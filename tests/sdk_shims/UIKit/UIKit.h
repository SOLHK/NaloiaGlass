#pragma once
#include <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <QuartzCore/QuartzCore.h>

typedef struct UIEdgeInsets { CGFloat top, left, bottom, right; } UIEdgeInsets;
static inline UIEdgeInsets UIEdgeInsetsMake(CGFloat t, CGFloat l, CGFloat b, CGFloat r) {
    UIEdgeInsets e = {t, l, b, r};
    return e;
}
extern const UIEdgeInsets UIEdgeInsetsZero;

typedef NS_ENUM(NSInteger, UIUserInterfaceStyle) {
    UIUserInterfaceStyleUnspecified = 0,
    UIUserInterfaceStyleLight = 1,
    UIUserInterfaceStyleDark = 2
};

typedef NS_OPTIONS(NSUInteger, UIViewAutoresizing) {
    UIViewAutoresizingNone = 0,
    UIViewAutoresizingFlexibleLeftMargin = 1 << 0,
    UIViewAutoresizingFlexibleWidth = 1 << 1,
    UIViewAutoresizingFlexibleRightMargin = 1 << 2,
    UIViewAutoresizingFlexibleTopMargin = 1 << 3,
    UIViewAutoresizingFlexibleHeight = 1 << 4,
    UIViewAutoresizingFlexibleBottomMargin = 1 << 5
};

typedef NS_OPTIONS(NSUInteger, UIViewAnimationOptions) {
    UIViewAnimationOptionAllowUserInteraction = 1 << 1,
    UIViewAnimationOptionBeginFromCurrentState = 1 << 2,
    UIViewAnimationOptionCurveEaseOut = 2 << 16
};

typedef NS_OPTIONS(NSUInteger, UIControlEvents) {
    UIControlEventTouchDown = 1 << 0,
    UIControlEventTouchDragEnter = 1 << 4,
    UIControlEventTouchDragExit = 1 << 5,
    UIControlEventTouchUpInside = 1 << 6,
    UIControlEventTouchUpOutside = 1 << 7,
    UIControlEventTouchCancel = 1 << 8,
    UIControlEventValueChanged = 1 << 12
};

typedef NS_OPTIONS(NSUInteger, UIControlState) {
    UIControlStateNormal = 0,
    UIControlStateHighlighted = 1 << 0,
    UIControlStateDisabled = 1 << 1,
    UIControlStateSelected = 1 << 2
};

typedef NS_ENUM(NSInteger, UIButtonType) {
    UIButtonTypeCustom = 0,
    UIButtonTypeSystem = 1
};

typedef NS_ENUM(NSInteger, UIViewContentMode) {
    UIViewContentModeScaleToFill = 0,
    UIViewContentModeScaleAspectFit = 1,
    UIViewContentModeCenter = 4
};

typedef NS_ENUM(NSInteger, NSTextAlignment) {
    NSTextAlignmentLeft = 0,
    NSTextAlignmentCenter = 1,
    NSTextAlignmentRight = 2
};

typedef NS_ENUM(NSInteger, UIGestureRecognizerState) {
    UIGestureRecognizerStatePossible = 0,
    UIGestureRecognizerStateBegan = 1,
    UIGestureRecognizerStateChanged = 2,
    UIGestureRecognizerStateEnded = 3,
    UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded
};

typedef NS_ENUM(NSInteger, UITableViewStyle) {
    UITableViewStylePlain = 0,
    UITableViewStyleGrouped = 1,
    UITableViewStyleInsetGrouped = 2
};

typedef NS_ENUM(NSInteger, UITableViewCellStyle) {
    UITableViewCellStyleDefault = 0,
    UITableViewCellStyleValue1 = 1,
    UITableViewCellStyleSubtitle = 3
};

typedef NS_ENUM(NSInteger, UITableViewCellAccessoryType) {
    UITableViewCellAccessoryNone = 0,
    UITableViewCellAccessoryDisclosureIndicator = 1,
    UITableViewCellAccessoryCheckmark = 3
};

typedef NS_ENUM(NSInteger, UITableViewCellSelectionStyle) {
    UITableViewCellSelectionStyleNone = 0,
    UITableViewCellSelectionStyleDefault = 3
};

typedef NS_ENUM(NSInteger, UIAlertControllerStyle) {
    UIAlertControllerStyleActionSheet = 0,
    UIAlertControllerStyleAlert = 1
};

typedef NS_ENUM(NSInteger, UIAlertActionStyle) {
    UIAlertActionStyleDefault = 0,
    UIAlertActionStyleCancel = 1,
    UIAlertActionStyleDestructive = 2
};

