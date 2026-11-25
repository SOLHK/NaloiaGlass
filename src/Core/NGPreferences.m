#import "NGPreferences.h"
#import "NGCoreLogic.h"
#import "NGEnvironment.h"
#import <CoreFoundation/CoreFoundation.h>

NSNotificationName const NGPreferencesDidChangeNotification = @"com.solhk.naloiaglass.preferencesDidChange";

static NSString * const kNGKeyEnabled             = @"com.solhk.naloiaglass.enabled";
static NSString * const kNGKeyDockMode            = @"com.solhk.naloiaglass.dockMode";
static NSString * const kNGKeyClearGlass          = @"com.solhk.naloiaglass.clearGlass";
static NSString * const kNGKeyHideTabTitles       = @"com.solhk.naloiaglass.hideTabTitles";
static NSString * const kNGKeyDetachedRightButton = @"com.solhk.naloiaglass.detachedRightButton";
static NSString * const kNGKeyHapticEnabled       = @"com.solhk.naloiaglass.hapticEnabled";
static NSString * const kNGKeyHorizontalInset     = @"com.solhk.naloiaglass.horizontalInset";
static NSString * const kNGKeyDockHeight          = @"com.solhk.naloiaglass.dockHeight";
static NSString * const kNGKeyAccentHex           = @"com.solhk.naloiaglass.accentHex";

static NSString * const kNGDefaultAccentHex       = @"#07C160";
static NSString * const kNGSolariumPrefKey        = @"com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck";

@implementation NGPreferences

+ (instancetype)shared {
    static NGPreferences *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[NGPreferences alloc] init];
    });
    return sInstance;
}

- (NSUserDefaults *)store {
    return NSUserDefaults.standardUserDefaults;
}

- (void)notifyChanged {
    [self syncSolariumPreferenceKey];
    [NSNotificationCenter.defaultCenter postNotificationName:NGPreferencesDidChangeNotification object:self];
}

- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id obj = [self.store objectForKey:key];
    if ([obj respondsToSelector:@selector(boolValue)]) {
        return [obj boolValue];
    }
    return defaultValue;
}

- (BOOL)enabled {
    return [self boolForKey:kNGKeyEnabled defaultValue:YES];
}

- (void)setEnabled:(BOOL)enabled {
    [self.store setBool:enabled forKey:kNGKeyEnabled];
    [self notifyChanged];
}

- (NGDockMode)dockMode {
    id obj = [self.store objectForKey:kNGKeyDockMode];
    if ([obj respondsToSelector:@selector(integerValue)]) {
        return (NGDockMode)NGSanitizeDockModeC((long)[obj integerValue]);
    }
    return NGDockModeSystemNative;
}

- (void)setDockMode:(NGDockMode)dockMode {
    NGDockMode clean = (NGDockMode)NGSanitizeDockModeC((long)dockMode);
    [self.store setInteger:clean forKey:kNGKeyDockMode];
    [self notifyChanged];
}

- (NGDockMode)effectiveDockMode {
    if (!self.enabled || ![NGEnvironment shouldActivatePlugin]) {
        return NGDockModeDisabled;
    }
    return self.dockMode;
}

- (BOOL)clearGlass {
    return [self boolForKey:kNGKeyClearGlass defaultValue:NO];
}

- (void)setClearGlass:(BOOL)clearGlass {
    [self.store setBool:clearGlass forKey:kNGKeyClearGlass];
    [self notifyChanged];
}

- (BOOL)hideTabTitles {
    return [self boolForKey:kNGKeyHideTabTitles defaultValue:NO];
}

- (void)setHideTabTitles:(BOOL)hideTabTitles {
    [self.store setBool:hideTabTitles forKey:kNGKeyHideTabTitles];
    [self notifyChanged];
}

- (BOOL)detachedRightButton {
    return [self boolForKey:kNGKeyDetachedRightButton defaultValue:NO];
}

