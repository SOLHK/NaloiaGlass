#pragma once
#include <objc/objc.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <dispatch/dispatch.h>
#include <stdint.h>
#include <stdlib.h>

typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef double NSTimeInterval;

#define NSIntegerMax LONG_MAX
#define NSNotFound ((NSInteger)0x7fffffffffffffffL)

#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#define NS_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define NS_ASSUME_NONNULL_END   _Pragma("clang assume_nonnull end")
#define FOUNDATION_EXPORT extern

@class NSString, NSArray, NSDictionary, NSError, NSInvocation;

@protocol NSObject
- (BOOL)isEqual:(nullable id)object;
@property (readonly) NSUInteger hash;
@property (readonly) Class superclass;
- (Class)class;
- (instancetype)self;
- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)respondsToSelector:(SEL)aSelector;
@property (readonly, copy) NSString *description;
@end

@protocol NSCopying
- (id)copyWithZone:(nullable void *)zone;
@end

@protocol NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(void *)state objects:(id __unsafe_unretained _Nullable * _Nonnull)buffer count:(NSUInteger)len;
@end

@interface NSObject <NSObject>
+ (instancetype)alloc;
+ (instancetype)new;
- (instancetype)init;
+ (Class)class;
+ (BOOL)instancesRespondToSelector:(SEL)aSelector;
- (nullable id)valueForKey:(NSString *)key;
- (void)setValue:(nullable id)value forKey:(NSString *)key;
- (IMP)methodForSelector:(SEL)aSelector;
- (id)copy;
@end

typedef NSString *NSNotificationName;
typedef NSString *NSErrorDomain;
typedef NSUInteger NSStringEncoding;
#define NSUTF8StringEncoding 4

typedef NS_OPTIONS(NSUInteger, NSStringCompareOptions) {
    NSCaseInsensitiveSearch = 1
};

typedef struct _NSRange { NSUInteger location; NSUInteger length; } NSRange;

@interface NSCharacterSet : NSObject
+ (NSCharacterSet *)whitespaceAndNewlineCharacterSet;
@end

@interface NSString : NSObject <NSCopying>
@property (readonly) NSUInteger length;
@property (readonly, nullable) const char *UTF8String;
+ (instancetype)stringWithFormat:(NSString *)format, ...;
- (instancetype)initWithData:(id)data encoding:(NSStringEncoding)encoding;
- (BOOL)isEqualToString:(NSString *)aString;
- (BOOL)hasPrefix:(NSString *)str;
- (BOOL)hasSuffix:(NSString *)str;
- (BOOL)containsString:(NSString *)str;
- (NSRange)rangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask;
- (NSString *)stringByTrimmingCharactersInSet:(NSCharacterSet *)set;
- (NSString *)uppercaseString;
- (nullable id)dataUsingEncoding:(NSStringEncoding)encoding;
@property (readonly) double doubleValue;
@property (readonly) NSInteger integerValue;
@property (readonly) BOOL boolValue;
@end

@interface NSMutableString : NSString
+ (instancetype)string;
- (void)appendString:(NSString *)aString;
- (void)appendFormat:(NSString *)format, ...;
@end

@interface NSAttributedString : NSObject <NSCopying>
@end

@interface NSValue : NSObject <NSCopying>
@end

@interface NSNumber : NSValue
+ (NSNumber *)numberWithBool:(BOOL)value;
+ (NSNumber *)numberWithInt:(int)value;
+ (NSNumber *)numberWithInteger:(NSInteger)value;
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value;
+ (NSNumber *)numberWithDouble:(double)value;
+ (NSNumber *)numberWithFloat:(float)value;
@property (readonly) BOOL boolValue;
@property (readonly) NSInteger integerValue;
@property (readonly) NSUInteger unsignedIntegerValue;
@property (readonly) double doubleValue;
@property (readonly) float floatValue;
@property (readonly, copy) NSString *stringValue;
@end

@interface NSNull : NSObject <NSCopying>
+ (NSNull *)null;
@end

@interface NSData : NSObject <NSCopying>
@property (readonly) NSUInteger length;
@end

@interface NSArray<__covariant ObjectType> : NSObject <NSCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
@property (nullable, nonatomic, readonly) ObjectType firstObject;
@property (nullable, nonatomic, readonly) ObjectType lastObject;
+ (instancetype)array;
+ (instancetype)arrayWithObjects:(const ObjectType _Nonnull [_Nullable])objects count:(NSUInteger)cnt;
- (ObjectType)objectAtIndex:(NSUInteger)index;
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;
- (BOOL)containsObject:(ObjectType)anObject;
- (NSUInteger)indexOfObject:(ObjectType)anObject;
- (NSString *)componentsJoinedByString:(NSString *)separator;
@end

