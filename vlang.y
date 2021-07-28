%{
#include <stdio.h>     							/* C declarations used in actions */
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "vlang.h"

int getIndex(char *vName, char mode);      							 /* Returns index from symbol table */
nodeType *SymIndex(char* vName, char mode, int vType, int size);	 /* Identifier type node */

void freeNodes();													 /* Free nodes allocation */
void freeNode(nodeType *p);											 /* Free single node allocation */

nodeType *indexToNode(char *vName);												 /* return variable identifier node */
int* constVectorUpdate(int val);												 /* create and update const vector element */
nodeType *constVecToNode(char* vName, char mode, int vType);					 /* convert const vector to node */
nodeType *constNumToNode(char* vName, char mode, int vType, int size, int val);  /* convert const number to node */
void printVariable(nodeType *p);												 /* print variable */
nodeType *opr(char oper, nodeType *variable, nodeType *element); 				 /* update variables based on operator */

void yyerror(char *s);
int yylex();

nodeType *symbols[SYMSIZE];								    		 /* Symbol table */
char varSymbol[SYMSIZE][IDLEN];										 /* Variable table: for mapping variables to symbol table */


int tcounter=0, ecounter=0, elemCounter = 0;
int* constVector;													/* remporary const array*/

%}

%union {
	int num;
	int* scalVector; 
	char* vName;
	nodeType *nPtr;
	}         									 /* type of variables */
%start line                                      /* Yacc definitions */
%token print
%token exit_command

%token scl
%token vec
%token <vName> identifier
%token <num> number 

%type <nPtr> line exp term def

%right '='
%left '+' '-'
%left '*' '/'
%left '.' ':'

%%

/* descriptions of expected inputs     corresponding actions (in C) */

line    	: assignment ';'				{ecounter=tcounter=0;}	
			| exit_command ';'				{freeNodes();}
			| def ';'						{;}
			| statement ';'					{;}
			| print exp	';'					{printVariable($2);}
        	;
assignment  : identifier '=' exp  			{opr(Assign, indexToNode($1), $3);}
			;
statement	: exp							{;} 				
exp    		: term                  		{;}
       		| exp '+' exp					{;}
			| exp '-' exp					{;}
			| exp '*' exp					{;}
			| exp '/' exp					{;}
			| '(' exp ')'					{;}
       		;
term   		: number                		{$$ = constNumToNode("constScal", SET, constScal, 1, $1);}
			| '[' elem ']'					{$$ = constVecToNode("constVec", SET, constVec);}
			| identifier					{$$ = indexToNode($1);} 
elem		: number 						{constVectorUpdate($1)}
			| number ',' elem 				{constVectorUpdate($1);}
def			: scl identifier				{printf("$d", $2); $$ = SymIndex($2, SET, scalar, 1); }
			| vec identifier '{' number '}'	{$$ = SymIndex($2, SET, vector, $4); printf("$d", $4);}
        	;


%%                     /* C code */

int getIndex(char *vName, char mode){
	/*  Returns the variable index from symbol table */	
	switch(mode){
		case GET:	/* Return index of variable from symbol table */
		{
			for(int i = 0; i < SYMSIZE; i++){
				if (!strcmp(varSymbol[i], "-1")) return -1;
                else if (!strcmp(vName, varSymbol[i])) return i;    /* ID found */
			}
			return -1;
		}
		case SET:	/* Sets the index of variable from symbol table and then returns the index */
		{
			for(int i = 0; i < SYMSIZE; i++){
				if(!strcmp(vName, varSymbol[i])) return i;	/* ID already exists */
				else if(!strcmp(varSymbol[i], "-1")){
					strcpy(varSymbol[i], vName);
					return i;
				}
			}
			return -1;
		}
	}
}
nodeType *SymIndex(char* vName, char mode, int vType, int size){
	printf("in sym function");
	int indx;
	if(vType != constVec && vType != constScal){
		/*  Initialize node paramaters */
		indx = getIndex(vName, mode);
		if (indx == -1 && mode == GET) {
			yyerror("variable not initialized");
			exit(1);
		}
		else if (indx == -1 && mode == SET) {
			yyerror("failed to initialize variable");
			exit(1);
		}
	}

	nodeType *p;
     
    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
	p->type = vType;

	strcpy(p->name, vName);
	p->value.size = size;
	/* allocate values array */
	if ((p->value.val = (int*)malloc(size * sizeof(int))) == NULL)
        yyerror("values out of memory");

	if(vType != constVec && vType != constScal){
		p->id = indx;
		symbols[indx] = p;
	}
	return p;
}