- (void)setDetachedRightButton:(BOOL)detachedRightButton {
    [self.store setBool:detachedRightButton forKey:kNGKeyDetachedRightButton];
    [self notifyChanged];
}

- (BOOL)hapticEnabled {
    return [self boolForKey:kNGKeyHapticEnabled defaultValue:YES];
}

- (void)setHapticEnabled:(BOOL)hapticEnabled {
    [self.store setBool:hapticEnabled forKey:kNGKeyHapticEnabled];
    [self notifyChanged];
}

- (CGFloat)horizontalInset {
    id obj = [self.store objectForKey:kNGKeyHorizontalInset];
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return (CGFloat)NGClampHorizontalInsetC([obj doubleValue]);
    }
    return 16.0;
}

- (void)setHorizontalInset:(CGFloat)horizontalInset {
    CGFloat clean = (CGFloat)NGClampHorizontalInsetC((double)horizontalInset);
    [self.store setDouble:(double)clean forKey:kNGKeyHorizontalInset];
    [self notifyChanged];
}

- (CGFloat)dockHeight {
    id obj = [self.store objectForKey:kNGKeyDockHeight];
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return (CGFloat)NGClampDockHeightC([obj doubleValue]);
    }
    return 52.0;
}

- (void)setDockHeight:(CGFloat)dockHeight {
    CGFloat clean = (CGFloat)NGClampDockHeightC((double)dockHeight);
    [self.store setDouble:(double)clean forKey:kNGKeyDockHeight];
    [self notifyChanged];
}

