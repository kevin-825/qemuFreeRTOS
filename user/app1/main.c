#include <stdlib.h>
#include <stdio.h>
#include "fact.h"

int main(int argc, char **argv)
{
    for (int i=0; i<argc; i++){
        printf("%d %s\n",i, argv[i]);
    }
    uint64_t n = (uint64_t)argv[1];
    uint64_t N=factorial(n);
    printf("factorial of %lu is %lu \n ", n, N);
}