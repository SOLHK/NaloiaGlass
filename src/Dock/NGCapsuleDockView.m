#import "NGCapsuleDockView.h"
#import "NGBadgeLogic.h"
#import "NGBadgeSync.h"
#import "NGPreferences.h"
#import "NGRuntimeBridge.h"
#import <QuartzCore/QuartzCore.h>

@interface NGDockItemSlotView : UIView
@property (nonatomic, strong) UIView *scaleContainer;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *badgePill;
@property (nonatomic, strong) UIView *unreadDot;
@property (nonatomic, strong) UIButton *hitButton;
@property (nonatomic, strong, nullable) UIImage *normalImage;
@property (nonatomic, strong, nullable) UIImage *selectedImage;
@property (nonatomic, assign) BOOL hideTitle;
@property (nonatomic, assign) BOOL itemSelected;
- (void)applyBadgeState:(NGBadgeState *)state;
@end

@implementation NGDockItemSlotView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = NO;

        _scaleContainer = [[UIView alloc] initWithFrame:self.bounds];
        _scaleContainer.backgroundColor = UIColor.clearColor;
        _scaleContainer.userInteractionEnabled = NO;
        [self addSubview:_scaleContainer];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.userInteractionEnabled = NO;
        [_scaleContainer addSubview:_iconView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.userInteractionEnabled = NO;
        [_scaleContainer addSubview:_titleLabel];

        _badgePill = [[UILabel alloc] initWithFrame:CGRectZero];
        _badgePill.font = [UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightSemibold];
        _badgePill.textColor = UIColor.whiteColor;
        _badgePill.backgroundColor = UIColor.systemRedColor;
        _badgePill.textAlignment = NSTextAlignmentCenter;
        _badgePill.clipsToBounds = YES;
        _badgePill.userInteractionEnabled = NO;
        _badgePill.hidden = YES;
        [_scaleContainer addSubview:_badgePill];

        _unreadDot = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 8.0, 8.0)];
        _unreadDot.backgroundColor = UIColor.systemRedColor;
        _unreadDot.layer.cornerRadius = 4.0;
        _unreadDot.userInteractionEnabled = NO;
        _unreadDot.hidden = YES;
        [_scaleContainer addSubview:_unreadDot];

        // Keep hitButton above all siblings so iOS 26 glass subviews never swallow taps.
        _hitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _hitButton.frame = self.bounds;
        _hitButton.backgroundColor = UIColor.clearColor;
        _hitButton.isAccessibilityElement = YES;
        [_hitButton addTarget:self action:@selector(onTouchDown)
             forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [_hitButton addTarget:self action:@selector(onTouchRelease)
             forControlEvents:UIControlEventTouchCancel | UIControlEventTouchDragExit | UIControlEventTouchUpOutside];
        [self addSubview:_hitButton];
    }
    return self;
}

- (void)onTouchDown {
    if (UIAccessibilityIsReduceMotionEnabled()) return;
    [UIView animateWithDuration:0.13
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.scaleContainer.transform = CGAffineTransformMakeScale(0.88, 0.88);
    } completion:nil];
}

