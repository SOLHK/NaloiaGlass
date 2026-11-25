#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NGCapsuleDockView : UIView

@property (nonatomic, weak, nullable) UITabBarController *controller;
@property (nonatomic, copy, nullable) NSArray<UIView *> *nativeButtonsSnapshot;

- (void)reloadFromController;
- (void)refreshBadgeStatesOnly;
- (void)refreshAppearanceAndSelectionAnimated:(BOOL)animated;
- (void)configureForPreviewItems:(NSArray<UITabBarItem *> *)items
                   selectedIndex:(NSUInteger)selectedIndex;

@end

NS_ASSUME_NONNULL_END
