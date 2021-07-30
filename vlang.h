#define IDLEN 31
#define SYMSIZE 52
#define VECLEN 255

/* Modes */
#define SET 0
#define GET 1

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
    char name[VECLEN];
    int indx;
    conType type;
    int ecounter;
    int size;
} expression;