- (void)onTouchRelease {
    if (UIAccessibilityIsReduceMotionEnabled()) {
        self.scaleContainer.transform = CGAffineTransformIdentity;
        return;
    }
    [UIView animateWithDuration:0.38
                          delay:0.0
         usingSpringWithDamping:0.58
          initialSpringVelocity:0.55
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.scaleContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)applyBadgeState:(NGBadgeState *)state {
    if (state.textBadge.length > 0) {
        self.badgePill.text = state.textBadge;
        self.badgePill.hidden = NO;
        self.unreadDot.hidden = YES;
        self.hitButton.accessibilityValue = [NSString stringWithFormat:@"%@ 条未读", state.textBadge];
    } else if (state.showsDot) {
        self.badgePill.hidden = YES;
        self.unreadDot.hidden = NO;
        self.hitButton.accessibilityValue = @"有新动态";
    } else {
        self.badgePill.hidden = YES;
        self.unreadDot.hidden = YES;
        self.hitButton.accessibilityValue = nil;
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.bounds;
    self.scaleContainer.bounds = b;
    self.scaleContainer.center = CGPointMake(CGRectGetMidX(b), CGRectGetMidY(b));
    self.hitButton.frame = b;

    CGFloat iconSize = self.hideTitle ? 25.0 : 22.0;
    if (self.hideTitle || self.titleLabel.text.length == 0) {
        self.titleLabel.hidden = YES;
        self.iconView.frame = CGRectMake(CGRectGetMidX(b) - iconSize * 0.5,
                                         CGRectGetMidY(b) - iconSize * 0.5,
                                         iconSize, iconSize);
    } else {
        self.titleLabel.hidden = NO;
        CGFloat totalH = iconSize + 2.0 + 12.0;
        CGFloat startY = (CGRectGetHeight(b) - totalH) * 0.5;
        self.iconView.frame = CGRectMake(CGRectGetMidX(b) - iconSize * 0.5,
                                         startY,
                                         iconSize, iconSize);
        self.titleLabel.frame = CGRectMake(2.0,
                                           CGRectGetMaxY(self.iconView.frame) + 1.5,
                                           MAX(0.0, CGRectGetWidth(b) - 4.0),
                                           12.0);
    }

    if (!self.badgePill.hidden) {
        CGSize fit = [self.badgePill sizeThatFits:CGSizeMake(48.0, 16.0)];
        CGFloat pillW = MAX(16.0, MIN(36.0, fit.width + 8.0));
        CGFloat pillH = 16.0;
        self.badgePill.frame = CGRectMake(CGRectGetMaxX(self.iconView.frame) - 6.0,
                                          MAX(2.0, CGRectGetMinY(self.iconView.frame) - 4.0),
                                          pillW, pillH);
        self.badgePill.layer.cornerRadius = pillH * 0.5;
    }
    if (!self.unreadDot.hidden) {
        self.unreadDot.frame = CGRectMake(CGRectGetMaxX(self.iconView.frame) - 2.0,
                                          MAX(3.0, CGRectGetMinY(self.iconView.frame) - 2.0),
                                          8.0, 8.0);
    }
}

@end

@interface NGCapsuleDockView ()
@property (nonatomic, strong) UIView *capsuleContainer;
@property (nonatomic, strong, nullable) UIVisualEffectView *capsuleGlassView;
@property (nonatomic, strong) UIView *capsuleSelectionLens;

@property (nonatomic, strong) UIView *orbContainer;
@property (nonatomic, strong, nullable) UIVisualEffectView *orbGlassView;
@property (nonatomic, strong) UIView *orbSelectionLens;

@property (nonatomic, strong) NSMutableArray<NGDockItemSlotView *> *slotViews;
@property (nonatomic, copy, nullable) NSArray<UITabBarItem *> *previewItems;
@property (nonatomic, assign) NSUInteger previewSelectedIndex;
@property (nonatomic, assign) BOOL appliedClearVariant;
@property (nonatomic, assign) BOOL hasAppliedGlassOnce;
@end

@implementation NGCapsuleDockView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = NO;
        self.accessibilityIdentifier = @"com.solhk.naloiaglass.capsuleDock";
        _slotViews = [NSMutableArray arrayWithCapacity:5];

        _capsuleContainer = [[UIView alloc] initWithFrame:CGRectZero];
        _capsuleContainer.backgroundColor = UIColor.clearColor;
        _capsuleContainer.layer.borderWidth = 0.5;
        _capsuleContainer.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.26].CGColor;
        [self addSubview:_capsuleContainer];

        _capsuleSelectionLens = [[UIView alloc] initWithFrame:CGRectZero];
        _capsuleSelectionLens.userInteractionEnabled = NO;
        _capsuleSelectionLens.layer.cornerCurve = kCACornerCurveContinuous;
        [_capsuleContainer addSubview:_capsuleSelectionLens];

        _orbContainer = [[UIView alloc] initWithFrame:CGRectZero];
        _orbContainer.backgroundColor = UIColor.clearColor;
        _orbContainer.layer.borderWidth = 0.5;
        _orbContainer.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.26].CGColor;
        _orbContainer.hidden = YES;
        [self addSubview:_orbContainer];

        _orbSelectionLens = [[UIView alloc] initWithFrame:CGRectZero];
        _orbSelectionLens.userInteractionEnabled = NO;
        _orbSelectionLens.layer.cornerCurve = kCACornerCurveContinuous;
        [_orbContainer addSubview:_orbSelectionLens];

        [self rebuildGlassSurfacesIfNeeded];
    }
    return self;
}