typedef NS_ENUM(NSInteger, UIModalPresentationStyle) {
    UIModalPresentationPageSheet = 1
};

typedef NS_ENUM(NSInteger, UIImpactFeedbackStyle) {
    UIImpactFeedbackStyleLight = 0,
    UIImpactFeedbackStyleMedium = 1
};

typedef NS_ENUM(NSInteger, UIBarButtonSystemItem) {
    UIBarButtonSystemItemDone = 0
};

typedef NS_ENUM(NSInteger, UIImageRenderingMode) {
    UIImageRenderingModeAutomatic = 0,
    UIImageRenderingModeAlwaysOriginal = 1,
    UIImageRenderingModeAlwaysTemplate = 2
};

typedef uint64_t UIAccessibilityTraits;
extern UIAccessibilityTraits UIAccessibilityTraitNone;
extern UIAccessibilityTraits UIAccessibilityTraitButton;
extern UIAccessibilityTraits UIAccessibilityTraitSelected;

typedef CGFloat UIFontWeight;
extern const UIFontWeight UIFontWeightRegular;
extern const UIFontWeight UIFontWeightMedium;
extern const UIFontWeight UIFontWeightSemibold;
extern const UIFontWeight UIFontWeightBold;

BOOL UIAccessibilityIsReduceTransparencyEnabled(void);
BOOL UIAccessibilityIsReduceMotionEnabled(void);

@interface UITraitCollection : NSObject
@property (class, nonatomic, readonly) UITraitCollection *currentTraitCollection;
@property (nonatomic, readonly) UIUserInterfaceStyle userInterfaceStyle;
@end

@interface UIColor : NSObject <NSCopying>
@property (class, nonatomic, readonly) UIColor *clearColor;
@property (class, nonatomic, readonly) UIColor *whiteColor;
@property (class, nonatomic, readonly) UIColor *blackColor;
@property (class, nonatomic, readonly) UIColor *labelColor;
@property (class, nonatomic, readonly) UIColor *secondaryLabelColor;
@property (class, nonatomic, readonly) UIColor *tertiaryLabelColor;
@property (class, nonatomic, readonly) UIColor *separatorColor;
@property (class, nonatomic, readonly) UIColor *systemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *secondarySystemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *systemGroupedBackgroundColor;
@property (class, nonatomic, readonly) UIColor *secondarySystemGroupedBackgroundColor;
@property (class, nonatomic, readonly) UIColor *systemRedColor;
@property (class, nonatomic, readonly) UIColor *systemGreenColor;
@property (class, nonatomic, readonly) UIColor *systemBlueColor;
@property (class, nonatomic, readonly) UIColor *systemTealColor;
@property (class, nonatomic, readonly) UIColor *systemIndigoColor;
@property (class, nonatomic, readonly) UIColor *systemOrangeColor;
@property (nonatomic, readonly) CGColorRef CGColor;
+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *)colorWithAlphaComponent:(CGFloat)alpha;
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection;
- (BOOL)getRed:(nullable CGFloat *)red green:(nullable CGFloat *)green blue:(nullable CGFloat *)blue alpha:(nullable CGFloat *)alpha;
@end

@interface UIFont : NSObject <NSCopying>
+ (UIFont *)systemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)systemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight;
+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)monospacedDigitSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight;
@end

typedef NS_ENUM(NSInteger, UIImageSymbolWeight) {
    UIImageSymbolWeightRegular = 4,
    UIImageSymbolWeightMedium = 5,
    UIImageSymbolWeightSemibold = 6,
    UIImageSymbolWeightBold = 7
};

@interface UIImageSymbolConfiguration : NSObject
+ (instancetype)configurationWithPointSize:(CGFloat)pointSize weight:(UIImageSymbolWeight)weight;
@end

@interface UIImage : NSObject <NSCopying>
@property (nonatomic, readonly) CGSize size;
+ (nullable UIImage *)systemImageNamed:(NSString *)name;
+ (nullable UIImage *)systemImageNamed:(NSString *)name withConfiguration:(nullable UIImageSymbolConfiguration *)configuration;
- (UIImage *)imageWithRenderingMode:(UIImageRenderingMode)renderingMode;
@end

@class UIWindow, UIGestureRecognizer;

