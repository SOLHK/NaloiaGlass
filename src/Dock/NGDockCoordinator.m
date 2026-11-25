#import "NGDockCoordinator.h"
#import "NGCapsuleDockView.h"
#import "NGEnvironment.h"
#import "NGNativeSolariumStyler.h"
#import "NGPreferences.h"
#import <objc/runtime.h>

NSNotificationName const NGDockDidAttachMainTabBarNotification = @"com.solhk.naloiaglass.didAttachMainTabBar";

static char kNGManagedOwnerControllerKey;
static char kNGNotifiedWindowAttachKey;
static char kNGOriginalStandardAppearanceKey;
static char kNGOriginalScrollEdgeAppearanceKey;
static char kNGOriginalTintColorKey;
static char kNGHiddenNativeButtonsKey;
static char kNGCapsuleOverlayViewKey;
static char kNGAppliedModeStampKey;

@interface NGWeakControllerBox : NSObject
@property (nonatomic, weak, nullable) UITabBarController *controller;
@end

@implementation NGWeakControllerBox
@end

@interface NGDockCoordinator ()
@property (nonatomic, strong) NSHashTable<UITabBarController *> *managedControllers;
@property (nonatomic, assign) BOOL isApplyingLayout;
@end

@implementation NGDockCoordinator

+ (instancetype)shared {
    static NGDockCoordinator *sCoordinator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sCoordinator = [[NGDockCoordinator alloc] initPrivate];
    });
    return sCoordinator;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _managedControllers = [NSHashTable weakObjectsHashTable];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(handlePreferencesChanged:)
                                                   name:NGPreferencesDidChangeNotification
                                                 object:nil];
    }
    return self;
}

+ (NSArray<NSString *> *)mainTabBarControllerCandidates {
    return @[
        @"MMTabBarController",
        @"MMTabBarControllerLite",
        @"MainTabBarController",
        @"WCTabBarController"
    ];
}

- (void)handlePreferencesChanged:(NSNotification *)note {
    (void)note;
    [self refreshAllManagedTabBars];
}

