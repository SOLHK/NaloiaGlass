#pragma once
#include <stddef.h>
#define LONG_MAX __LONG_MAX__
void *malloc(size_t size);
void free(void *ptr);
void exit(int status) __attribute__((noreturn));
