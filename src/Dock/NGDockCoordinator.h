#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const NGDockDidAttachMainTabBarNotification;

@interface NGDockCoordinator : NSObject

+ (instancetype)shared;
+ (NSArray<NSString *> *)mainTabBarControllerCandidates;

- (BOOL)isEligibleMainTabBarController:(UITabBarController *)controller;
- (BOOL)isManagedMainTabBar:(UITabBar *)tabBar;
- (void)attachIfEligible:(UITabBarController *)controller;
- (void)handleManagedTabBarLayout:(UITabBar *)tabBar;
- (void)refreshAllManagedTabBars;
- (NSString *)hierarchyDiagnosticReport;

@end

NS_ASSUME_NONNULL_END
