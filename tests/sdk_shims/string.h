#pragma once
#include <stddef.h>
size_t strlen(const char *s);
int strcmp(const char *s1, const char *s2);
int strncmp(const char *s1, const char *s2, size_t n);
const char *strstr(const char *haystack, const char *needle);
void *memcpy(void *dst, const void *src, size_t n);
void *memset(void *b, int c, size_t len);
