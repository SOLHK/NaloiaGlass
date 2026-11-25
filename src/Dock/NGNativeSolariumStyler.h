#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGNativeSolariumStyler : NSObject

+ (void)applyToMainTabBar:(UITabBar *)tabBar hideTitles:(BOOL)hideTitles;
+ (void)restoreTabBar:(UITabBar *)tabBar;

@end

NS_ASSUME_NONNULL_END
