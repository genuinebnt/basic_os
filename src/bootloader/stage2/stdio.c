#include "stdio.h"
#include "stdint.h"
#include "X86.h"

void putc(char c)
{
    X86_Video_WriteCharTeletype(c, 0);
}

void puts(const char *str)
{
    while (*str)
    {
        putc(*str);
        str++;
    }
}