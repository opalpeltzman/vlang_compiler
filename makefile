calc.exe: lex.yy.c vlang.tab.c
	gcc lex.yy.c vlang.tab.c -o vlang.exe

lex.yy.c: vlang.tab.c vlang.l
	flex vlang.l

vlang.tab.c: vlang.y
	bison -d vlang.y

clean: 
	rm lex.yy.c vlang.tab.c vlang.tab.h vlang.exe