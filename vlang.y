%{
#include <stdio.h>     							/* C declarations used in actions */
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "vlang.h"



void yyerror(char *s);
int yylex();

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

%}

%union {
	int size;
	int indx;
	int num;
	char elem[VECLEN]; 
	char vName[IDLEN];
	int IndnVar[2];
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
%type <vName> line exp  

%right '='
%left '+' '-'
%left '*' '/'
%left '.' ':'

%%

/* descriptions of expected inputs     corresponding actions (in C) */

line    	: assignment ';'				{;}	
			| line assignment ';'			{;}
			| exit_command ';'				{exit(EXIT_SUCCESS);}
			| def ';'						{;}
			| line def ';'					{;}			
			| statement ';'					{;}
			| line statement ';'			{;}
			| line exit_command ';'			{exit(EXIT_SUCCESS);}
        	;
assignment  : identifier '=' exp  			{;}
			;
statement	: exp							{;} 
			| print exp	';'					{;}				
exp    		: term                  		{;}
       		| exp '+' exp					{;}
			| exp '-' exp					{;}
			| exp '*' exp					{;}
			| exp '/' exp					{;}
			| '(' exp ')'					{;}
       		;
term   		: number                		{printf("\t %d;\n", $1); constsSclUpdate($$, $1);}
			| constVector					{printf("\t %s;\n", $1); constsVecUpdate($$, $1);}
			| identifier					{printf("\t %s;\n", $1); getSymIndex($$, $1, GET);} 
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

void getSymIndex(int* dest, char *name, char mode){
	/* Returns the variable index from symbol table */
	int sIndex = variablesIndex(name, mode);
    if(sIndex == -1) {
        yyerror("ariable not initialized");
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
	// printf("sIndex: %d array type: %d\n", dest[0], dest[1]);
}

void constsSclUpdate(int* dest, int value){
	sclIndxCount ++;
	ConstSclArray[sclIndxCount].val = value;
	ConstSclArray[sclIndxCount].indx = sclIndxCount;

	dest[0] = sclIndxCount;
	dest[1] = constScl;
	// printf("sIndex: %d array type: %d\n", dest[0], dest[1]);
}

int main (void) {
	/* init symbol, vec and scl tables */
	memset(symbols, 0, sizeof(SYMSIZE));
	memset(ConstVecArray, 0, sizeof(SYMSIZE));
	memset(ConstSclArray, 0, sizeof(SYMSIZE));

	/* Initialize variable table */
    for (int i = 0; i < SYMSIZE; i++) strcpy(vars[i], "-1");

	vecIndxCount = -1;
	sclIndxCount = -1;
	return yyparse();
}

void yyerror(char *s){
	fprintf (stderr, "%s\n", s);
} 
