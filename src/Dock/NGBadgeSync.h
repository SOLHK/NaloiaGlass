#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGBadgeState : NSObject
@property (nonatomic, copy, nullable, readonly) NSString *textBadge;
@property (nonatomic, assign, readonly) BOOL showsDot;
- (instancetype)initWithTextBadge:(nullable NSString *)textBadge showsDot:(BOOL)showsDot;
@end

@interface NGBadgeSync : NSObject
+ (NGBadgeState *)resolveBadgeForItem:(nullable UITabBarItem *)item
                         nativeButton:(nullable UIView *)nativeButton;
@end

NS_ASSUME_NONNULL_END
