#pragma once
#include <stdbool.h>
#include <stddef.h>

typedef struct objc_class *Class;
typedef struct objc_object *id;
typedef struct objc_selector *SEL;
typedef void (*IMP)(void);
typedef bool BOOL;

#define YES __objc_yes
#define NO  __objc_no
#define nil ((id)0)
#define Nil ((Class)0)
