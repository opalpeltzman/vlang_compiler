%{
#include <stdio.h>     							/* C declarations used in actions */
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "vlang.h"



void yyerror(char *s);
int yylex();

int ecounter=0;
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
expression printTerm(expression term);							/* print term */
void printExp(expression exp1, expression exp2, char* oper);	/* print expression */
void printAssign(char* var, expression exp);					/* print assignment */

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
%type <expr> line exp  

%right '='
%left '+' '-'
%left '*' '/'
%left '.' ':'

%%

/* descriptions of expected inputs     corresponding actions (in C) */

line    	: assignment ';'				{ecounter=0;}	
			| line assignment ';'			{;}
			| exit_command ';'				{exit(EXIT_SUCCESS);}
			| line exit_command ';'			{exit(EXIT_SUCCESS);}
			| def ';'						{;}
			| line def ';'					{;}			
			| statement ';'					{;}
			| line statement ';'			{;}
        	;
assignment  : identifier '=' exp  			{printAssign($1, $3);}
			;
statement	: exp							{;} 
			| print exp	';'					{;}				
exp    		: term                  		{$$ = printTerm($1);}
       		| exp '+' exp					{;}
			| exp '-' exp					{;}
			| exp '*' exp					{;}
			| exp '/' exp					{;}
			| '(' exp ')'					{;}
       		;
term   		: number                		{$$ = constsSclUpdate($1);}
			| constVector					{$$ = constsVecUpdate($1);}
			| identifier					{$$ = getSymIndex($1, GET);} 
def			: scl identifier				{printf("\tint %s;\n", $2); setSymbolTable($2, scalar, 0);}
			| vec identifier vecSize		{printf("\tint %s[%d];\n", $2, $3); setSymbolTable($2, vector, $3);}
        	;


%%                     /* C code */

int variablesIndex(char *name, char mode){
    /* variable index in symbol table */
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

void setSymbolTable(char *vName, conType type, int size){
	/* update variable in symbol table */
	int sIndex = variablesIndex(vName, SET);
    if(sIndex == -1) {
        yyerror("failed to initialize variable");
        exit(1);
    }
	symbols[sIndex].type = type;
	symbols[sIndex].size = size;
	symbols[sIndex].indx = sIndex;
	strcpy(symbols[sIndex].name, vName);

	// printf("type: %d, size: %d, index: %d, name: %s\n", symbols[sIndex].type, symbols[sIndex].size, symbols[sIndex].indx, symbols[sIndex].name);
}

expression getSymIndex(char *name, char mode){
	/* Returns the variable index from symbol table */
	expression dest;
	int sIndex = variablesIndex(name, mode);
    if(sIndex == -1) {
        yyerror("variable not initialized");
        exit(1);
    }
	dest.indx = sIndex;
	dest.type = symbols[sIndex].type;
	dest.ecounter = -1;
	// printf("sIndex: %d array type: %d term counter: %d\n", dest.indx, dest.type, dest.ecounter);
	return dest;
}

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
	// printf("count: %d\n", count);
	dest.indx = vecIndxCount;
	dest.type = coVector;
	dest.ecounter = -1;
	// printf("sIndex: %d type: %d term counter: %d\n", dest.indx, dest.type, dest.ecounter);
	// printf("value: %s\n", ConstVecArray[vecIndxCount].val);
	// printf("vector size: %d\n", ConstVecArray[vecIndxCount].size);
	return dest;
}

expression constsSclUpdate(int value){
	expression dest;
	sclIndxCount ++;
	ConstSclArray[sclIndxCount].val = value;
	ConstSclArray[sclIndxCount].indx = sclIndxCount;

	dest.indx = sclIndxCount;
	dest.type = coScalar;
	dest.ecounter = -1;
	// printf("sIndex: %d type: %d term counter: %d\n", dest.indx, dest.type, dest.ecounter);
	// printf("value: %d\n", ConstSclArray[sclIndxCount].val);
	return dest;
}

expression printTerm(expression term){
	expression exp;
	exp.type = term.type;
	exp.indx = term.indx;
	exp.ecounter = ecounter;
	ecounter++;
	/* print term */
	if(term.type == vector){
		printf("\tint e%d[%d];\n", exp.ecounter, symbols[exp.indx].size);
		printf("\tmemcpy(e%d, %s, sizeof(%s));\n", exp.ecounter, symbols[exp.indx].name, symbols[exp.indx].name);
		// printf("sIndex: %d type: %d exp counter: %d\n", exp.indx, exp.type, exp.ecounter);
	}
	else if(term.type == scalar){
		printf("\te%d = %s\n", exp.ecounter, symbols[exp.indx].name);
	}
	else if(term.type == coVector){
		printf("\tint e%d[] = %s;\n", exp.ecounter, ConstVecArray[term.indx].val);
		// printf("sIndex: %d type: %d exp counter: %d\n", exp.indx, exp.type, exp.ecounter);
	}
	else if(term.type == coScalar){
		printf("\tint e%d = %d;\n", exp.ecounter, ConstSclArray[term.indx].val);
		// printf("sIndex: %d type: %d exp counter: %d\n", exp.indx, exp.type, exp.ecounter);
	}
	return exp;
}

void printAssign(char* var, expression exp){
	/* possible assignments: s=s v=constV v=v v=s v=constS */
	int sIndex = variablesIndex(var, GET);
    if(sIndex == -1) {
        yyerror("variable not initialized");
        exit(1);
    }
	printf("symbol type: %d\n", symbols[sIndex].type);
	switch(symbols[sIndex].type){
		case scalar:{
			printf("exp type: %d exp indx: %d\n", exp.type, exp.indx);
			if(exp.type == scalar || exp.type == coScalar){
				printf("\t%s=e%d\n", symbols[sIndex].name, exp.ecounter);
			}else{
				yyerror("not valid action!");
        		exit(1);
			}
			break;
		}
		case vector:{

			break;
		}
	}
}

void printExp(expression exp1, expression exp2, char* oper){

}

int main (void) {
	/* init symbol, vec and scl tables */
	// memset(symbols, 0, sizeof(SYMSIZE));
	// memset(ConstVecArray, 0, sizeof(SYMSIZE));
	// memset(ConstSclArray, 0, sizeof(SYMSIZE));

	/* Initialize variable table */
    for (int i = 0; i < SYMSIZE; i++) strcpy(vars[i], "-1");

	vecIndxCount = -1;
	sclIndxCount = -1;
	ecounter=0;
	return yyparse();
}

void yyerror(char *s){
	fprintf (stderr, "%s\n", s);
} 
