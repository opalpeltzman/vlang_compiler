# Vlang Language Compiler
## Description
Course name: Automats and compilation.
The course final project, building a compiler from Vlang language to C file.
The compiler is built with the usage of Bison and Flex.
Vlang language id described in the attached Vlang.pdf file.

## Steps to run the compiler
```
1. Run "make" command in order to generate vlang.exe (Example: make)
2. Run the compiler using output file and input file containing vlang language/syntax  
   (Example: " ./vlang source.vlang out.c ")
3. Compile the output C file (Example: " gcc out.c -o out.exe ")
4. Run C file  (Example: " ./out.exe ")
```
### Important Info
The Vlang compiler is using Reserved words: "eX", when X indicates positive integer number (including 0).
Make sure you do not use reserved variables in your vlang input program.
