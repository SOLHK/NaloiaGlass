#pragma once
#include <math.h>
#include <stdbool.h>

typedef double CGFloat;
typedef struct CGColor *CGColorRef;

typedef struct CGPoint { CGFloat x; CGFloat y; } CGPoint;
typedef struct CGSize { CGFloat width; CGFloat height; } CGSize;
typedef struct CGRect { CGPoint origin; CGSize size; } CGRect;
typedef struct CGAffineTransform {
    CGFloat a, b, c, d;
    CGFloat tx, ty;
} CGAffineTransform;

extern const CGPoint CGPointZero;
extern const CGSize CGSizeZero;
extern const CGRect CGRectZero;
extern const CGAffineTransform CGAffineTransformIdentity;

static inline CGPoint CGPointMake(CGFloat x, CGFloat y) { CGPoint p = {x, y}; return p; }
static inline CGSize CGSizeMake(CGFloat w, CGFloat h) { CGSize s = {w, h}; return s; }
static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat w, CGFloat h) { CGRect r = {{x, y}, {w, h}}; return r; }
static inline CGRect CGRectInset(CGRect rect, CGFloat dx, CGFloat dy) {
    return CGRectMake(rect.origin.x + dx, rect.origin.y + dy, rect.size.width - 2.0 * dx, rect.size.height - 2.0 * dy);
}
static inline CGFloat CGRectGetWidth(CGRect r) { return fabs(r.size.width); }
static inline CGFloat CGRectGetHeight(CGRect r) { return fabs(r.size.height); }
static inline CGFloat CGRectGetMinX(CGRect r) { return r.origin.x; }
static inline CGFloat CGRectGetMinY(CGRect r) { return r.origin.y; }
static inline CGFloat CGRectGetMidX(CGRect r) { return r.origin.x + r.size.width * 0.5; }
static inline CGFloat CGRectGetMidY(CGRect r) { return r.origin.y + r.size.height * 0.5; }
static inline CGFloat CGRectGetMaxX(CGRect r) { return r.origin.x + r.size.width; }
static inline CGFloat CGRectGetMaxY(CGRect r) { return r.origin.y + r.size.height; }
static inline bool CGRectIsEmpty(CGRect r) { return r.size.width <= 0.0 || r.size.height <= 0.0; }
static inline bool CGRectEqualToRect(CGRect a, CGRect b) {
    return a.origin.x == b.origin.x && a.origin.y == b.origin.y && a.size.width == b.size.width && a.size.height == b.size.height;
}
static inline bool CGSizeEqualToSize(CGSize a, CGSize b) { return a.width == b.width && a.height == b.height; }
static inline bool CGRectContainsPoint(CGRect r, CGPoint p) {
    return p.x >= r.origin.x && p.x <= r.origin.x + r.size.width && p.y >= r.origin.y && p.y <= r.origin.y + r.size.height;
}
static inline CGAffineTransform CGAffineTransformMakeScale(CGFloat sx, CGFloat sy) {
    CGAffineTransform t = {sx, 0, 0, sy, 0, 0};
    return t;
}
