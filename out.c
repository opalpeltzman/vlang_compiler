#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
	int e0[] = {2,4,8,5};
	int e1[] = {7,1,1,1};
	int e2[4] = {0};
	for(int i = 0; i < 4; i++){
		if(e1[i] >= 0 && e1[i] < 4){
			e2[i] = e0[e1[i]];
		}
		else{fprintf (stderr, "index out of range"); exit(0);}
	}
	printf("[");
	for(int i = 0; i < 4 - 1; i++){
		printf("%d,",e2[i]);
	}
	printf("%d", e2[4 - 1]);
	printf("]\n");

	return 0;
}