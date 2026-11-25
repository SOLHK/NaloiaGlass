#pragma once
#include <objc/objc.h>
#include <stdint.h>

typedef struct objc_method *Method;

typedef enum {
    OBJC_ASSOCIATION_ASSIGN = 0,
    OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
    OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
    OBJC_ASSOCIATION_RETAIN = 01401,
    OBJC_ASSOCIATION_COPY = 01403
} objc_AssociationPolicy;

Class objc_getClass(const char *name);
Class objc_lookUpClass(const char *name);
Class object_getClass(id obj);
Class class_getSuperclass(Class cls);
const char *class_getName(Class cls);
SEL sel_registerName(const char *str);
const char *sel_getName(SEL sel);

Method class_getInstanceMethod(Class cls, SEL name);
IMP method_getImplementation(Method m);
const char *method_getTypeEncoding(Method m);
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
void method_exchangeImplementations(Method m1, Method m2);

void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy);
id objc_getAssociatedObject(id object, const void *key);
