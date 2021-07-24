%{

#include <stdio.h>
#include <string.h>
#include "calc.tab.h"
void yyerror (char *s);
int yylex();
%}


numbers     ([0-9])+

%%

"print"			   {return print;}
"exit"			   {return exit_command;}
"scl"              {return ;}
"vec"              {return ;}
[a-zA-Z]			   {yylval.id = yytext[0]; return identifier;}
{numbers}          {yylval.num = atoi(yytext); return number;}
[.:-+*/=;]         {return yytext[0];}
[ \t\n]            ;
.      		       {ECHO; yyerror ("unexpected character");}

%%
int yywrap (void) {return 1;}
