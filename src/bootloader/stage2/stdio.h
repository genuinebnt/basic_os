#pragma once

#include "stdint.h"

void putc(char c);
void puts(const char *str);
size_t strlen(const char *str);
int _cdecl printf_number(int *argp, int length, bool sign, int radix);
void print_int(const int *arg);
