%{
#include <stdio.h>
#include <string.h>
#include "vlang.tab.h"
void yyerror (char *s);
int yylex();
%}

ALPHA     [A-Za-z]
DIGIT     ([0-9])

%%

"print"			                    {return print;}
"exit"			                    {return exit_command;}
"scl"                               {return scl;}
"vec"                               {return vec;}
{ALPHA}({ALPHA}|{DIGIT})*		    {strcpy(yylval.id, yytext); printf("An identifier: %s\n", yylval.id); return identifier;}
{DIGIT}+                            {yylval.num = atoi(yytext); return number;}
[.:-+*/=;]                          {return yytext[0];}
[ \t\n]                             ;
.                                   {ECHO; yyerror ("unexpected character");}

%%
int yywrap (void) {return 1;}
