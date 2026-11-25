#import "NGWeChatSettingsEntry.h"
#import "NGDockCoordinator.h"
#import "NGEnvironment.h"
#import "NGPreferences.h"
#import "NGRuntimeBridge.h"
#import "NGSettingsViewController.h"
#import <objc/message.h>
#import <objc/runtime.h>

static char kNGTabBarLongPressGestureKey;
static char kNGWindowTripleTapGestureKey;

static IMP gNGOrigReloadTableData = NULL;
static BOOL gNGSettingsControllerHooked = NO;
static BOOL gNGInsideReloadTableData = NO;

static NSString *NGCurrentModeStatusText(void) {
    NGPreferences *prefs = NGPreferences.shared;
    if (!prefs.enabled) return @"已关闭";
    if (![NGEnvironment isIOS26OrNewer]) return @"需 iOS 26+";
    return (prefs.dockMode == NGDockModeFloatingCapsule) ? @"悬浮胶囊" : @"系统原生";
}

static void NGOpenNaloiaGlassSettingsImpl(id self, SEL _cmd) {
    (void)_cmd;
    if (![self isKindOfClass:UIViewController.class]) return;
    UIViewController *vc = (UIViewController *)self;
    if (vc.navigationController) {
        NGSettingsViewController *settingsVC = [[NGSettingsViewController alloc] init];
        [vc.navigationController pushViewController:settingsVC animated:YES];
    } else {
        [NGWeChatSettingsEntry presentSettingsFromViewController:vc];
    }
}

static void NGReloadTableDataHookImpl(id self, SEL _cmd) {
    if (gNGOrigReloadTableData) {
        ((void (*)(id, SEL))gNGOrigReloadTableData)(self, _cmd);
    }
    if (gNGInsideReloadTableData) return;
    gNGInsideReloadTableData = YES;
    @try {
        id tableViewMgr = [self valueForKey:@"m_tableViewMgr"];
        if (!tableViewMgr) return;

        SEL getSectionSel = sel_registerName("getSectionAt:");
        if (![tableViewMgr respondsToSelector:getSectionSel]) return;
        id firstSection = ((id (*)(id, SEL, NSInteger))objc_msgSend)(tableViewMgr, getSectionSel, 0);
        if (!firstSection) return;

        SEL cellsSel = sel_registerName("cells");
        SEL setCellsSel = sel_registerName("setCells:");
        if (![firstSection respondsToSelector:cellsSel] || ![firstSection respondsToSelector:setCellsSel]) return;

        NSArray *existingCells = ((id (*)(id, SEL))objc_msgSend)(firstSection, cellsSel);
        if (![existingCells isKindOfClass:NSArray.class]) existingCells = @[];

        SEL titleSel = sel_registerName("title");
        for (id cell in existingCells) {
            if ([cell respondsToSelector:titleSel]) {
                id titleObj = ((id (*)(id, SEL))objc_msgSend)(cell, titleSel);
                if ([titleObj isKindOfClass:NSString.class] &&
                    [(NSString *)titleObj isEqualToString:@"Naloia Glass"]) {
                    return;
                }
            }
        }

        Class cellMgrCls = objc_getClass("WCTableViewNormalCellManager");
        SEL factorySel = sel_registerName("normalCellForSel:target:title:rightValue:accessoryType:");
        if (!cellMgrCls || ![cellMgrCls respondsToSelector:factorySel]) return;

        SEL openSel = sel_registerName("ng_openNaloiaGlassSettings");
        id entryCell = ((id (*)(id, SEL, SEL, id, id, id, NSInteger))objc_msgSend)(
            cellMgrCls,
            factorySel,
            openSel,
            self,
            @"Naloia Glass",
            NGCurrentModeStatusText(),
            1
        );
        if (!entryCell) return;

        NSMutableArray *updated = [NSMutableArray arrayWithCapacity:existingCells.count + 1];
        [updated addObject:entryCell];
        [updated addObjectsFromArray:existingCells];
        ((void (*)(id, SEL, id))objc_msgSend)(firstSection, setCellsSel, updated);

        SEL getTableSel = sel_registerName("getTableView");
        if ([tableViewMgr respondsToSelector:getTableSel]) {
            id tableView = ((id (*)(id, SEL))objc_msgSend)(tableViewMgr, getTableSel);
            if ([tableView isKindOfClass:UITableView.class]) {
                [(UITableView *)tableView reloadData];
            }
        }
    } @catch (NSException *e) {
        (void)e;
    } @finally {
        gNGInsideReloadTableData = NO;
    }
}

