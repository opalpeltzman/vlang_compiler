%{
#include <stdio.h>     							/* C declarations used in actions */
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "vlang.h"

void yyerror(char *s);
int yylex();

extern FILE* yyin;
extern FILE * yyout;

int ecounter=0;									/* counter for temp exp */
int expArray=1;									/* counter for comma table */
expression commaArray[VECLEN];					/* comma expression table */
nodeType symbols[SYMSIZE];						/* Symbol table */
char vars[SYMSIZE][IDLEN];  					/* Variable table: for mapping variables to symbol table */

ConstVecnodeType ConstVecArray[VECLEN];			/* temporary const vector table */
int vecIndxCount = -1;							/* vec index counter */
ConstSclnodeType ConstSclArray[VECLEN];			/* temporary const scalar table */
int sclIndxCount= -1;							/* scl index counter */

/* symbol table help functions */
void setSymbolTable(char *vName, conType type, int size);		/* update variable in symbol table */
expression getSymIndex(char *name, char mode);					/* Returns the variable index from symbol table */
int variablesIndex(char *name, char mode);						/* variable index in symbol table */	

/* consts table help functions */
expression constsVecUpdate(char* value);						/* update const vector table */
expression constsSclUpdate(int value);							/* update const scalar table */

/* print functions */
void printFileInitialize();												/* prepare C file */
void printPrintStat(expression exp);									/* check if comma and send to print print statement */
void printPrint(expression exp);										/* print print statement */
void commaExp(expression exp1, expression exp2);						/* handle exp, exp statement */
expression printTerm(expression term);									/* print term */
expression printExp(expression exp1, char* oper, expression exp2);		/* print expression */
expression printVecExp(expression exp1, char* oper, expression exp2);	/* print only vector expression */
expression printAssign(char* var, expression exp);						/* print assignment */

%}

%union {
	int size;
	int num;
	char elem[VECLEN]; 
	char vName[IDLEN];
	int IndnVar[3];
	expression expr;
	}         									 /* type of variables */
%start line                                      /* Yacc definitions */
%token print
%token exit_command

%token scl
%token vec
%token <vName> identifier
%token <size> vecSize
%token <num> number
%token <elem> constVector

%type <expr> term
%type <expr> line exp assignment 

%right '='
%left ','
%left '+' '-'
%left '*' '/'
%left '.' ':'
%left '(' ')'

%%

/* descriptions of expected inputs     corresponding actions (in C) */

line    	: assignment ';'				{ecounter=0;}	
			| line assignment ';'			{;}
			| exit_command ';'				{fprintf(yyout, "\n\treturn 0;\n}");exit(EXIT_SUCCESS);}
			| line exit_command ';'			{fprintf(yyout, "\n\treturn 0;\n}");exit(EXIT_SUCCESS);}
			| def ';'						{;}
			| line def ';'					{;}			
			| statement ';'					{;}
			| line statement ';'			{;}
        	;
assignment  : identifier '=' exp  			{$$ = printAssign($1, $3);}
			;
statement	: exp							{;} 
			| print exp						{printPrintStat($2);}				
exp    		: term                  		{$$ = printTerm($1);}
       		| exp '+' exp					{$$ = printExp($1, "+", $3);}
			| exp '-' exp					{$$ = printExp($1, "-", $3);}
			| exp '*' exp					{$$ = printExp($1, "*", $3);}
			| exp '/' exp					{$$ = printExp($1, "/", $3);}
			| exp '.' exp					{$$ = printVecExp($1, ".", $3);}
			| exp ':' exp					{$$ = printVecExp($1, ":", $3);}
			| '(' exp ')'					{$$ = $2;}
			| exp ',' exp					{$$ =  $3; commaExp($1, $3);}
       		;
term   		: number                		{$$ = constsSclUpdate($1);}
			| constVector					{$$ = constsVecUpdate($1);}
			| identifier					{$$ = getSymIndex($1, GET);} 
