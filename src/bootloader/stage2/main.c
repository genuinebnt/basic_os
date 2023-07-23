#include "stdint.h"
#include "stdio.h"

void _cdecl cstart_(uint16_t bootDrive)
{
    char letter = 'z';
    char word[] = "word";
    int number = 40;
    printf("Hello world!, %c %s %d hi there", letter, word, number);
}