+ (NSString *)normalizedHexOrDefault:(NSString *)candidate {
    if (![candidate isKindOfClass:NSString.class]) {
        return kNGDefaultAccentHex;
    }
    unsigned int r = 0, g = 0, b = 0;
    if (!NGParseHexColorRGBC(candidate.UTF8String, &r, &g, &b)) {
        return kNGDefaultAccentHex;
    }
    return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

- (NSString *)accentHex {
    NSString *stored = [self.store stringForKey:kNGKeyAccentHex];
    return [NGPreferences normalizedHexOrDefault:stored];
}

- (void)setAccentHex:(NSString *)accentHex {
    NSString *normalized = [NGPreferences normalizedHexOrDefault:accentHex];
    [self.store setObject:normalized forKey:kNGKeyAccentHex];
    [self notifyChanged];
}

- (BOOL)isSolariumPreferenceActiveInSystem {
    CFPropertyListRef val = CFPreferencesCopyAppValue((__bridge CFStringRef)kNGSolariumPrefKey,
                                                      kCFPreferencesCurrentApplication);
    if (!val) {
        return [self.store boolForKey:kNGSolariumPrefKey];
    }
    BOOL active = NO;
    if ([(__bridge id)val respondsToSelector:@selector(boolValue)]) {
        active = [(__bridge id)val boolValue];
    }
    CFRelease(val);
    return active;
}

- (BOOL)syncSolariumPreferenceKey {
    if (![NGEnvironment isWeChatHostProcess]) {
        return NO;
    }
    NSInteger major = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
    bool shouldEnable = NGShouldWriteSolariumKeyC(self.enabled, (int)self.dockMode, (long)major);
    CFStringRef cfKey = (__bridge CFStringRef)kNGSolariumPrefKey;

    if (shouldEnable) {
        [self.store setBool:YES forKey:kNGSolariumPrefKey];
        CFPreferencesSetAppValue(cfKey, kCFBooleanTrue, kCFPreferencesCurrentApplication);
    } else {
        [self.store removeObjectForKey:kNGSolariumPrefKey];
        CFPreferencesSetAppValue(cfKey, NULL, kCFPreferencesCurrentApplication);
    }
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
    return shouldEnable ? YES : NO;
}

- (NSString *)exportJSONString {
    NSDictionary<NSString *, id> *payload = @{
        @"version": @1,
        @"enabled": @(self.enabled),
        @"dockMode": @(self.dockMode),
        @"clearGlass": @(self.clearGlass),
        @"hideTabTitles": @(self.hideTabTitles),
        @"detachedRightButton": @(self.detachedRightButton),
        @"hapticEnabled": @(self.hapticEnabled),
        @"horizontalInset": @(self.horizontalInset),
        @"dockHeight": @(self.dockHeight),
        @"accentHex": self.accentHex
    };
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload
                                                   options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys
                                                     error:&err];
    if (!data || err) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)importJSONString:(NSString *)json error:(NSError * _Nullable __autoreleasing *)error {
    if (![json isKindOfClass:NSString.class] || json.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.solhk.naloiaglass.error"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"配置文本为空"}];
        }
        return NO;
    }
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return NO;
    NSError *parseErr = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
    if (![parsed isKindOfClass:NSDictionary.class] || parseErr) {
        if (error) {
            *error = parseErr ?: [NSError errorWithDomain:@"com.solhk.naloiaglass.error"
                                                     code:1002
                                                 userInfo:@{NSLocalizedDescriptionKey: @"JSON 格式无效，需要字典对象"}];
        }
        return NO;
    }
    NSDictionary *dict = (NSDictionary *)parsed;
    if ([dict[@"enabled"] respondsToSelector:@selector(boolValue)]) {
        [self.store setBool:[dict[@"enabled"] boolValue] forKey:kNGKeyEnabled];
    }
    if ([dict[@"dockMode"] respondsToSelector:@selector(integerValue)]) {
        NSInteger cleanMode = NGSanitizeDockModeC((long)[dict[@"dockMode"] integerValue]);
        [self.store setInteger:cleanMode forKey:kNGKeyDockMode];
    }
    if ([dict[@"clearGlass"] respondsToSelector:@selector(boolValue)]) {
        [self.store setBool:[dict[@"clearGlass"] boolValue] forKey:kNGKeyClearGlass];
    }
    if ([dict[@"hideTabTitles"] respondsToSelector:@selector(boolValue)]) {
        [self.store setBool:[dict[@"hideTabTitles"] boolValue] forKey:kNGKeyHideTabTitles];
    }
    if ([dict[@"detachedRightButton"] respondsToSelector:@selector(boolValue)]) {
        [self.store setBool:[dict[@"detachedRightButton"] boolValue] forKey:kNGKeyDetachedRightButton];
    }
    if ([dict[@"hapticEnabled"] respondsToSelector:@selector(boolValue)]) {
        [self.store setBool:[dict[@"hapticEnabled"] boolValue] forKey:kNGKeyHapticEnabled];
    }
    if ([dict[@"horizontalInset"] respondsToSelector:@selector(doubleValue)]) {
        double cleanInset = NGClampHorizontalInsetC([dict[@"horizontalInset"] doubleValue]);
        [self.store setDouble:cleanInset forKey:kNGKeyHorizontalInset];
    }
    if ([dict[@"dockHeight"] respondsToSelector:@selector(doubleValue)]) {
        double cleanHeight = NGClampDockHeightC([dict[@"dockHeight"] doubleValue]);
        [self.store setDouble:cleanHeight forKey:kNGKeyDockHeight];
    }
    if ([dict[@"accentHex"] isKindOfClass:NSString.class]) {
        [self.store setObject:[NGPreferences normalizedHexOrDefault:dict[@"accentHex"]] forKey:kNGKeyAccentHex];
    }
    [self notifyChanged];
    return YES;
}

- (void)resetToDefaults {
    NSArray<NSString *> *keys = @[
        kNGKeyEnabled,
        kNGKeyDockMode,
        kNGKeyClearGlass,
        kNGKeyHideTabTitles,
        kNGKeyDetachedRightButton,
        kNGKeyHapticEnabled,
        kNGKeyHorizontalInset,
        kNGKeyDockHeight,
        kNGKeyAccentHex
    ];
    for (NSString *key in keys) {
        [self.store removeObjectForKey:key];
    }
    [self notifyChanged];
}

@end
