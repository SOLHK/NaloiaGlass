#ifndef NG_SOLARIUM_LOGIC_H
#define NG_SOLARIUM_LOGIC_H

#include <ctype.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>

static inline bool NGSolariumContainsTokenCI(const char *haystack, const char *needle) {
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

static inline bool NGShouldHideWeChatTabBarBackdropViewC(const char *className,
                                                         long tag,
                                                         bool isVisualEffectView,
                                                         double width,
                                                         double barWidth,
                                                         double height) {
    if (className) {
        // Never touch UIKit native bar background, tab buttons, our own capsule,
        // or iOS 26 Solarium / Liquid Glass internal rendering views.
        if (strcmp(className, "_UIBarBackground") == 0 ||
            strcmp(className, "UITabBarButton") == 0 ||
            strcmp(className, "NGCapsuleDockView") == 0 ||
            NGSolariumContainsTokenCI(className, "Solarium") ||
            NGSolariumContainsTokenCI(className, "Glass") ||
            NGSolariumContainsTokenCI(className, "Portal") ||
            NGSolariumContainsTokenCI(className, "Lens") ||
            NGSolariumContainsTokenCI(className, "Platter")) {
            return false;
        }
    }

    // WeChat's custom TabBar ExtraLight blur overlay identified in B-plan testing.
    if (tag == 102289) {
        return true;
    }

    // Full-width non-system blur view inserted by WeChat over UITabBar.
    if (isVisualEffectView && barWidth > 100.0 && width >= (barWidth - 32.0) && height >= 36.0) {
        return true;
    }

    return false;
}

#endif /* NG_SOLARIUM_LOGIC_H */
