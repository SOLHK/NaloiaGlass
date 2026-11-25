#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGWeChatSettingsEntry : NSObject

+ (void)installEntryHooks;
+ (void)attachQuickGesturesToTabBar:(UITabBar *)tabBar;
+ (void)attachFallbackGestureToWindow:(nullable UIWindow *)window;
+ (void)presentSettingsFromViewController:(nullable UIViewController *)presenter;

@end

NS_ASSUME_NONNULL_END
