#import <UIKit/UIKit.h>
#import "NGDockCoordinator.h"
#import "NGEnvironment.h"
#import "NGPreferences.h"
#import "NGRuntimeBridge.h"
#import "NGWeChatSettingsEntry.h"

static IMP gOrigTBCViewDidAppear = NULL;
static IMP gOrigTBCViewDidLayoutSubviews = NULL;
static IMP gOrigTBCSetSelectedIndex = NULL;
static IMP gOrigTBCSetSelectedViewController = NULL;

static IMP gOrigTabBarLayoutSubviews = NULL;
static IMP gOrigTabBarSetItemsAnimated = NULL;

static void NGTBCViewDidAppearHook(UITabBarController *self, SEL _cmd, BOOL animated) {
    if (gOrigTBCViewDidAppear) {
        ((void (*)(id, SEL, BOOL))gOrigTBCViewDidAppear)(self, _cmd, animated);
    }
    if ([NGEnvironment shouldActivatePlugin]) {
        [NGDockCoordinator.shared attachIfEligible:self];
    }
}

static void NGTBCViewDidLayoutSubviewsHook(UITabBarController *self, SEL _cmd) {
    if (gOrigTBCViewDidLayoutSubviews) {
        ((void (*)(id, SEL))gOrigTBCViewDidLayoutSubviews)(self, _cmd);
    }
    if ([NGEnvironment shouldActivatePlugin]) {
        [NGDockCoordinator.shared attachIfEligible:self];
    }
}

static void NGTBCSetSelectedIndexHook(UITabBarController *self, SEL _cmd, NSUInteger index) {
    if (gOrigTBCSetSelectedIndex) {
        ((void (*)(id, SEL, NSUInteger))gOrigTBCSetSelectedIndex)(self, _cmd, index);
    }
    if ([NGEnvironment shouldActivatePlugin] && [NGDockCoordinator.shared isManagedMainTabBar:self.tabBar]) {
        [NGDockCoordinator.shared handleManagedTabBarLayout:self.tabBar];
    }
}

static void NGTBCSetSelectedViewControllerHook(UITabBarController *self, SEL _cmd, UIViewController *vc) {
    if (gOrigTBCSetSelectedViewController) {
        ((void (*)(id, SEL, id))gOrigTBCSetSelectedViewController)(self, _cmd, vc);
    }
    if ([NGEnvironment shouldActivatePlugin] && [NGDockCoordinator.shared isManagedMainTabBar:self.tabBar]) {
        [NGDockCoordinator.shared handleManagedTabBarLayout:self.tabBar];
    }
}

static void NGTabBarLayoutSubviewsHook(UITabBar *self, SEL _cmd) {
    if (gOrigTabBarLayoutSubviews) {
        ((void (*)(id, SEL))gOrigTabBarLayoutSubviews)(self, _cmd);
    }
    // Single associated-object check short-circuits all non-main UITabBar instances immediately.
    if ([NGDockCoordinator.shared isManagedMainTabBar:self]) {
        [NGDockCoordinator.shared handleManagedTabBarLayout:self];
    }
}

static void NGTabBarSetItemsAnimatedHook(UITabBar *self, SEL _cmd, NSArray<UITabBarItem *> *items, BOOL animated) {
    if (gOrigTabBarSetItemsAnimated) {
        ((void (*)(id, SEL, id, BOOL))gOrigTabBarSetItemsAnimated)(self, _cmd, items, animated);
    }
    if ([NGDockCoordinator.shared isManagedMainTabBar:self]) {
        [NGDockCoordinator.shared handleManagedTabBarLayout:self];
    }
}

static void NGInstallScopedTabBarHooks(void) {
    Class tbcCls = UITabBarController.class;
    NGSwizzleInstanceMethod(tbcCls, @selector(viewDidAppear:),
                            (IMP)NGTBCViewDidAppearHook, &gOrigTBCViewDidAppear);
    NGSwizzleInstanceMethod(tbcCls, @selector(viewDidLayoutSubviews),
                            (IMP)NGTBCViewDidLayoutSubviewsHook, &gOrigTBCViewDidLayoutSubviews);
    NGSwizzleInstanceMethod(tbcCls, @selector(setSelectedIndex:),
                            (IMP)NGTBCSetSelectedIndexHook, &gOrigTBCSetSelectedIndex);
    NGSwizzleInstanceMethod(tbcCls, @selector(setSelectedViewController:),
                            (IMP)NGTBCSetSelectedViewControllerHook, &gOrigTBCSetSelectedViewController);

    Class tbCls = UITabBar.class;
    NGSwizzleInstanceMethod(tbCls, @selector(layoutSubviews),
                            (IMP)NGTabBarLayoutSubviewsHook, &gOrigTabBarLayoutSubviews);
    NGSwizzleInstanceMethod(tbCls, sel_registerName("setItems:animated:"),
                            (IMP)NGTabBarSetItemsAnimatedHook, &gOrigTabBarSetItemsAnimated);
}

// Priority 101 runs before UIKit/SwiftUI reads IgnoreSolariumLinkedOnCheck at startup.
__attribute__((constructor(101)))
static void NaloiaGlassEarlyConstructor(void) {
    @autoreleasepool {
        if (![NGEnvironment isWeChatHostProcess]) {
            return;
        }

        // Synchronize or clean up IgnoreSolariumLinkedOnCheck immediately on launch.
        [NGPreferences.shared syncSolariumPreferenceKey];

        if ([NGEnvironment isIOS26OrNewer]) {
            NGInstallScopedTabBarHooks();
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [NGWeChatSettingsEntry installEntryHooks];
        });
    }
}
