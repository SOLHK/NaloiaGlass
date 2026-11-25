#pragma once
#include <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>

typedef NSString *CALayerCornerCurve;
extern CALayerCornerCurve const kCACornerCurveContinuous;

@interface CALayer : NSObject
@property CGFloat cornerRadius;
@property (copy) CALayerCornerCurve cornerCurve;
@property CGFloat borderWidth;
@property (nullable) CGColorRef borderColor;
@property float shadowOpacity;
@property CGFloat shadowRadius;
@property CGSize shadowOffset;
@property (nullable) CGColorRef shadowColor;
@property BOOL masksToBounds;
@end

@interface CATransaction : NSObject
+ (void)begin;
+ (void)commit;
+ (void)setDisableActions:(BOOL)flag;
@end
