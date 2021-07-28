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
void getSymIndex(int* dest, char *name, char mode);				/* Returns the variable index from symbol table */
int variablesIndex(char *name, char mode);						/* variable index in symbol table */	

/* consts table help functions */
void constsVecUpdate(int* dest, char* value);					/* update const vector table */
void constsSclUpdate(int* dest, int value);						/* update const scalar table */

/* print functions */
void printTerm(expression exp, int* term);						/* print term */
void printExp(expression exp1, expression exp2, char* oper);	/* print expression */
void printAssign(char* var, expression exp);					/* print assignment */

%}

%union {
	int size;
	int num;
	char elem[VECLEN]; 
	char vName[IDLEN];
	int IndnVar[2];
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

%type <IndnVar> term
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
exp    		: term                  		{printTerm($$, $1);}
       		| exp '+' exp					{;}
			| exp '-' exp					{;}
			| exp '*' exp					{;}
			| exp '/' exp					{;}
			| '(' exp ')'					{;}
       		;
term   		: number                		{constsSclUpdate($$, $1);}
			| constVector					{constsVecUpdate($$, $1);}
			| identifier					{getSymIndex($$, $1, GET);} 
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

	printf("type: %d, size: %d, index: %d, name: %s\n", symbols[sIndex].type, symbols[sIndex].size, symbols[sIndex].indx, symbols[sIndex].name);
}

void getSymIndex(int* dest, char *name, char mode){
	/* Returns the variable index from symbol table */
	int sIndex = variablesIndex(name, mode);
    if(sIndex == -1) {
        yyerror("variable not initialized");
        exit(1);
    }
	dest[0] = sIndex;
	dest[1] = symbolTab;
	// printf("sIndex: %d array type: %d\n", dest[0], dest[1]);
}

void constsVecUpdate(int* dest, char* value){
	vecIndxCount ++;
	strcpy(ConstVecArray[vecIndxCount].val, value);
	ConstVecArray[vecIndxCount].indx = vecIndxCount;

	/* calc array size */
	int count = 0;
	for(int i=0; value[i] != '\0' ; i++){
		if(value[i] == ','){
			count ++;
		}
	}
	count ++;
	ConstVecArray[vecIndxCount].size = count;
	// printf("count: %d\n", count);
	dest[0] = vecIndxCount;
	dest[1] = constVec;
	// printf(" %s \n", ConstVecArray[vecIndxCount].val);
}

void constsSclUpdate(int* dest, int value){
	sclIndxCount ++;
	ConstSclArray[sclIndxCount].val = value;
	ConstSclArray[sclIndxCount].indx = sclIndxCount;

	dest[0] = sclIndxCount;
	dest[1] = constScl;
	printf("term- sIndex: %d array type: %d\n", dest[0], dest[1]);
}

void printTerm(expression exp, int* term){
	/* print term */
	switch(term[1]){
		case symbolTab:{
			printf("\te%d=%s\n", ecounter, symbols[term[0]].name);
			exp.type = symbols[term[0]].type;
			exp.indx = term[0];
			exp.ecounter = ecounter;
			ecounter++; 
			printf("exp type: %d exp indx: %d\n", exp.type, exp.indx);
			break;
		}
		case constVec:{
			printf("\te%d=%s\n", ecounter, ConstVecArray[term[0]].val);
			exp.type = coVector;
			exp.indx = term[0];
			exp.ecounter = ecounter;
			ecounter++; 
			break;
		}
		case constScl:{
			printf("\te%d=%d\n", ecounter, ConstSclArray[term[0]].val);
			exp.type = coScalar;
			exp.indx = term[0];
			exp.ecounter = ecounter;
			ecounter++; 
			printf("exp type: %d exp indx: %d\n", exp.type, exp.indx);
			break;
		}
	}
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
	return yyparse();
}

void yyerror(char *s){
	fprintf (stderr, "%s\n", s);
} 