@implementation NGWeChatSettingsEntry

+ (void)installEntryHooks {
    if (![NGEnvironment isWeChatHostProcess]) return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(handleMainTabBarAttached:)
                                                   name:NGDockDidAttachMainTabBarNotification
                                                 object:nil];
    });
    [self tryInstallWeChatSettingsRowWithAttempt:0];
}

+ (void)tryInstallWeChatSettingsRowWithAttempt:(NSInteger)attempt {
    if (gNGSettingsControllerHooked || attempt > 24) return;

    const char *candidates[] = {
        "NewSettingViewController",
        "MMNewSettingViewController",
        "WCNewSettingViewController",
        "SettingViewController",
        "MoreSettingViewController"
    };
    Class targetCls = Nil;
    for (size_t i = 0; i < sizeof(candidates) / sizeof(candidates[0]); i++) {
        Class cls = objc_getClass(candidates[i]);
        if (cls && class_getInstanceMethod(cls, sel_registerName("reloadTableData"))) {
            targetCls = cls;
            break;
        }
    }

    if (targetCls) {
        SEL openSel = sel_registerName("ng_openNaloiaGlassSettings");
        class_addMethod(targetCls, openSel, (IMP)NGOpenNaloiaGlassSettingsImpl, "v@:");
        if (NGSwizzleInstanceMethod(targetCls,
                                    sel_registerName("reloadTableData"),
                                    (IMP)NGReloadTableDataHookImpl,
                                    &gNGOrigReloadTableData)) {
            gNGSettingsControllerHooked = YES;
        }
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tryInstallWeChatSettingsRowWithAttempt:attempt + 1];
    });
}

+ (void)handleMainTabBarAttached:(NSNotification *)note {
    if ([note.object isKindOfClass:UITabBar.class]) {
        UITabBar *bar = (UITabBar *)note.object;
        [self attachQuickGesturesToTabBar:bar];
        [self attachFallbackGestureToWindow:bar.window];
    }
}

+ (void)attachQuickGesturesToTabBar:(UITabBar *)tabBar {
    if (!tabBar || !NSThread.isMainThread) return;
    if (objc_getAssociatedObject(tabBar, &kNGTabBarLongPressGestureKey)) return;

    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTabBarLongPressed:)];
    longPress.minimumPressDuration = 0.80;
    longPress.cancelsTouchesInView = NO;
    [tabBar addGestureRecognizer:longPress];
    objc_setAssociatedObject(tabBar, &kNGTabBarLongPressGestureKey, longPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)attachFallbackGestureToWindow:(UIWindow *)window {
    if (!window || !NSThread.isMainThread) return;
    if (objc_getAssociatedObject(window, &kNGWindowTripleTapGestureKey)) return;

    UITapGestureRecognizer *tripleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onWindowTripleTapped:)];
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.numberOfTapsRequired = 3;
    tripleTap.cancelsTouchesInView = NO;
    [window addGestureRecognizer:tripleTap];
    objc_setAssociatedObject(window, &kNGWindowTripleTapGestureKey, tripleTap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)onTabBarLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan && gesture.view.window) {
        [self presentSettingsFromViewController:gesture.view.window.rootViewController];
    }
}

+ (void)onWindowTripleTapped:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized && gesture.view.window) {
        [self presentSettingsFromViewController:gesture.view.window.rootViewController];
    }
}

+ (void)presentSettingsFromViewController:(UIViewController *)presenter {
    if (!NSThread.isMainThread || !presenter) return;

    UIViewController *top = presenter;
    for (NSUInteger depth = 0; depth < 16 && top.presentedViewController; depth++) {
        top = top.presentedViewController;
    }
    if (top.isBeingDismissed || [top isKindOfClass:UIAlertController.class]) return;
    if ([top isKindOfClass:NGSettingsViewController.class]) return;
    if ([top isKindOfClass:UINavigationController.class] &&
        [((UINavigationController *)top).topViewController isKindOfClass:NGSettingsViewController.class]) {
        return;
    }

    NGSettingsViewController *settingsVC = [[NGSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [top presentViewController:nav animated:YES completion:nil];
}

@end
