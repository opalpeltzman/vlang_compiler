%{
#include <stdio.h>
#include <string.h>
#include "vlang.h"
#include "vlang.tab.h"

void yyerror (char *s);
int yylex();

int getVecSize(char* input);
%}

ALPHA           [A-Za-z]
DIGIT           ([0-9])
constVector     \[[ ]*[0-9]+([ ]*,[ ]*[0-9]+[ ]*)*\]
vecSize         [{][0-9]+[}]

%%

"print"			                    {return print;}
"if"			                    {return if_stm;}
"loop"			                    {return loop;}
"exit"			                    {return exit_command;}
"scl"                               {return scl;}
"vec"                               {return vec;}
{ALPHA}({ALPHA}|{DIGIT})*		    {strcpy(yylval.vName, yytext); return identifier;}
{DIGIT}+                            {yylval.num = atoi(yytext); return number;}
{vecSize}                           {yylval.size = getVecSize(yytext); return vecSize;}
{constVector}                       {strcpy(yylval.elem, yytext); return constVector;}
[-+*/=;]                            {return yytext[0];}
"."                                 {return yytext[0];}
":"                                 {return yytext[0];}
"{"                                 {return yytext[0];}
"}"                                 {return yytext[0];}
"("                                 {return yytext[0];}
")"                                 {return yytext[0];}
","                                 {return yytext[0];}
[ \t\n]                             ;
.                                   {ECHO; yyerror ("unexpected character");}

%%
int yywrap (void) {return 1;}

int getVecSize(char* input){
    /* copy vector size */
    
    int arrSize = strlen(input);
    char temp[arrSize];
    strcpy(temp, input);

    char dest[arrSize-2];
    for(int i=1; i< arrSize; i++){
        if(temp[i] != '{' && temp[i] != '}'){
            dest[i-1] = temp[i];
        }
    }
    return atoi(dest);
}