- (BOOL)classHierarchyMatchesMainCandidates:(UIViewController *)controller {
    NSSet<NSString *> *candidates = [NSSet setWithArray:[NGDockCoordinator mainTabBarControllerCandidates]];
    for (Class cls = object_getClass(controller); cls && cls != NSObject.class; cls = class_getSuperclass(cls)) {
        if ([candidates containsObject:NSStringFromClass(cls)]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isEligibleMainTabBarController:(UITabBarController *)controller {
    if (![controller isKindOfClass:UITabBarController.class] || !controller.isViewLoaded) {
        return NO;
    }
    UITabBar *bar = controller.tabBar;
    if (!bar || bar.items.count < 3 || bar.items.count > 6) {
        return NO;
    }
    if ([self classHierarchyMatchesMainCandidates:controller]) {
        return YES;
    }
    UIWindow *win = controller.view.window;
    if (!win) return NO;
    UIViewController *root = win.rootViewController;
    if (root == controller) return YES;
    if ([root.childViewControllers containsObject:controller]) return YES;
    return NO;
}

- (BOOL)isManagedMainTabBar:(UITabBar *)tabBar {
    if (!tabBar) return NO;
    NGWeakControllerBox *box = objc_getAssociatedObject(tabBar, &kNGManagedOwnerControllerKey);
    return [box isKindOfClass:NGWeakControllerBox.class] && (box.controller != nil);
}

- (void)attachIfEligible:(UITabBarController *)controller {
    if (!NSThread.isMainThread || ![NGEnvironment shouldActivatePlugin]) {
        return;
    }
    if (![self isEligibleMainTabBarController:controller]) {
        return;
    }
    UITabBar *bar = controller.tabBar;
    NGWeakControllerBox *box = objc_getAssociatedObject(bar, &kNGManagedOwnerControllerKey);
    BOOL firstAttach = (box == nil);
    if (!box) {
        box = [[NGWeakControllerBox alloc] init];
        objc_setAssociatedObject(bar, &kNGManagedOwnerControllerKey, box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    box.controller = controller;
    [self.managedControllers addObject:controller];

    BOOL windowNewlyAvailable = (bar.window != nil && !objc_getAssociatedObject(bar, &kNGNotifiedWindowAttachKey));
    if (bar.window != nil && windowNewlyAvailable) {
        objc_setAssociatedObject(bar, &kNGNotifiedWindowAttachKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (firstAttach || windowNewlyAvailable) {
        [NSNotificationCenter.defaultCenter postNotificationName:NGDockDidAttachMainTabBarNotification object:bar];
    }
    [self applyCurrentModeToController:controller];
}

- (void)handleManagedTabBarLayout:(UITabBar *)tabBar {
    if (!NSThread.isMainThread || self.isApplyingLayout || ![NGEnvironment shouldActivatePlugin]) {
        return;
    }
    NGWeakControllerBox *box = objc_getAssociatedObject(tabBar, &kNGManagedOwnerControllerKey);
    UITabBarController *controller = [box isKindOfClass:NGWeakControllerBox.class] ? box.controller : nil;
    if (![controller isKindOfClass:UITabBarController.class] || controller.tabBar != tabBar) {
        return;
    }
    if (tabBar.window != nil && !objc_getAssociatedObject(tabBar, &kNGNotifiedWindowAttachKey)) {
        objc_setAssociatedObject(tabBar, &kNGNotifiedWindowAttachKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [NSNotificationCenter.defaultCenter postNotificationName:NGDockDidAttachMainTabBarNotification object:tabBar];
    }
    [self applyCurrentModeToController:controller];
}

- (void)refreshAllManagedTabBars {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshAllManagedTabBars];
        });
        return;
    }
    for (UITabBarController *controller in self.managedControllers.allObjects) {
        if (controller.isViewLoaded) {
            [self applyCurrentModeToController:controller];
        }
    }
}

- (NSArray<UIView *> *)liveNativeTabButtonsInTabBar:(UITabBar *)bar {
    NSMutableArray<UIView *> *buttons = [NSMutableArray arrayWithCapacity:bar.items.count];
    for (UIView *sub in bar.subviews) {
        if ([NSStringFromClass(sub.class) isEqualToString:@"UITabBarButton"]) {
            [buttons addObject:sub];
        }
    }
    return buttons;
}

- (BOOL)areHiddenSnapshotsCurrentForTabBar:(UITabBar *)bar {
    NSArray<NSDictionary *> *snapshots = objc_getAssociatedObject(bar, &kNGHiddenNativeButtonsKey);
    if (!snapshots || snapshots.count != bar.items.count) {
        return NO;
    }
    NSArray<UIView *> *liveButtons = [self liveNativeTabButtonsInTabBar:bar];
    if (liveButtons.count != snapshots.count) {
        return NO;
    }
    for (UIView *live in liveButtons) {
        BOOL found = NO;
        for (NSDictionary *entry in snapshots) {
            if (entry[@"view"] == live) {
                found = YES;
                break;
            }
        }
        if (!found) return NO;
    }
    return YES;
}

- (NSArray<UIView *> *)snapshotAndHideNativeButtonsInTabBar:(UITabBar *)bar {
    NSArray<UIView *> *liveButtons = [self liveNativeTabButtonsInTabBar:bar];
    if (liveButtons.count != bar.items.count || liveButtons.count == 0) {
        return @[];
    }
    NSMutableArray<NSDictionary *> *snapshots = [NSMutableArray arrayWithCapacity:liveButtons.count];
    for (UIView *btn in liveButtons) {
        [snapshots addObject:@{
            @"view": btn,
            @"alpha": @(btn.alpha),
            @"interaction": @(btn.userInteractionEnabled)
        }];
        btn.alpha = 0.0;
        btn.userInteractionEnabled = NO;
    }
    objc_setAssociatedObject(bar, &kNGHiddenNativeButtonsKey, snapshots, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return liveButtons;
}

- (void)restoreHiddenNativeButtonsInTabBar:(UITabBar *)bar {
    NSArray<NSDictionary *> *snapshots = objc_getAssociatedObject(bar, &kNGHiddenNativeButtonsKey);
    for (NSDictionary *entry in snapshots) {
        UIView *btn = entry[@"view"];
        btn.alpha = (CGFloat)[entry[@"alpha"] doubleValue];
        btn.userInteractionEnabled = [entry[@"interaction"] boolValue];
    }
    objc_setAssociatedObject(bar, &kNGHiddenNativeButtonsKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

- (void)backupAppearanceIfNeededForTabBar:(UITabBar *)bar {
    if (!objc_getAssociatedObject(bar, &kNGOriginalStandardAppearanceKey)) {
        objc_setAssociatedObject(bar, &kNGOriginalStandardAppearanceKey,
                                 [bar.standardAppearance copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar, &kNGOriginalScrollEdgeAppearanceKey,
                                 bar.scrollEdgeAppearance ? [bar.scrollEdgeAppearance copy] : NSNull.null,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar, &kNGOriginalTintColorKey,
                                 bar.tintColor ?: NSNull.null,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)restoreTabBarToNativeState:(UITabBar *)bar {
    if (!bar) return;

    NGCapsuleDockView *capsule = objc_getAssociatedObject(bar, &kNGCapsuleOverlayViewKey);
    [capsule removeFromSuperview];
    objc_setAssociatedObject(bar, &kNGCapsuleOverlayViewKey, nil, OBJC_ASSOCIATION_ASSIGN);

    [self restoreHiddenNativeButtonsInTabBar:bar];
    [NGNativeSolariumStyler restoreTabBar:bar];

    UITabBarAppearance *origStd = objc_getAssociatedObject(bar, &kNGOriginalStandardAppearanceKey);
    if (origStd) {
        bar.standardAppearance = origStd;
    }
    id origEdge = objc_getAssociatedObject(bar, &kNGOriginalScrollEdgeAppearanceKey);
    if (origEdge) {
        bar.scrollEdgeAppearance = (origEdge == NSNull.null) ? nil : (UITabBarAppearance *)origEdge;
    }
    id origTint = objc_getAssociatedObject(bar, &kNGOriginalTintColorKey);
    if (origTint) {
        bar.tintColor = (origTint == NSNull.null) ? nil : (UIColor *)origTint;
    }

    objc_setAssociatedObject(bar, &kNGOriginalStandardAppearanceKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kNGOriginalScrollEdgeAppearanceKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kNGOriginalTintColorKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kNGAppliedModeStampKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

- (CGRect)capsuleHostFrameForTabBar:(UITabBar *)bar {
    CGFloat safeBottom = bar.safeAreaInsets.bottom;
    CGFloat homeIndicatorClearance = safeBottom > 14.0 ? (safeBottom - 12.0) : safeBottom;
    CGFloat desiredHeight = NGPreferences.shared.dockHeight;
    CGFloat contentAreaHeight = MAX(desiredHeight, CGRectGetHeight(bar.bounds) - homeIndicatorClearance);
    return CGRectMake(0.0, 0.0, CGRectGetWidth(bar.bounds), contentAreaHeight);
}

- (void)applyCurrentModeToController:(UITabBarController *)controller {
    if (self.isApplyingLayout) return;
    UITabBar *bar = controller.tabBar;
    if (!bar || CGRectIsEmpty(bar.bounds)) return;

    self.isApplyingLayout = YES;
    @try {
        NGPreferences *prefs = NGPreferences.shared;
        NGDockMode mode = [prefs effectiveDockMode];
        NSString *stamp = [NSString stringWithFormat:@"%ld-%d-%d-%d-%.1f-%.1f-%@-%lu",
                           (long)mode,
                           prefs.clearGlass,
                           prefs.hideTabTitles,
                           prefs.detachedRightButton,
                           prefs.horizontalInset,
                           prefs.dockHeight,
                           prefs.accentHex,
                           (unsigned long)bar.items.count];
        NSString *prevStamp = objc_getAssociatedObject(bar, &kNGAppliedModeStampKey);

        if (mode == NGDockModeDisabled) {
            if (prevStamp != nil) {
                [self restoreTabBarToNativeState:bar];
            }
            return;
        }

        if (mode == NGDockModeSystemNative) {
            if (![prevStamp hasPrefix:@"1-"]) {
                [self restoreTabBarToNativeState:bar];
            }
            [NGNativeSolariumStyler applyToMainTabBar:bar hideTitles:prefs.hideTabTitles];
            objc_setAssociatedObject(bar, &kNGAppliedModeStampKey, stamp, OBJC_ASSOCIATION_COPY_NONATOMIC);
            return;
        }

        if (mode == NGDockModeFloatingCapsule) {
            NGCapsuleDockView *existing = objc_getAssociatedObject(bar, &kNGCapsuleOverlayViewKey);
            if ([prevStamp isEqualToString:stamp] && existing && [self areHiddenSnapshotsCurrentForTabBar:bar]) {
                [NGNativeSolariumStyler suppressWeChatLegacyBackdropsInTabBar:bar];
                CGRect desired = [self capsuleHostFrameForTabBar:bar];
                if (!CGRectEqualToRect(existing.frame, desired)) {
                    existing.frame = desired;
                }
                if (bar.subviews.lastObject != existing) {
                    [bar bringSubviewToFront:existing];
                }
                [existing refreshBadgeStatesOnly];
                [existing refreshAppearanceAndSelectionAnimated:NO];
                return;
            }

            [self restoreTabBarToNativeState:bar];
            [self backupAppearanceIfNeededForTabBar:bar];
            [NGNativeSolariumStyler suppressWeChatLegacyBackdropsInTabBar:bar];

            NSArray<UIView *> *hiddenButtons = [self snapshotAndHideNativeButtonsInTabBar:bar];
            if (hiddenButtons.count == 0) {
                return;
            }

            UITabBarAppearance *transparent = [bar.standardAppearance copy];
            [transparent configureWithTransparentBackground];
            bar.standardAppearance = transparent;
            bar.scrollEdgeAppearance = transparent;

            NGCapsuleDockView *dock = [[NGCapsuleDockView alloc] initWithFrame:[self capsuleHostFrameForTabBar:bar]];
            dock.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            dock.controller = controller;
            dock.nativeButtonsSnapshot = hiddenButtons;
            [bar addSubview:dock];
            [dock reloadFromController];

            objc_setAssociatedObject(bar, &kNGCapsuleOverlayViewKey, dock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(bar, &kNGAppliedModeStampKey, stamp, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    } @finally {
        self.isApplyingLayout = NO;
    }
}

- (NSString *)hierarchyDiagnosticReport {
    NSMutableString *report = [NSMutableString string];
    [report appendFormat:@"%@\n", [NGEnvironment diagnosticSummary]];

    NGPreferences *prefs = NGPreferences.shared;
    [report appendFormat:@"Effective Mode: %ld | Solarium Key In System: %@\n",
     (long)[prefs effectiveDockMode],
     [prefs isSolariumPreferenceActiveInSystem] ? @"YES" : @"NO"];

    NSMutableArray<NSString *> *loadedCandidates = [NSMutableArray array];
    for (NSString *name in [NGDockCoordinator mainTabBarControllerCandidates]) {
        if (NSClassFromString(name)) {
            [loadedCandidates addObject:name];
        }
    }
    [report appendFormat:@"Loaded TabVC Candidates: %@\n",
     loadedCandidates.count ? [loadedCandidates componentsJoinedByString:@", "] : @"(none)"];

    NSArray<UITabBarController *> *controllers = self.managedControllers.allObjects;
    [report appendFormat:@"Managed TabBarControllers: %lu\n", (unsigned long)controllers.count];
    for (UITabBarController *tbc in controllers) {
        UITabBar *bar = tbc.tabBar;
        [report appendFormat:@"- %@ (items=%lu, frame=%.0fx%.0f)\n",
         NSStringFromClass(tbc.class),
         (unsigned long)bar.items.count,
         CGRectGetWidth(bar.frame),
         CGRectGetHeight(bar.frame)];
        for (UIView *sub in bar.subviews) {
            [report appendFormat:@"  * %@ tag=%ld hidden=%d alpha=%.2f frame=(%.0f,%.0f %.0fx%.0f)\n",
             NSStringFromClass(sub.class),
             (long)sub.tag,
             sub.hidden,
             sub.alpha,
             CGRectGetMinX(sub.frame), CGRectGetMinY(sub.frame),
             CGRectGetWidth(sub.frame), CGRectGetHeight(sub.frame)];
        }
    }
    return report;
}

@end