@interface UIView : NSObject
@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGFloat alpha;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isOpaque) BOOL opaque;
@property (nonatomic) BOOL clipsToBounds;
@property (nonatomic, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property (nonatomic) NSInteger tag;
@property (nonatomic) UIViewAutoresizing autoresizingMask;
@property (nonatomic) UIUserInterfaceStyle overrideUserInterfaceStyle;
@property (nullable, nonatomic, copy) UIColor *backgroundColor;
@property (nullable, nonatomic, copy) UIColor *tintColor;
@property (nonatomic, readonly, strong) CALayer *layer;
@property (nullable, nonatomic, readonly) UIView *superview;
@property (nonatomic, readonly, copy) NSArray<__kindof UIView *> *subviews;
@property (nullable, nonatomic, readonly) UIWindow *window;
@property (nullable, nonatomic, copy) NSString *accessibilityIdentifier;
@property (nullable, nonatomic, copy) NSString *accessibilityLabel;
@property (nullable, nonatomic, copy) NSString *accessibilityValue;
@property (nonatomic) UIAccessibilityTraits accessibilityTraits;
@property (nonatomic) BOOL isAccessibilityElement;
@property (nonatomic) BOOL accessibilityElementsHidden;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)addSubview:(UIView *)view;
- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index;
- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview;
- (void)bringSubviewToFront:(UIView *)view;
- (void)removeFromSuperview;
- (nullable __kindof UIView *)viewWithTag:(NSInteger)tag;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;
- (void)layoutSubviews;
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable id)event;
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable id)event;
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^ _Nullable)(BOOL finished))completion;
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^ _Nullable)(BOOL finished))completion;
@end

@interface UIVisualEffect : NSObject <NSCopying>
@end

@interface UIBlurEffect : UIVisualEffect
@end

@interface UIVisualEffectView : UIView
@property (nonatomic, readonly, strong) UIView *contentView;
@property (nullable, nonatomic, copy) UIVisualEffect *effect;
- (instancetype)initWithEffect:(nullable UIVisualEffect *)effect;
@end

@interface UILabel : UIView
@property (nullable, nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic) NSTextAlignment textAlignment;
@property (nonatomic) NSInteger numberOfLines;
- (CGSize)sizeThatFits:(CGSize)size;
@end

@interface UIImageView : UIView
@property (nullable, nonatomic, strong) UIImage *image;
@property (nonatomic) UIViewContentMode contentMode;
@end

@interface UIControl : UIView
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)removeTarget:(nullable id)target action:(nullable SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents;
@end

@interface UIButton : UIControl
@property (nullable, nonatomic, readonly, strong) UILabel *titleLabel;
@property (nullable, nonatomic, readonly, strong) UIImageView *imageView;
+ (instancetype)buttonWithType:(UIButtonType)buttonType;
- (void)setTitle:(nullable NSString *)title forState:(UIControlState)state;
- (void)setTitleColor:(nullable UIColor *)color forState:(UIControlState)state;
- (void)setImage:(nullable UIImage *)image forState:(UIControlState)state;
@end

@interface UISwitch : UIControl
@property (nonatomic, getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@interface UISlider : UIControl
@property (nonatomic) float value;
@property (nonatomic) float minimumValue;
@property (nonatomic) float maximumValue;
- (void)setValue:(float)value animated:(BOOL)animated;
@end

@interface UITextField : UIControl
@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSString *placeholder;
@end

@interface UIBarItem : NSObject
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, strong) UIImage *image;
@property (nonatomic) UIEdgeInsets imageInsets;
@property (nonatomic) NSInteger tag;
@end

@interface UITabBarItem : UIBarItem
@property (nullable, nonatomic, strong) UIImage *selectedImage;
@property (nullable, nonatomic, copy) NSString *badgeValue;
- (instancetype)initWithTitle:(nullable NSString *)title image:(nullable UIImage *)image tag:(NSInteger)tag;
@end

@interface UIBarAppearance : NSObject <NSCopying>
- (void)configureWithTransparentBackground;
@end

@interface UITabBarAppearance : UIBarAppearance
@end

@interface UITabBar : UIView
@property (nullable, nonatomic, copy) NSArray<UITabBarItem *> *items;
@property (nullable, nonatomic, weak) UITabBarItem *selectedItem;
@property (nonatomic, copy) UITabBarAppearance *standardAppearance;
@property (nullable, nonatomic, copy) UITabBarAppearance *scrollEdgeAppearance;
@property (nonatomic) UIEdgeInsets safeAreaInsets;
@end

@class UINavigationController, UITabBarController;

@interface UIBarButtonItem : UIBarItem
- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(nullable id)target action:(nullable SEL)action;
- (instancetype)initWithTitle:(nullable NSString *)title style:(NSInteger)style target:(nullable id)target action:(nullable SEL)action;
@end

@interface UINavigationItem : NSObject
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, strong) UIBarButtonItem *leftBarButtonItem;
@property (nullable, nonatomic, strong) UIBarButtonItem *rightBarButtonItem;
@end