- (void)rebuildGlassSurfacesIfNeeded {
    BOOL clear = NGPreferences.shared.clearGlass;
    BOOL reduceTrans = UIAccessibilityIsReduceTransparencyEnabled();
    if (self.hasAppliedGlassOnce && self.appliedClearVariant == clear &&
        ((reduceTrans && !self.capsuleGlassView) || (!reduceTrans && self.capsuleGlassView != nil))) {
        return;
    }
    self.hasAppliedGlassOnce = YES;
    self.appliedClearVariant = clear;

    [self.capsuleGlassView removeFromSuperview];
    [self.orbGlassView removeFromSuperview];
    self.capsuleGlassView = NGCreateLiquidGlassView(clear, YES);
    self.orbGlassView = NGCreateLiquidGlassView(clear, YES);

    if (self.capsuleGlassView) {
        self.capsuleContainer.backgroundColor = UIColor.clearColor;
        [self.capsuleContainer insertSubview:self.capsuleGlassView atIndex:0];
    } else {
        self.capsuleContainer.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    }

    if (self.orbGlassView) {
        self.orbContainer.backgroundColor = UIColor.clearColor;
        [self.orbContainer insertSubview:self.orbGlassView atIndex:0];
    } else {
        self.orbContainer.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    }
}

- (NSArray<UITabBarItem *> *)activeTabItems {
    if (self.controller) {
        return self.controller.tabBar.items ?: @[];
    }
    return self.previewItems ?: @[];
}

- (NSUInteger)activeSelectedIndex {
    NSArray<UITabBarItem *> *items = [self activeTabItems];
    if (items.count == 0) return 0;
    NSUInteger idx = self.controller ? self.controller.selectedIndex : self.previewSelectedIndex;
    if (idx >= items.count) idx = 0;
    return idx;
}

- (void)configureForPreviewItems:(NSArray<UITabBarItem *> *)items selectedIndex:(NSUInteger)selectedIndex {
    self.controller = nil;
    self.previewItems = items;
    self.previewSelectedIndex = selectedIndex;
    [self rebuildSlotsForItems:items];
    [self refreshAppearanceAndSelectionAnimated:NO];
}

- (void)reloadFromController {
    NSArray<UITabBarItem *> *items = [self activeTabItems];
    if (items.count < 2 || items.count > 6) return;
    [self rebuildGlassSurfacesIfNeeded];
    [self rebuildSlotsForItems:items];
    [self refreshBadgeStatesOnly];
    [self refreshAppearanceAndSelectionAnimated:NO];
}

