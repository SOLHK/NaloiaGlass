#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NGDockMode) {
    NGDockModeDisabled = 0,
    NGDockModeSystemNative = 1,
    NGDockModeFloatingCapsule = 2
};

FOUNDATION_EXPORT NSNotificationName const NGPreferencesDidChangeNotification;

@interface NGPreferences : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NGDockMode dockMode;
@property (nonatomic, assign) BOOL clearGlass;
@property (nonatomic, assign) BOOL hideTabTitles;
@property (nonatomic, assign) BOOL detachedRightButton;
@property (nonatomic, assign) BOOL hapticEnabled;
@property (nonatomic, assign) CGFloat horizontalInset;
@property (nonatomic, assign) CGFloat dockHeight;
@property (nonatomic, copy) NSString *accentHex;

- (NGDockMode)effectiveDockMode;
- (BOOL)isSolariumPreferenceActiveInSystem;
- (BOOL)syncSolariumPreferenceKey;

- (nullable NSString *)exportJSONString;
- (BOOL)importJSONString:(NSString *)json error:(NSError * _Nullable * _Nullable)error;
- (void)resetToDefaults;

@end

NS_ASSUME_NONNULL_END
