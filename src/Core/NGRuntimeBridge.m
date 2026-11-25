#import "NGRuntimeBridge.h"
#import "NGCoreLogic.h"
#import "NGEnvironment.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

static NSMutableSet<NSString *> *NGInstalledSwizzleTokens(void) {
    static NSMutableSet<NSString *> *sTokens = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sTokens = [NSMutableSet set];
    });
    return sTokens;
}

BOOL NGSwizzleInstanceMethod(Class cls,
                             SEL originalSel,
                             IMP replacementImp,
                             IMP _Nullable * _Nonnull outOriginalImp) {
    if (!cls || !originalSel || !replacementImp || !outOriginalImp) {
        return NO;
    }
    NSString *token = [NSString stringWithFormat:@"%s::%s",
                       class_getName(cls), sel_getName(originalSel)];
    @synchronized (NGInstalledSwizzleTokens()) {
        if ([NGInstalledSwizzleTokens() containsObject:token]) {
            return NO;
        }
        Method method = class_getInstanceMethod(cls, originalSel);
        if (!method) {
            return NO;
        }
        const char *types = method_getTypeEncoding(method);
        IMP prev = class_replaceMethod(cls, originalSel, replacementImp, types);
        if (!prev) {
            prev = method_getImplementation(method);
        }
        *outOriginalImp = prev;
        [NGInstalledSwizzleTokens() addObject:token];
        return YES;
    }
}

UIVisualEffect *NGCreateLiquidGlassEffect(BOOL clearVariant, BOOL interactive) {
    if (![NGEnvironment isIOS26OrNewer] || UIAccessibilityIsReduceTransparencyEnabled()) {
        return nil;
    }
    Class glassCls = objc_lookUpClass("UIGlassEffect");
    SEL styleSel = sel_registerName("effectWithStyle:");
    if (!glassCls || ![glassCls respondsToSelector:styleSel]) {
        return nil;
    }
    // UIGlassEffectStyleRegular = 0, UIGlassEffectStyleClear = 1 in iOS 26 UIKit.
    NSInteger style = clearVariant ? 1 : 0;
    id effect = ((id (*)(id, SEL, NSInteger))objc_msgSend)(glassCls, styleSel, style);
    if (![effect isKindOfClass:UIVisualEffect.class]) {
        return nil;
    }
    SEL interactiveSel = sel_registerName("setInteractive:");
    if ([effect respondsToSelector:interactiveSel]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(effect, interactiveSel, interactive);
    }
    return (UIVisualEffect *)effect;
}

UIVisualEffectView *NGCreateLiquidGlassView(BOOL clearVariant, BOOL interactive) {
    UIVisualEffect *effect = NGCreateLiquidGlassEffect(clearVariant, interactive);
    if (!effect) {
        return nil;
    }
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
    view.backgroundColor = UIColor.clearColor;
    view.contentView.backgroundColor = UIColor.clearColor;
    view.opaque = NO;
    view.userInteractionEnabled = NO;
    view.accessibilityElementsHidden = YES;
    return view;
}

void NGApplyCapsuleCorners(UIView *view, CGFloat fallbackRadius) {
    if (!view) return;
    Class cornerCls = objc_lookUpClass("UICornerConfiguration");
    SEL capsuleSel = sel_registerName("capsuleConfiguration");
    SEL setConfigSel = sel_registerName("setCornerConfiguration:");
    if (cornerCls && [cornerCls respondsToSelector:capsuleSel] && [view respondsToSelector:setConfigSel]) {
        id config = ((id (*)(id, SEL))objc_msgSend)(cornerCls, capsuleSel);
        if (config) {
            ((void (*)(id, SEL, id))objc_msgSend)(view, setConfigSel, config);
            return;
        }
    }
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.cornerRadius = MAX(0.0, fallbackRadius);
}

UIColor *NGColorFromHexString(NSString *hex, UIColor *fallback) {
    UIColor *safeFallback = fallback ?: [UIColor colorWithRed:7.0 / 255.0 green:193.0 / 255.0 blue:96.0 / 255.0 alpha:1.0];
    if (![hex isKindOfClass:NSString.class]) {
        return safeFallback;
    }
    unsigned int r = 0, g = 0, b = 0;
    if (!NGParseHexColorRGBC(hex.UTF8String, &r, &g, &b)) {
        return safeFallback;
    }
    return [UIColor colorWithRed:((CGFloat)r) / 255.0
                           green:((CGFloat)g) / 255.0
                            blue:((CGFloat)b) / 255.0
                           alpha:1.0];
}