- (void)rebuildSlotsForItems:(NSArray<UITabBarItem *> *)items {
    if (self.slotViews.count != items.count) {
        for (NGDockItemSlotView *slot in self.slotViews) {
            [slot removeFromSuperview];
        }
        [self.slotViews removeAllObjects];
        for (NSUInteger i = 0; i < items.count; i++) {
            NGDockItemSlotView *slot = [[NGDockItemSlotView alloc] initWithFrame:CGRectZero];
            slot.hitButton.tag = (NSInteger)i;
            [slot.hitButton addTarget:self action:@selector(handleSlotTapped:)
                     forControlEvents:UIControlEventTouchUpInside];
            [self.slotViews addObject:slot];
        }
    }

    for (NSUInteger i = 0; i < items.count; i++) {
        UITabBarItem *item = items[i];
        NGDockItemSlotView *slot = self.slotViews[i];
        UIImage *normal = item.image ? [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil;
        UIImage *selected = item.selectedImage ? [item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : normal;
        slot.normalImage = normal;
        slot.selectedImage = selected;
        slot.titleLabel.text = item.title ?: @"";
        slot.hitButton.accessibilityLabel = item.title.length ? item.title : [NSString stringWithFormat:@"标签 %lu", (unsigned long)(i + 1)];
    }
}

- (void)refreshBadgeStatesOnly {
    NSArray<UITabBarItem *> *items = [self activeTabItems];
    NSArray<UIView *> *nativeButtons = self.nativeButtonsSnapshot;
    for (NSUInteger i = 0; i < self.slotViews.count && i < items.count; i++) {
        UIView *nativeBtn = (i < nativeButtons.count) ? nativeButtons[i] : nil;
        NGBadgeState *state = [NGBadgeSync resolveBadgeForItem:items[i] nativeButton:nativeBtn];
        [self.slotViews[i] applyBadgeState:state];
    }
}

- (void)handleSlotTapped:(UIButton *)sender {
    NSUInteger index = (NSUInteger)MAX(0, sender.tag);
    NSArray<UITabBarItem *> *items = [self activeTabItems];
    if (index >= items.count || index >= self.slotViews.count) return;

    [self.slotViews[index] onTouchRelease];

    if (NGPreferences.shared.hapticEnabled) {
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen prepare];
        [gen impactOccurred];
    }

    if (!self.controller) {
        self.previewSelectedIndex = index;
        [self refreshAppearanceAndSelectionAnimated:YES];
        return;
    }

    UITabBarController *tbc = self.controller;
    NSArray<UIViewController *> *vcs = tbc.viewControllers;
    if (index >= vcs.count) return;
    UIViewController *targetVC = vcs[index];
    BOOL wasAlreadySelected = (tbc.selectedIndex == index);

    id<UITabBarControllerDelegate> delegate = tbc.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        if (![delegate tabBarController:tbc shouldSelectViewController:targetVC]) {
            return;
        }
    }

    BOOL forwardedToNativeControl = NO;
    if (wasAlreadySelected && index < self.nativeButtonsSnapshot.count) {
        UIView *nativeView = self.nativeButtonsSnapshot[index];
        if ([nativeView isKindOfClass:UIControl.class]) {
            [(UIControl *)nativeView sendActionsForControlEvents:UIControlEventTouchUpInside];
            forwardedToNativeControl = YES;
        }
    } else {
        tbc.selectedIndex = index;
    }

    if (!forwardedToNativeControl &&
        [delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [delegate tabBarController:tbc didSelectViewController:targetVC];
    }

    [self refreshAppearanceAndSelectionAnimated:YES];
}

- (void)refreshAppearanceAndSelectionAnimated:(BOOL)animated {
    [self rebuildGlassSurfacesIfNeeded];
    NGPreferences *prefs = NGPreferences.shared;
    UIColor *accent = NGColorFromHexString(prefs.accentHex, nil);
    BOOL hideTitles = prefs.hideTabTitles;
    NSUInteger selected = [self activeSelectedIndex];

    self.capsuleSelectionLens.backgroundColor = [accent colorWithAlphaComponent:0.17];
    self.orbSelectionLens.backgroundColor = [accent colorWithAlphaComponent:0.20];

    for (NSUInteger i = 0; i < self.slotViews.count; i++) {
        NGDockItemSlotView *slot = self.slotViews[i];
        BOOL isSel = (i == selected);
        slot.itemSelected = isSel;
        slot.hideTitle = hideTitles;
        slot.iconView.image = isSel ? (slot.selectedImage ?: slot.normalImage) : slot.normalImage;
        slot.iconView.tintColor = isSel ? accent : UIColor.secondaryLabelColor;
        slot.titleLabel.textColor = isSel ? accent : UIColor.secondaryLabelColor;
        slot.hitButton.accessibilityTraits = isSel
            ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected)
            : UIAccessibilityTraitButton;
        [slot setNeedsLayout];
    }

    [self setNeedsLayout];
    if (animated && self.window && !UIAccessibilityIsReduceMotionEnabled()) {
        [UIView animateWithDuration:0.34
                              delay:0.0
             usingSpringWithDamping:0.75
              initialSpringVelocity:0.35
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            [self layoutIfNeeded];
        } completion:nil];
    } else {
        [self layoutIfNeeded];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSUInteger count = self.slotViews.count;
    if (count == 0) return;

    NGPreferences *prefs = NGPreferences.shared;
    NGDockLayoutMetrics m = NGComputeDockLayoutC((double)CGRectGetWidth(self.bounds),
                                                 (double)prefs.horizontalInset,
                                                 (double)prefs.dockHeight,
                                                 (unsigned long)count,
                                                 prefs.detachedRightButton ? true : false);

    CGFloat topY = (CGRectGetHeight(self.bounds) - (CGFloat)m.height) * 0.5;
    CGRect capFrame = CGRectMake((CGFloat)m.capsuleX, topY, (CGFloat)m.capsuleWidth, (CGFloat)m.height);
    self.capsuleContainer.frame = capFrame;
    CGFloat capRadius = (CGFloat)m.height * 0.5;
    NGApplyCapsuleCorners(self.capsuleContainer, capRadius);
    if (self.capsuleGlassView) {
        self.capsuleGlassView.frame = self.capsuleContainer.bounds;
        NGApplyCapsuleCorners(self.capsuleGlassView, capRadius);
    }

    if (m.hasDetachedOrb) {
        self.orbContainer.hidden = NO;
        CGRect orbFrame = CGRectMake((CGFloat)m.orbX, topY, (CGFloat)m.orbWidth, (CGFloat)m.height);
        self.orbContainer.frame = orbFrame;
        NGApplyCapsuleCorners(self.orbContainer, capRadius);
        if (self.orbGlassView) {
            self.orbGlassView.frame = self.orbContainer.bounds;
            NGApplyCapsuleCorners(self.orbGlassView, capRadius);
        }
    } else {
        self.orbContainer.hidden = YES;
    }

    NSUInteger capsuleCount = (NSUInteger)m.capsuleItemCount;
    CGRect innerCap = CGRectInset(self.capsuleContainer.bounds, 5.0, 4.0);
    CGFloat slotW = capsuleCount > 0 ? (CGRectGetWidth(innerCap) / (CGFloat)capsuleCount) : 0.0;

    for (NSUInteger i = 0; i < count; i++) {
        NGDockItemSlotView *slot = self.slotViews[i];
        if (m.hasDetachedOrb && i == count - 1) {
            if (slot.superview != self.orbContainer) {
                [self.orbContainer addSubview:slot];
            }
            slot.frame = self.orbContainer.bounds;
        } else {
            if (slot.superview != self.capsuleContainer) {
                [self.capsuleContainer addSubview:slot];
            }
            slot.frame = CGRectMake(CGRectGetMinX(innerCap) + (CGFloat)i * slotW,
                                    CGRectGetMinY(innerCap),
                                    slotW,
                                    CGRectGetHeight(innerCap));
        }
    }

    NSUInteger selected = [self activeSelectedIndex];
    if (m.hasDetachedOrb && selected == count - 1) {
        self.capsuleSelectionLens.alpha = 0.0;
        CGRect orbLens = CGRectInset(self.orbContainer.bounds, 4.0, 4.0);
        self.orbSelectionLens.frame = orbLens;
        self.orbSelectionLens.layer.cornerRadius = MIN(CGRectGetWidth(orbLens), CGRectGetHeight(orbLens)) * 0.5;
        self.orbSelectionLens.alpha = 1.0;
    } else if (capsuleCount > 0) {
        self.orbSelectionLens.alpha = 0.0;
        NSUInteger clampedSel = MIN(selected, capsuleCount - 1);
        CGRect lensRect = CGRectMake(CGRectGetMinX(innerCap) + (CGFloat)clampedSel * slotW + 2.0,
                                     CGRectGetMinY(innerCap),
                                     MAX(0.0, slotW - 4.0),
                                     CGRectGetHeight(innerCap));
        self.capsuleSelectionLens.frame = lensRect;
        self.capsuleSelectionLens.layer.cornerRadius = CGRectGetHeight(lensRect) * 0.5;
        self.capsuleSelectionLens.alpha = 1.0;
    }
}

@end
