#ifndef NG_BADGE_LOGIC_H
#define NG_BADGE_LOGIC_H

#include <ctype.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>

typedef struct {
    bool hasDetachedOrb;
    unsigned long capsuleItemCount;
    double capsuleX;
    double capsuleWidth;
    double orbSpacing;
    double orbX;
    double orbWidth;
    double height;
} NGDockLayoutMetrics;

static inline bool NGContainsAsciiTokenCaseInsensitiveC(const char *haystack, const char *needle) {
    if (!haystack || !needle || !*needle) return false;
    size_t nlen = strlen(needle);
    for (const char *p = haystack; *p != '\0'; p++) {
        size_t i = 0;
        while (i < nlen && p[i] != '\0' &&
               tolower((unsigned char)p[i]) == tolower((unsigned char)needle[i])) {
            i++;
        }
        if (i == nlen) return true;
    }
    return false;
}

static inline bool NGIsLikelyUnreadIndicatorViewC(const char *className,
                                                  double width,
                                                  double height,
                                                  bool hidden,
                                                  double alpha,
                                                  bool isRedTinted) {
    if (hidden || alpha <= 0.05) {
        return false;
    }
    if (width < 4.0 || width > 28.0 || height < 4.0 || height > 22.0) {
        return false;
    }
    if (className) {
        if (NGContainsAsciiTokenCaseInsensitiveC(className, "SwappableImageView") ||
            NGContainsAsciiTokenCaseInsensitiveC(className, "ButtonLabel")) {
            return false;
        }
        if (NGContainsAsciiTokenCaseInsensitiveC(className, "Badge") ||
            NGContainsAsciiTokenCaseInsensitiveC(className, "RedPoint") ||
            NGContainsAsciiTokenCaseInsensitiveC(className, "Unread") ||
            NGContainsAsciiTokenCaseInsensitiveC(className, "Dot")) {
            return true;
        }
    }
    if (isRedTinted && width <= 16.0 && height <= 16.0) {
        return true;
    }
    return false;
}

static inline NGDockLayoutMetrics NGComputeDockLayoutC(double containerWidth,
                                                       double horizontalInset,
                                                       double dockHeight,
                                                       unsigned long itemCount,
                                                       bool requestDetachedOrb) {
    NGDockLayoutMetrics m;
    m.height = dockHeight > 36.0 ? dockHeight : 36.0;
    m.capsuleX = horizontalInset >= 0.0 ? horizontalInset : 0.0;
    double usableWidth = containerWidth - 2.0 * m.capsuleX;
    if (usableWidth < 0.0) usableWidth = 0.0;

    const double spacing = 10.0;
    double orbSize = m.height;
    bool canDetach = requestDetachedOrb && (itemCount >= 3) && (usableWidth >= (orbSize + spacing + 110.0));

    if (canDetach) {
        m.hasDetachedOrb = true;
        m.capsuleItemCount = itemCount - 1;
        m.orbSpacing = spacing;
        m.orbWidth = orbSize;
        m.capsuleWidth = usableWidth - spacing - orbSize;
        m.orbX = m.capsuleX + m.capsuleWidth + spacing;
    } else {
        m.hasDetachedOrb = false;
        m.capsuleItemCount = itemCount;
        m.orbSpacing = 0.0;
        m.orbWidth = 0.0;
        m.capsuleWidth = usableWidth;
        m.orbX = m.capsuleX + usableWidth;
    }
    return m;
}

#endif /* NG_BADGE_LOGIC_H */
