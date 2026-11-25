#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGEnvironment : NSObject

+ (BOOL)isWeChatMainAppBundle:(nullable NSString *)bundleID
                   bundlePath:(nullable NSString *)bundlePath;
+ (BOOL)isWeChatHostProcess;
+ (BOOL)isIOS26OrNewer;
+ (BOOL)isGlassRuntimeAvailable;
+ (BOOL)shouldActivatePlugin;
+ (NSString *)pluginVersion;
+ (NSString *)diagnosticSummary;

@end

NS_ASSUME_NONNULL_END