void freeNodes(){
    for(int i=0; i<SYMSIZE; i++){
		if(symbols[i] != NULL){
			for(int j = 0; j<symbols[i]->value.size; j++)
				free(symbols[i]->value.val);
			free(symbols[i]);
		}
	}
	exit(EXIT_SUCCESS);
}
void freeNode(nodeType *p){
	if (!p) return;
    for(int j = 0; j<p->value.size; j++)
		free(p->value.val);
    free(p);
}

nodeType *indexToNode(char *vName){
	/* return the identifier node */
	int indx = getIndex(vName, GET);
	return symbols[indx];
}

nodeType *constNumToNode(char* vName, char mode, int vType, int size, int val){
	/* return const element node */
	nodeType *p = SymIndex(vName, mode, vType, size);
	(p->value.val)[0] = val;
	return p;
}

int* constVectorUpdate(int val){
	/* update and return const vector element */
	int size = elemCounter;
	if(elemCounter == 0){
		++size;
		constVector = (int*) calloc(size, sizeof(int));
		for (int i = elemCounter; i < size; ++i) {
            constVector[i] = val;
        }
		elemCounter = size;
	}
	else{
		++size;
		constVector = realloc(constVector, size * sizeof(int));
		for (int i = elemCounter; i < size; ++i) {
            constVector[i] = val;
        }
		elemCounter = size;
	}
	return constVector;
}

nodeType *constVecToNode(char* vName, char mode, int vType){
	nodeType *p = SymIndex(vName, mode, vType, elemCounter);
	for (int i = 0; i < p->value.size; ++i)
		(p->value.val)[i] = constVector[i];
	elemCounter = 0;
	free(constVector);

	return p;
}

nodeType *opr(char oper, nodeType *variable, nodeType *element){
	/* update variables based on operator */
	switch(oper){
		case Assign:{
			if(variable->type == scalar){
				if(element->type == scalar || element->type == constScal)
					*(variable->value.val) = *(element->value.val);
			}
			else if(variable->type == vector){	
				if((element->type == constVec ||element->type == vector) && variable->value.size == element->value.size){
					for (int i = 0; i < variable->value.size; ++i)
						(variable->value.val)[i] = (element->value.val)[i];
				}									
				if(element->type == scalar){
					for (int i = 0; i < variable->value.size; ++i)
						(variable->value.val)[i] = *(element->value.val);
				}
			}
			/* delete memory allocation for constan exp */
			if(element->type == constVec || element->type == constScal)
				freeNode(element);
	
			return variable;
		}
	}
}

void printVariable(nodeType *p){
	switch(p->type){
		case scalar:{
			printf("scalar %d\n", *(p->value.val));
		}
		case vector:{
			printf("[");
			for (int i = 0; i < p->value.size; ++i)
				printf("%d, ", *(p->value.val));
			printf("]\n");
		}
		case constScal: printf("scalarConst %d\n", *(p->value.val));
	}
}

int main (void) {
	/* init symbol table */
	for(int i=0; i<SYMSIZE; i++) {
		strcpy(varSymbol[i], "-1");
		symbols[i] = NULL;
	}

	return yyparse();
}

void yyerror(char *s){
	fprintf (stderr, "%s\n", s);
} 
