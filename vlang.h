#define IDLEN 31
#define SYMSIZE 52

/* Modes */
#define SET 0
#define GET 1

typedef enum
{
    Assign,
    plus,
    minus,
    divide,
    mult
} operType;

typedef enum
{
    scalar,
    vector,
    constScal,
    constVec
} conType; /* variables types */

typedef struct{
    int size;
    int* val;
}nodeValue;

typedef struct 
{
    conType type;
    nodeValue value;
    int id;
    char name[IDLEN];
} nodeType;