@interface NSMutableArray<ObjectType> : NSArray<ObjectType>
+ (instancetype)arrayWithCapacity:(NSUInteger)numItems;
- (void)addObject:(ObjectType)anObject;
- (void)addObjectsFromArray:(NSArray<ObjectType> *)otherArray;
- (void)removeAllObjects;
- (void)removeObject:(ObjectType)anObject;
@end

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> : NSObject <NSCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
+ (instancetype)dictionaryWithObjects:(const ObjectType _Nonnull [_Nullable])objects forKeys:(const KeyType _Nonnull [_Nullable])keys count:(NSUInteger)cnt;
- (nullable ObjectType)objectForKey:(KeyType)aKey;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
@end

@interface NSMutableDictionary<KeyType, ObjectType> : NSDictionary<KeyType, ObjectType>
+ (instancetype)dictionary;
- (void)setObject:(ObjectType)anObject forKey:(KeyType)aKey;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType)key;
@end

@interface NSSet<__covariant ObjectType> : NSObject <NSCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
@property (readonly, copy) NSArray<ObjectType> *allObjects;
+ (instancetype)setWithArray:(NSArray<ObjectType> *)array;
- (BOOL)containsObject:(ObjectType)anObject;
@end

@interface NSMutableSet<ObjectType> : NSSet<ObjectType>
+ (instancetype)set;
- (void)addObject:(ObjectType)object;
@end

@interface NSHashTable<ObjectType> : NSObject <NSFastEnumeration>
@property (readonly, copy) NSArray<ObjectType> *allObjects;
+ (NSHashTable<ObjectType> *)weakObjectsHashTable;
- (void)addObject:(nullable ObjectType)object;
- (BOOL)containsObject:(nullable ObjectType)anObject;
@end

extern NSErrorDomain const NSCocoaErrorDomain;
extern NSString * const NSLocalizedDescriptionKey;

@interface NSError : NSObject
@property (readonly, copy) NSString *localizedDescription;
+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code userInfo:(nullable NSDictionary<NSString *, id> *)dict;
@end

typedef NS_OPTIONS(NSUInteger, NSJSONWritingOptions) {
    NSJSONWritingPrettyPrinted = (1UL << 0),
    NSJSONWritingSortedKeys = (1UL << 1)
};
typedef NS_OPTIONS(NSUInteger, NSJSONReadingOptions) {
    NSJSONReadingFragmentsAllowed = (1UL << 2)
};

@interface NSJSONSerialization : NSObject
+ (nullable NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError * _Nullable * _Nullable)error;
+ (nullable id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError * _Nullable * _Nullable)error;
@end

@interface NSUserDefaults : NSObject
@property (class, readonly, strong) NSUserDefaults *standardUserDefaults;
- (nullable id)objectForKey:(NSString *)defaultName;
- (void)setObject:(nullable id)value forKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
- (double)doubleForKey:(NSString *)defaultName;
- (void)setDouble:(double)value forKey:(NSString *)defaultName;
- (NSInteger)integerForKey:(NSString *)defaultName;
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;
- (nullable NSString *)stringForKey:(NSString *)defaultName;
- (BOOL)synchronize;
@end

@interface NSBundle : NSObject
@property (class, readonly, strong) NSBundle *mainBundle;
@property (nullable, readonly, copy) NSString *bundleIdentifier;
@property (readonly, copy) NSString *bundlePath;
@property (nullable, readonly, copy) NSDictionary<NSString *, id> *infoDictionary;
@end

typedef struct {
    NSInteger majorVersion;
    NSInteger minorVersion;
    NSInteger patchVersion;
} NSOperatingSystemVersion;

@interface NSProcessInfo : NSObject
@property (class, readonly, strong) NSProcessInfo *processInfo;
@property (readonly) NSOperatingSystemVersion operatingSystemVersion;
@property (readonly) NSTimeInterval systemUptime;
@end

@interface NSNotification : NSObject
@property (readonly, copy) NSNotificationName name;
@property (nullable, readonly, strong) id object;
@end

@interface NSNotificationCenter : NSObject
@property (class, readonly, strong) NSNotificationCenter *defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;
- (void)removeObserver:(id)observer;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
@end

@interface NSThread : NSObject
@property (class, readonly) BOOL isMainThread;
@end

@interface NSIndexPath : NSObject
@property (nonatomic, readonly) NSInteger section;
@property (nonatomic, readonly) NSInteger row;
+ (instancetype)indexPathForRow:(NSInteger)row inSection:(NSInteger)section;
@end

@interface NSException : NSObject
@end

Class _Nullable NSClassFromString(NSString *aClassName);
NSString *NSStringFromClass(Class aClass);
SEL NSSelectorFromString(NSString *aSelectorName);
void NSLog(NSString *format, ...);
