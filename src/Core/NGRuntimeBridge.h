#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

BOOL NGSwizzleInstanceMethod(Class cls,
                             SEL originalSel,
                             IMP replacementImp,
                             IMP _Nullable * _Nonnull outOriginalImp);

UIVisualEffect * _Nullable NGCreateLiquidGlassEffect(BOOL clearVariant, BOOL interactive);
UIVisualEffectView * _Nullable NGCreateLiquidGlassView(BOOL clearVariant, BOOL interactive);
void NGApplyCapsuleCorners(UIView *view, CGFloat fallbackRadius);
UIColor *NGColorFromHexString(NSString * _Nullable hex, UIColor *fallback);

NS_ASSUME_NONNULL_END
