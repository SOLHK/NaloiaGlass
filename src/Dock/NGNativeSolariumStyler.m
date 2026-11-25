#import "NGNativeSolariumStyler.h"
#import "NGSolariumLogic.h"
#import <objc/runtime.h>

static char kNGSolariumBackdropSnapshotsKey;
static char kNGSolariumItemTitleSnapshotsKey;

@implementation NGNativeSolariumStyler

+ (void)applyToMainTabBar:(UITabBar *)tabBar hideTitles:(BOOL)hideTitles {
    if (!tabBar) return;

    [self suppressWeChatLegacyBackdropsInTabBar:tabBar];
    if (hideTitles) {
        [self hideTitlesInTabBar:tabBar];
    } else {
        [self restoreTitlesInTabBar:tabBar];
    }
}

+ (void)suppressWeChatLegacyBackdropsInTabBar:(UITabBar *)tabBar {
    NSMutableArray<NSDictionary *> *snapshots = objc_getAssociatedObject(tabBar, &kNGSolariumBackdropSnapshotsKey);
    if (!snapshots) {
        snapshots = [NSMutableArray arrayWithCapacity:4];
        objc_setAssociatedObject(tabBar, &kNGSolariumBackdropSnapshotsKey, snapshots, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat barWidth = CGRectGetWidth(tabBar.bounds);
    NSUInteger inspected = 0;

    for (UIView *sub in tabBar.subviews) {
        if (inspected >= 32) break;
        inspected++;

        NSString *clsName = NSStringFromClass(sub.class) ?: @"";
        BOOL isVEV = [sub isKindOfClass:UIVisualEffectView.class];
        CGRect f = sub.frame;

        if (!NGShouldHideWeChatTabBarBackdropViewC(clsName.UTF8String,
                                                   (long)sub.tag,
                                                   isVEV ? true : false,
                                                   (double)CGRectGetWidth(f),
                                                   (double)barWidth,
                                                   (double)CGRectGetHeight(f))) {
            continue;
        }

        BOOL alreadyRecorded = NO;
        for (NSDictionary *entry in snapshots) {
            if (entry[@"view"] == sub) {
                alreadyRecorded = YES;
                break;
            }
        }
        if (!alreadyRecorded) {
            [snapshots addObject:@{
                @"view": sub,
                @"hidden": @(sub.hidden),
                @"alpha": @(sub.alpha)
            }];
        }
        sub.hidden = YES;
        sub.alpha = 0.0;
    }
}

+ (void)hideTitlesInTabBar:(UITabBar *)tabBar {
    NSArray<UITabBarItem *> *items = tabBar.items;
    if (items.count == 0) return;

    NSMutableArray<NSDictionary *> *saved = objc_getAssociatedObject(tabBar, &kNGSolariumItemTitleSnapshotsKey);
    if (!saved) {
        saved = [NSMutableArray arrayWithCapacity:items.count];
        objc_setAssociatedObject(tabBar, &kNGSolariumItemTitleSnapshotsKey, saved, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UITabBarItem *item in items) {
        BOOL recorded = NO;
        for (NSDictionary *entry in saved) {
            if (entry[@"item"] == item) {
                recorded = YES;
                break;
            }
        }
        if (!recorded) {
            UIEdgeInsets ins = item.imageInsets;
            [saved addObject:@{
                @"item": item,
                @"title": item.title ?: NSNull.null,
                @"top": @(ins.top),
                @"left": @(ins.left),
                @"bottom": @(ins.bottom),
                @"right": @(ins.right)
            }];
        }
        if (item.title.length > 0) {
            item.title = @"";
        }
        item.imageInsets = UIEdgeInsetsMake(5.0, 0.0, -5.0, 0.0);
    }
}

+ (void)restoreTitlesInTabBar:(UITabBar *)tabBar {
    NSArray<NSDictionary *> *saved = objc_getAssociatedObject(tabBar, &kNGSolariumItemTitleSnapshotsKey);
    if (!saved) return;

    for (NSDictionary *entry in saved) {
        UITabBarItem *item = entry[@"item"];
        id rawTitle = entry[@"title"];
        item.title = (rawTitle == NSNull.null) ? nil : (NSString *)rawTitle;
        item.imageInsets = UIEdgeInsetsMake([entry[@"top"] doubleValue],
                                            [entry[@"left"] doubleValue],
                                            [entry[@"bottom"] doubleValue],
                                            [entry[@"right"] doubleValue]);
    }
    objc_setAssociatedObject(tabBar, &kNGSolariumItemTitleSnapshotsKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

+ (void)restoreTabBar:(UITabBar *)tabBar {
    if (!tabBar) return;

    NSArray<NSDictionary *> *snapshots = objc_getAssociatedObject(tabBar, &kNGSolariumBackdropSnapshotsKey);
    for (NSDictionary *entry in snapshots) {
        UIView *view = entry[@"view"];
        view.hidden = [entry[@"hidden"] boolValue];
        view.alpha = (CGFloat)[entry[@"alpha"] doubleValue];
    }
    objc_setAssociatedObject(tabBar, &kNGSolariumBackdropSnapshotsKey, nil, OBJC_ASSOCIATION_ASSIGN);

    [self restoreTitlesInTabBar:tabBar];
}

@end