def			: scl identifier				{fprintf(yyout, "\tint %s;\n", $2); setSymbolTable($2, scalar, 0);}
			| vec identifier vecSize		{fprintf(yyout, "\tint %s[%d];\n", $2, $3); setSymbolTable($2, vector, $3);}
        	;


%%                     /* C code */

/* variable index in symbol table */
int variablesIndex(char *name, char mode){ 
    switch (mode) {
        case GET:       /* Return index of variable from symbol table */
        {
            for (int i = 0; i < SYMSIZE; i++) {
                if (!strcmp(vars[i], "-1")) return -1;
                else if (!strcmp(name, vars[i])) return i;    /* ID found */
            }
            return -1;
        }
        case SET:       /* Sets the index of variable from symbol table and then returns the index */
        {
            for (int i = 0; i < SYMSIZE; i++) {
                if (!strcmp(name, vars[i])) return i;     /* ID already exists */
                else if (!strcmp(vars[i], "-1")) {
                    strcpy(vars[i], name);
                    return i;
                }
            }
            return -1;
        }
    }
}

/* update variable in symbol table */
void setSymbolTable(char *vName, conType type, int size){
	int sIndex = variablesIndex(vName, SET);
    if(sIndex == -1) {
        yyerror("failed to initialize variable");}
	symbols[sIndex].type = type;
	symbols[sIndex].size = size;
	symbols[sIndex].indx = sIndex;
	strcpy(symbols[sIndex].name, vName);
}

/* Returns the variable index from symbol table */
expression getSymIndex(char *name, char mode){
	
	expression dest;
	int sIndex = variablesIndex(name, mode);
    if(sIndex == -1) {
        yyerror("variable does not exist");}
	dest.indx = sIndex;
	dest.type = symbols[sIndex].type;
	dest.ecounter = -1;
	dest.size = symbols[sIndex].size;
	return dest;
}

/* update const vector table */
expression constsVecUpdate(char* value){	
	expression dest;
	vecIndxCount ++;
	ConstVecArray[vecIndxCount].indx = vecIndxCount;

	/* calc array size */
	int count = 0;
	for(int i=0; value[i] != '\0' ; i++){	/* count size of array */
		if(value[i] == ','){
			count ++;
		}
		if(value[i] == '['){				/* replace [] to {} */
			value[i] = '{';
		}
		if(value[i] == ']'){				/* replace [] to {} */
			value[i] = '}';
		}
	}
	count ++;
	ConstVecArray[vecIndxCount].size = count;
	strcpy(ConstVecArray[vecIndxCount].val, value);
	dest.indx = vecIndxCount;
	dest.type = coVector;
	dest.ecounter = -1;
	dest.size = count;
	return dest;
}

/* update const scalar table */
expression constsSclUpdate(int value){
	expression dest;
	sclIndxCount ++;
	ConstSclArray[sclIndxCount].val = value;
	ConstSclArray[sclIndxCount].indx = sclIndxCount;

	dest.indx = sclIndxCount;
	dest.type = coScalar;
	dest.ecounter = -1;
	dest.size = 0;
	return dest;
}

/* print terms */
expression printTerm(expression term){
	expression exp;
	exp.type = term.type;
	exp.indx = term.indx;

	/* print term */
	if(term.type == vector){exp.ecounter = -1; exp.size = symbols[term.indx].size;;}
	else if(term.type == scalar){exp.ecounter = -1; exp.size = 0;}
	else if(term.type == coVector){
		exp.ecounter = ecounter;
		fprintf(yyout, "\tint e%d[] = %s;\n", exp.ecounter, ConstVecArray[term.indx].val);
		ecounter++;
	}
	else if(term.type == coScalar){
		exp.ecounter = ecounter;
		fprintf(yyout, "\tint e%d = %d;\n", exp.ecounter, ConstSclArray[term.indx].val);
		ecounter++;
	}
	return exp;
}