@interface UIViewController : NSObject
@property (null_resettable, nonatomic, strong) UIView *view;
@property (nonatomic, readonly, getter=isViewLoaded) BOOL viewLoaded;
@property (nullable, nonatomic, copy) NSString *title;
@property (nonatomic, readonly, strong) UINavigationItem *navigationItem;
@property (nullable, nonatomic, readonly, strong) UINavigationController *navigationController;
@property (nullable, nonatomic, readonly) UIViewController *presentedViewController;
@property (nonatomic, readonly, getter=isBeingDismissed) BOOL beingDismissed;
@property (nonatomic) UIModalPresentationStyle modalPresentationStyle;
@property (nonatomic, readonly) NSArray<__kindof UIViewController *> *childViewControllers;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewDidLayoutSubviews;
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^ _Nullable)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^ _Nullable)(void))completion;
@end

@interface UINavigationController : UIViewController
@property (nullable, nonatomic, readonly, strong) UIViewController *topViewController;
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
@end

@protocol UITabBarControllerDelegate <NSObject>
@optional
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;
@end

@interface UITabBarController : UIViewController
@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController *> *viewControllers;
@property (nullable, nonatomic, assign) __kindof UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic, readonly) UITabBar *tabBar;
@property (nullable, nonatomic, weak) id<UITabBarControllerDelegate> delegate;
@end

@interface UITableViewCell : UIView
@property (nonatomic, readonly, strong) UIView *contentView;
@property (nullable, nonatomic, readonly, strong) UILabel *textLabel;
@property (nullable, nonatomic, readonly, strong) UILabel *detailTextLabel;
@property (nullable, nonatomic, strong) UIView *accessoryView;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;
@property (nonatomic) UITableViewCellSelectionStyle selectionStyle;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier;
@end

@protocol UITableViewDataSource <NSObject>
- (NSInteger)tableView:(id)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(id)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (NSInteger)numberOfSectionsInTableView:(id)tableView;
- (nullable NSString *)tableView:(id)tableView titleForHeaderInSection:(NSInteger)section;
- (nullable NSString *)tableView:(id)tableView titleForFooterInSection:(NSInteger)section;
@end

@protocol UITableViewDelegate <NSObject>
@optional
- (void)tableView:(id)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(id)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface UITableView : UIView
@property (nullable, nonatomic, weak) id<UITableViewDataSource> dataSource;
@property (nullable, nonatomic, weak) id<UITableViewDelegate> delegate;
@property (nullable, nonatomic, strong) UIView *tableHeaderView;
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style;
- (void)reloadData;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (nullable __kindof UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
@end

@interface UITableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (null_resettable, nonatomic, strong) UITableView *tableView;
- (instancetype)initWithStyle:(UITableViewStyle)style;
@end

@interface UIAlertAction : NSObject
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(UIAlertActionStyle)style handler:(void (^ _Nullable)(UIAlertAction *action))handler;
@end

@interface UIAlertController : UIViewController
@property (nullable, nonatomic, readonly) NSArray<UITextField *> *textFields;
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle;
- (void)addAction:(UIAlertAction *)action;
- (void)addTextFieldWithConfigurationHandler:(void (^ _Nullable)(UITextField *textField))configurationHandler;
@end

@interface UIGestureRecognizer : NSObject
@property (nonatomic, readonly) UIGestureRecognizerState state;
@property (nullable, nonatomic, readonly) UIView *view;
@property (nonatomic) BOOL cancelsTouchesInView;
- (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action;
@end

@interface UITapGestureRecognizer : UIGestureRecognizer
@property (nonatomic) NSUInteger numberOfTapsRequired;
@property (nonatomic) NSUInteger numberOfTouchesRequired;
@end

@interface UILongPressGestureRecognizer : UIGestureRecognizer
@property (nonatomic) NSTimeInterval minimumPressDuration;
@end

@interface UIWindow : UIView
@property (nullable, nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, readonly, getter=isKeyWindow) BOOL keyWindow;
@end

@interface UIScene : NSObject
@end

@interface UIWindowScene : UIScene
@property (nonatomic, readonly) NSArray<UIWindow *> *windows;
@end

@interface UIApplication : NSObject
@property (class, nonatomic, readonly) UIApplication *sharedApplication;
@property (nonatomic, readonly) NSSet<UIScene *> *connectedScenes;
@end

@interface UIPasteboard : NSObject
@property (class, nonatomic, readonly) UIPasteboard *generalPasteboard;
@property (nullable, nonatomic, copy) NSString *string;
@end

@interface UIImpactFeedbackGenerator : NSObject
- (instancetype)initWithStyle:(UIImpactFeedbackStyle)style;
- (void)prepare;
- (void)impactOccurred;
@end
