#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
	int a[3];
	int e0[] = {10,0,20};
	memcpy(a, e0, sizeof(a));
	int i;
	int e1 = 0;
	i = e1;
	printf("%d", i);
	printf(" : ");
	printf("[");
	for(int i = 0; i < 3 - 1; i++){
		printf("%d,",a[i]);
	}
	printf("%d", a[3 - 1]);
	printf("]\n");
	int e2[] = {1,2};
	printf("[");
	for(int i = 0; i < 2 - 1; i++){
		printf("%d,",e2[i]);
	}
	printf("%d", e2[2 - 1]);
	printf("]");
	printf(" : ");
	printf("[");
	for(int i = 0; i < 3 - 1; i++){
		printf("%d,",a[i]);
	}
	printf("%d", a[3 - 1]);
	printf("]\n");
	printf("%d", i);
	printf(" : ");
	printf("%d", i);
	printf(" : ");
	printf("%d", i);
	printf(" : ");
	printf("[");
	for(int i = 0; i < 3 - 1; i++){
		printf("%d,",a[i]);
	}
	printf("%d", a[3 - 1]);
	printf("]\n");

	return 0;
}