/* print assignment */
expression printAssign(char* var, expression exp){
	/* possible assignments: s=s v=constV v=v v=s v=constS */
	expression dest;
	int sIndex = variablesIndex(var, GET);
    if(sIndex == -1) {
        yyerror("variable not initialized");}
	/* update returned expression */
	dest.type = symbols[sIndex].type;
	dest.indx = sIndex;
	dest.ecounter = -1;
	
	if(symbols[sIndex].type == scalar){			/* scalar handling */
		if(exp.type == scalar){
			fprintf(yyout, "\t%s = %s;\n", symbols[sIndex].name, symbols[exp.indx].name);
		}else if(exp.type == coScalar){
			fprintf(yyout, "\t%s = e%d;\n", symbols[sIndex].name, exp.ecounter);
		}else{
			yyerror("scalar can't be equal to vector");}
	}else if(symbols[sIndex].type == vector){	/* vector handling */
		if(exp.type == scalar){
			fprintf(yyout, "\tfor(int i = 0; i < %d; i++){\n", symbols[sIndex].size);
			fprintf(yyout, "\t\t%s[i] = %s;\n\t}\n", symbols[sIndex].name, symbols[exp.indx].name);
		}else if(exp.type == coScalar){
			fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", symbols[sIndex].size);
			fprintf(yyout,"\t\t%s[i] = e%d;\n\t}\n", symbols[sIndex].name, exp.ecounter);
		}else if(exp.type == vector){
			if(symbols[sIndex].size == symbols[exp.indx].size){
				fprintf(yyout,"\tmemcpy(%s, %s, sizeof(%s));\n", symbols[sIndex].name, symbols[exp.indx].name, symbols[sIndex].name);
			}else{
				yyerror("can't assigned different sizes");}
		}else if(exp.type == coVector){
			if(symbols[sIndex].size == exp.size){
				fprintf(yyout,"\tmemcpy(%s, e%d, sizeof(%s));\n", symbols[sIndex].name, exp.ecounter, symbols[sIndex].name);
			}else{
				yyerror("can't assigned different sizes");}
		}else{
			yyerror("wrong input when assigned vector");}	
	}else{										/* error */
			yyerror("not valid identifier");}
	return dest;
}

