#define IDLEN 31
#define SYMSIZE 52
#define VECLEN 255

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
    coVector,
    coScalar
} conType; /* variables types */

typedef struct 
{
    conType type;
    int size;
    int indx;
    char name[IDLEN];
} nodeType;

typedef enum
{
    constScl,
    constVec,
    symbolTab
} arrayType;/* table types */

typedef struct 
{
    int size;
    int indx;
    char val[VECLEN];
} ConstVecnodeType;

typedef struct 
{
    int indx;
    int val;
} ConstSclnodeType;

typedef struct 
{
    int indx;
    conType type;
    int ecounter;
} expression;