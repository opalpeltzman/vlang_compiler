%{

#include <stdio.h>
void yyerror (char *s);
int yylex();
#include <stdio.h>     /* C declarations used in actions */
#include <stdlib.h>
#include <ctype.h>

int symbols[52];
int symbolVal(char symbol);
void updateSymbolVal(char symbol, int val);
int tcounter=0, ecounter=0;

%}

%union {int num; int* vec;}         		 /* type of variables */
%start line                                  /* Yacc definitions */
%token ID
%token print
%token scl
%token vec
%token exit_command
%token <num> number
%type <num> line exp term 

%right '='
%left '+' '-'
%left '*' '/'
%left '.' ':'
%left '()'

%%

/* descriptions of expected inputs     corresponding actions (in C) */

line    : assignment ';'		{ecounter=tcounter=0;}
		| exit_command ';'		{exit(EXIT_SUCCESS);}
		| print exp ';'			{printf("\tprintf(\"%%d\\n\", e%d );\n", $2);}
		| scl ID ';'			{;}
		| line assignment ';'	{;}
		| line print exp ';'	{printf("\tprintf(\"%%d\\n\", e%d );\n", $3);}
		| line exit_command ';'	{exit(EXIT_SUCCESS);}
        ;

assignment : ID '=' exp  { printf("\t%c=e%d\n", $1,$3);}
			;
exp    	: term                  {$$ = ++ecounter; printf("\te%d=t%d;\n", ecounter, $1);}
       	| 
       	;
term   	: number                {$$ = ++tcounter; printf("\tt%d=%d;\n", tcounter, $1);}
		| ID			{$$ = ++tcounter; printf("\tt%d=%c;\n", tcounter, $1);} 
        ;

%%                     /* C code */

int computeSymbolIndex(char token)
{
	int idx = -1;
	if(islower(token)) {
		idx = token - 'a' + 26;
	} else if(isupper(token)) {
		idx = token - 'A';
	}
	return idx;
} 

/* returns the value of a given symbol */
int symbolVal(char symbol)
{
	int bucket = computeSymbolIndex(symbol);
	return symbols[bucket];
}

/* updates the value of a given symbol */
void updateSymbolVal(char symbol, int val)
{
	int bucket = computeSymbolIndex(symbol);
	symbols[bucket] = val;
}

int main (void) {
	/* init symbol table */
	int i;
	for(i=0; i<52; i++) {
		symbols[i] = 0;
	}

	return yyparse ( );
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);} 
