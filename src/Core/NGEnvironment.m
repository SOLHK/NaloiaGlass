#import "NGEnvironment.h"
#import "NGCoreLogic.h"
#import <UIKit/UIKit.h>

@implementation NGEnvironment

+ (BOOL)isWeChatMainAppBundle:(NSString *)bundleID bundlePath:(NSString *)bundlePath {
    if (![bundleID isKindOfClass:NSString.class]) {
        return NO;
    }
    const char *cBundle = bundleID.UTF8String;
    const char *cPath = [bundlePath isKindOfClass:NSString.class] ? bundlePath.UTF8String : "";
    return NGIsEligibleWeChatBundleC(cBundle, cPath) ? YES : NO;
}

+ (BOOL)isWeChatHostProcess {
    static BOOL sChecked = NO;
    static BOOL sEligible = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *main = NSBundle.mainBundle;
        sEligible = [self isWeChatMainAppBundle:main.bundleIdentifier bundlePath:main.bundlePath];
        sChecked = YES;
    });
    (void)sChecked;
    return sEligible;
}

+ (BOOL)isIOS26OrNewer {
    return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26;
}

+ (BOOL)isGlassRuntimeAvailable {
    return [self isIOS26OrNewer] && (NSClassFromString(@"UIGlassEffect") != Nil);
}

+ (BOOL)shouldActivatePlugin {
    return [self isWeChatHostProcess] && [self isIOS26OrNewer];
}

+ (NSString *)pluginVersion {
    return @"1.0.0";
}

+ (NSString *)diagnosticSummary {
    NSBundle *bundle = NSBundle.mainBundle;
    NSOperatingSystemVersion ver = NSProcessInfo.processInfo.operatingSystemVersion;
    NSString *wechatVer = [bundle.infoDictionary objectForKey:@"CFBundleShortVersionString"] ?: @"unknown";
    return [NSString stringWithFormat:
            @"Naloia Glass %@\n"
            @"Bundle ID: %@\n"
            @"WeChat Version: %@\n"
            @"iOS Version: %ld.%ld.%ld\n"
            @"UIGlassEffect Available: %@\n"
            @"Reduce Transparency: %@\n"
            @"Plugin Activated: %@",
            [self pluginVersion],
            bundle.bundleIdentifier ?: @"(nil)",
            wechatVer,
            (long)ver.majorVersion, (long)ver.minorVersion, (long)ver.patchVersion,
            NSClassFromString(@"UIGlassEffect") ? @"YES" : @"NO",
            UIAccessibilityIsReduceTransparencyEnabled() ? @"YES" : @"NO",
            [self shouldActivatePlugin] ? @"YES" : @"NO"];
}

@end