/* print expressions */
expression printExp(expression exp1, char* oper, expression exp2){
	expression dest;
	dest.ecounter = ecounter++;
	dest.indx = -1;	
	if(exp1.type == scalar){									/* handle scalar exp1 */
		if(strcmp(oper, ":") == 0 || strcmp(oper, ".") == 0 ){
			yyerror("not valid operand for scalar");}
		if(exp2.type == scalar){
			dest.type = coScalar;
			dest.indx = -1;	
			dest.size = 0;						
			fprintf(yyout,"\tint e%d = %s %s %s;\n", dest.ecounter, symbols[exp1.indx].name, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coScalar){
			dest.type = coScalar;
			dest.indx = -1;
			dest.size = 0;	
			fprintf(yyout,"\tint e%d = %s %s e%d;\n", dest.ecounter, symbols[exp1.indx].name, oper, exp2.ecounter);
		}else if(exp2.type == vector){
			dest.type = coVector;
			dest.indx = -1;
			dest.size = symbols[exp2.indx].size;
			fprintf(yyout,"\tint e%d[%d];\n", dest.ecounter, symbols[exp2.indx].size);
			fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", symbols[exp2.indx].size);
			fprintf(yyout,"\t\te%d[i] = %s %s %s[i];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coVector){
			dest.type = coVector;
			dest.indx = -1;	
			dest.size = exp2.size;
			fprintf(yyout,"\tint e%d[%d];\n", dest.ecounter, exp2.size);
			fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", exp2.size);
			fprintf(yyout,"\t\te%d[i] = %s %s e%d[i];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, oper, exp2.ecounter);
		}
	}else if(exp1.type == coScalar){							/* handle const scalar exp1 */
		if(strcmp(oper, ":") == 0 || strcmp(oper, ".") == 0 ){
			yyerror("not valid operand for scalar");}
		if(exp2.type == scalar){
			dest.type = coScalar;
			dest.size = 0;						
			fprintf(yyout,"\tint e%d = e%d %s %s;\n", dest.ecounter, exp1.ecounter, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coScalar){
			dest.type = coScalar;
			dest.size = 0;	
			fprintf(yyout,"\tint e%d = e%d %s e%d;\n", dest.ecounter, exp1.ecounter, oper, exp2.ecounter);
		}else if(exp2.type == vector){
			dest.type = coVector;
			dest.size = symbols[exp2.indx].size;
			fprintf(yyout,"\tint e%d[%d];\n", dest.ecounter, symbols[exp2.indx].size);
			fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", symbols[exp2.indx].size);
			fprintf(yyout,"\t\te%d[i] = e%d %s %s[i];\n\t}\n", dest.ecounter, exp1.ecounter, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coVector){
			dest.type = coVector;
			dest.size = exp2.size;
			fprintf(yyout,"\tint e%d[%d];\n", dest.ecounter, exp2.size);
			fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", exp2.size);
			fprintf(yyout,"\t\te%d[i] = e%d %s e%d[i];\n\t}\n", dest.ecounter, exp1.ecounter, oper, exp2.ecounter);
		}
	}else if(exp1.type == vector){								/* handle vector exp1 */
		dest.type = coVector;
		dest.size = symbols[exp1.indx].size;
		fprintf(yyout,"\tint e%d[%d];\n", dest.ecounter, symbols[exp1.indx].size);
		fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", symbols[exp1.indx].size);
		if(exp2.type == scalar){						
			fprintf(yyout,"\t\te%d[i] = %s[i] %s %s;\n\t}\n", dest.ecounter, symbols[exp1.indx].name, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coScalar){
			fprintf(yyout,"\t\te%d[i] = %s[i] %s e%d;\n\t}\n", dest.ecounter, symbols[exp1.indx].name, oper, exp2.ecounter);
		}else if(exp2.type == vector && symbols[exp1.indx].size == symbols[exp2.indx].size){
			fprintf(yyout,"\t\te%d[i] = %s[i] %s %s[i];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coVector && symbols[exp1.indx].size == exp2.size){
			fprintf(yyout,"\t\te%d[i] = %s[i] %s e%d[i];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, oper, exp2.ecounter);
		}else{
			yyerror("vector sizes does not match");}
	}else if(exp1.type == coVector){						    /* handle const vector exp1 */
		dest.type = coVector;
		dest.size = exp1.size;
		fprintf(yyout,"\tint e%d[%d];\n", dest.ecounter, exp1.size);
		fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", exp1.size);
		if(exp2.type == scalar){						
			fprintf(yyout,"\t\te%d[i] = e%d[i] %s %s;\n\t}\n", dest.ecounter, exp1.ecounter, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coScalar){
			fprintf(yyout,"\t\te%d[i] = e%d[i] %s e%d;\n\t}\n", dest.ecounter, exp1.ecounter, oper, exp2.ecounter);
		}else if(exp2.type == vector && exp1.size == symbols[exp2.indx].size){
			fprintf(yyout,"\t\te%d[i] = e%d[i] %s %s[i];\n\t}\n", dest.ecounter, exp1.ecounter, oper, symbols[exp2.indx].name);
		}else if(exp2.type == coVector && exp1.size == exp2.size){
			fprintf(yyout,"\t\te%d[i] = e%d[i] %s e%d[i];\n\t}\n", dest.ecounter, exp1.ecounter, oper, exp2.ecounter);
		}else{
			yyerror("vector sizes does not match");}
	}
	return dest;
}

/* print only vector expression */
expression printVecExp(expression exp1, char* oper, expression exp2){
	if(exp1.type == scalar || exp1.type == coScalar){yyerror("not valid operand for scalar");}
	expression dest;
	dest.ecounter = ecounter++;
	dest.indx = -1;	
	if(strcmp(oper, ".") == 0){
		if(exp2.type == scalar || exp2.type == coScalar){yyerror("not valid operand for scalar");}
		if(exp1.size != exp2.size){yyerror("not valid operand for scalar");}
		else{
			dest.type = coScalar;
			dest.size = 0;
			fprintf(yyout,"\tint e%d = 0;\n", dest.ecounter);
			fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", exp1.size);
			if(exp1.type == vector && exp2.type == vector){fprintf(yyout,"\t\te%d += %s[i] * %s[i];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, symbols[exp2.indx].name);}
			if(exp1.type == vector && exp2.type == coVector){fprintf(yyout,"\t\te%d += %s[i] * e%d[i];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, exp2.ecounter);}
			if(exp1.type == coVector && exp2.type == vector){fprintf(yyout,"\t\te%d += e%d[i] * %s[i];\n\t}\n", dest.ecounter, exp1.ecounter, symbols[exp2.indx].name);}
			if(exp1.type == coVector && exp2.type == coVector){fprintf(yyout,"\t\te%d += e%d[i] * e%d[i];\n\t}\n", dest.ecounter, exp1.ecounter, exp2.ecounter);}
		}
	}else if(strcmp(oper, ":") == 0){
		if(exp2.type == scalar || exp2.type == coScalar){
			dest.type = coScalar;
			dest.size = 0;
			fprintf(yyout,"\tint e%d = 0;\n", dest.ecounter);
			if(exp1.type == vector && exp2.type == scalar){
				fprintf(yyout,"\tif(%s >= 0 && %s < %d){\n", symbols[exp2.indx].name, symbols[exp2.indx].name, exp1.size);
				fprintf(yyout,"\t\te%d = %s[%s];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, symbols[exp2.indx].name);}
			if(exp1.type == vector && exp2.type == coScalar){
				fprintf(yyout,"\tif(e%d >= 0 && e%d < %d){\n", exp2.ecounter, exp2.ecounter, exp1.size);
				fprintf(yyout,"\t\te%d = %s[e%d];\n\t}\n", dest.ecounter, symbols[exp1.indx].name, exp2.ecounter);}
			if(exp1.type == coVector && exp2.type == scalar){
				fprintf(yyout,"\tif(%s >= 0 && %s < %d){\n", symbols[exp2.indx].name, symbols[exp2.indx].name, exp1.size);
				fprintf(yyout,"\t\te%d = e%d[%s];\n\t}\n", dest.ecounter, exp1.ecounter, symbols[exp2.indx].name);}
			if(exp1.type == coVector && exp2.type == coScalar){
				fprintf(yyout,"\tif(e%d >= 0 && e%d < %d){\n", exp2.ecounter, exp2.ecounter, exp1.size);
				fprintf(yyout,"\t\te%d = e%d[e%d];\n\t}\n", dest.ecounter, exp1.ecounter, exp2.ecounter);}
			fprintf(yyout,"\telse{fprintf (stderr, \"index out of range\"); exit(0);}\n");
		}
		if(exp2.type == vector || exp2.type == coVector){
			if(exp1.size != exp2.size){yyerror("not valid operation for different sizes");}
			else{
				dest.type = coVector;
				dest.size = exp1.size;
				fprintf(yyout,"\tint e%d[%d] = {0};\n", dest.ecounter, exp1.size);
				fprintf(yyout,"\tfor(int i = 0; i < %d; i++){\n", exp1.size);
				if(exp1.type == vector && exp2.type == vector){
					fprintf(yyout,"\t\tif(%s[i] >= 0 && %s[i] < %d){\n", symbols[exp2.indx].name, symbols[exp2.indx].name, exp1.size);
					fprintf(yyout,"\t\t\te%d[i] = %s[%s[i]];\n\t\t}\n", dest.ecounter, symbols[exp1.indx].name, symbols[exp2.indx].name);}
				if(exp1.type == vector && exp2.type == coVector){
					fprintf(yyout,"\t\tif(e%d[i] >= 0 && e%d[i] < %d){\n", exp2.ecounter, exp2.ecounter, exp1.size);
					fprintf(yyout,"\t\t\te%d[i] = %s[e%d[i]];\n\t\t}\n", dest.ecounter, symbols[exp1.indx].name, exp2.ecounter);}
				if(exp1.type == coVector && exp2.type == vector){
					fprintf(yyout,"\t\tif(%s[i] >= 0 && %s[i] < %d){\n", symbols[exp2.indx].name, symbols[exp2.indx].name, exp1.size);
					fprintf(yyout,"\t\t\te%d[i] = e%d[%s[i]];\n\t\t}\n", dest.ecounter, exp1.ecounter, symbols[exp2.indx].name);}
				if(exp1.type == coVector && exp2.type == coVector){
					fprintf(yyout,"\t\tif(e%d[i] >= 0 && e%d[i] < %d){\n", exp2.ecounter, exp2.ecounter, exp1.size);
					fprintf(yyout,"\t\t\te%d[i] = e%d[e%d[i]];\n\t\t}\n", dest.ecounter, exp1.ecounter, exp2.ecounter);}
				fprintf(yyout,"\t\telse{fprintf (stderr, \"index out of range\"); exit(0);}\n\t}\n");
			}
		}
		
		
	}
	return dest;
}

/* check if comma and send to print print statement */
void printPrintStat(expression exp){
	
	if(expArray > 1){
		for(int i=0; i < expArray - 1; i++){printPrint(commaArray[i]); fprintf(yyout,"\tprintf(\":\\n\");\n");}
		printPrint(commaArray[expArray - 1]);
	}else{
		printPrint(exp);
	}
	expArray = 1;
}

/* print print statement */
void printPrint(expression exp){
	
	if(exp.type == vector || exp.type == coVector){
		fprintf(yyout,"\tprintf(\"[\");\n");
		fprintf(yyout,"\tfor(int i = 0; i < %d - 1; i++){\n", exp.size);
		if(exp.type == vector){fprintf(yyout,"\t\tprintf(\"%%d,\", %s[i]);\n\t}\n\tprintf(\"%%d\", %s[%d - 1]);\n", symbols[exp.indx].name, symbols[exp.indx].name, exp.size);}
		if(exp.type == coVector){fprintf(yyout,"\t\tprintf(\"%%d,\",e%d[i]);\n\t}\n\tprintf(\"%%d\", e%d[%d - 1]);\n", exp.ecounter, exp.ecounter, exp.size);}
		fprintf(yyout,"\tprintf(\"]\\n\");\n");

	}else if(exp.type == scalar){
		fprintf(yyout,"\tprintf(\"%%d\\n\", %s);\n", symbols[exp.indx].name);
	}else if(exp.type == coScalar){
		fprintf(yyout,"\tprintf(\"%%d\\n\", e%d);\n", exp.ecounter);
	}
}

/* handle exp, exp statement */
void commaExp(expression exp1, expression exp2){
	commaArray[expArray -1] = exp1;
	expArray++;
	commaArray[expArray -1] = exp2;
}

/* prepare C file */
void printFileInitialize(FILE * out){
	fprintf(out, "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n");

	/* main function  */
	fprintf(out , "\nint main(void)\n{\n");
}

int main (void) {
	if(_argc==2){
		yyout = fopen(_argv[1], "w");
		if(!yyout)
         	{
         	    fprintf(stderr, "can't read file %s\n", _argv[2]);
         	    return 1;
         	}
	}
	/* Initialize variable table */
    for (int i = 0; i < SYMSIZE; i++) strcpy(vars[i], "-1");

	vecIndxCount = -1;
	sclIndxCount = -1;
	ecounter=0;

	printFileInitialize(yyout);
	return yyparse();
	fprintf(yyout, "\n\treturn 0;\n}");
}

void yyerror(char *s){
	fprintf (stderr, "%s\n", s);
	exit(0);
} 
