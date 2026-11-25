#pragma once
#include <stdbool.h>
#include <stdint.h>

typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFBoolean *CFBooleanRef;
typedef CFTypeRef CFPropertyListRef;
typedef unsigned char Boolean;

extern const CFBooleanRef kCFBooleanTrue;
extern const CFBooleanRef kCFBooleanFalse;
extern const CFStringRef kCFPreferencesCurrentApplication;
extern const CFStringRef kCFPreferencesCurrentUser;
extern const CFStringRef kCFPreferencesCurrentHost;

#define CFSTR(cStr) ((CFStringRef)__builtin___CFStringMakeConstantString("" cStr ""))

void CFPreferencesSetAppValue(CFStringRef key, CFPropertyListRef value, CFStringRef applicationID);
Boolean CFPreferencesAppSynchronize(CFStringRef applicationID);
CFPropertyListRef CFPreferencesCopyAppValue(CFStringRef key, CFStringRef applicationID);
Boolean CFBooleanGetValue(CFBooleanRef boolean);
void CFRelease(CFTypeRef cf);
