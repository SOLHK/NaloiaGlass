#pragma once
#include <objc/objc.h>

struct objc_super {
    __unsafe_unretained id receiver;
    __unsafe_unretained Class super_class;
};

void objc_msgSend(void);
void objc_msgSendSuper(void);
