#import "NGBadgeSync.h"
#import "NGBadgeLogic.h"

@implementation NGBadgeState

- (instancetype)initWithTextBadge:(NSString *)textBadge showsDot:(BOOL)showsDot {
    self = [super init];
    if (self) {
        _textBadge = [textBadge copy];
        _showsDot = showsDot;
    }
    return self;
}

@end

@implementation NGBadgeSync

+ (BOOL)isPredominantlyRedColor:(UIColor *)color {
    if (!color) return NO;
    UIColor *resolved = [color resolvedColorWithTraitCollection:UITraitCollection.currentTraitCollection];
    CGFloat r = 0.0, g = 0.0, b = 0.0, a = 0.0;
    if (![resolved getRed:&r green:&g blue:&b alpha:&a]) {
        return NO;
    }
    return (a > 0.35 && r > 0.72 && g < 0.38 && b < 0.38);
}

+ (NGBadgeState *)resolveBadgeForItem:(UITabBarItem *)item nativeButton:(UIView *)nativeButton {
    if (item.badgeValue.length > 0) {
        return [[NGBadgeState alloc] initWithTextBadge:item.badgeValue showsDot:NO];
    }
    if (![nativeButton isKindOfClass:UIView.class]) {
        return [[NGBadgeState alloc] initWithTextBadge:nil showsDot:NO];
    }

    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithCapacity:16];
    if (nativeButton.subviews.count > 0) {
        [queue addObjectsFromArray:nativeButton.subviews];
    }

    // Bounded breadth-first scan of the native UITabBarButton subtree to catch
    // WeChat's custom Moments/Discover unread dot views without touching deep trees.
    for (NSUInteger idx = 0; idx < queue.count && idx < 24; idx++) {
        UIView *sub = queue[idx];
        CGRect bounds = sub.bounds;
        NSString *clsName = NSStringFromClass(sub.class) ?: @"";
        BOOL redBg = [self isPredominantlyRedColor:sub.backgroundColor];

        if (NGIsLikelyUnreadIndicatorViewC(clsName.UTF8String,
                                           (double)CGRectGetWidth(bounds),
                                           (double)CGRectGetHeight(bounds),
                                           sub.hidden ? true : false,
                                           (double)sub.alpha,
                                           redBg ? true : false)) {
            // Check if a custom WeChat badge label inside this view actually holds text.
            if ([sub isKindOfClass:UILabel.class]) {
                NSString *txt = ((UILabel *)sub).text;
                if (txt.length > 0) {
                    return [[NGBadgeState alloc] initWithTextBadge:txt showsDot:NO];
                }
            }
            return [[NGBadgeState alloc] initWithTextBadge:nil showsDot:YES];
        }

        if (sub.subviews.count > 0 && queue.count < 24) {
            [queue addObjectsFromArray:sub.subviews];
        }
    }

    return [[NGBadgeState alloc] initWithTextBadge:nil showsDot:NO];
}

@end
