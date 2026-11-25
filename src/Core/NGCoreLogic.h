#ifndef NG_CORE_LOGIC_H
#define NG_CORE_LOGIC_H

#include <ctype.h>
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>

static inline bool NGHasAppexSuffixC(const char *path) {
    if (!path) return false;
    size_t len = strlen(path);
    while (len > 0 && (path[len - 1] == '/' || path[len - 1] == '\\')) {
        len--;
    }
    if (len < 6) return false;
    const char *tail = path + (len - 6);
    if (tail[0] != '.') return false;
    const char expected[5] = {'a', 'p', 'p', 'e', 'x'};
    for (size_t i = 0; i < 5; i++) {
        if (tolower((unsigned char)tail[1 + i]) != expected[i]) {
            return false;
        }
    }
    return true;
}

static inline bool NGIsEligibleWeChatBundleC(const char *bundleID, const char *bundlePath) {
    if (!bundleID || strcmp(bundleID, "com.tencent.xin") != 0) {
        return false;
    }
    if (NGHasAppexSuffixC(bundlePath)) {
        return false;
    }
    return true;
}

static inline bool NGShouldWriteSolariumKeyC(bool enabled, int dockMode, long iosMajorVersion) {
    if (iosMajorVersion < 26) {
        return false;
    }
    return enabled && (dockMode == 1);
}

static inline int NGSanitizeDockModeC(long rawMode) {
    if (rawMode == 2) {
        return 2;
    }
    return 1;
}

static inline double NGClampHorizontalInsetC(double value) {
    if (isnan(value) || isinf(value)) {
        return 16.0;
    }
    if (value < 8.0) return 8.0;
    if (value > 28.0) return 28.0;
    return value;
}

static inline double NGClampDockHeightC(double value) {
    if (isnan(value) || isinf(value)) {
        return 52.0;
    }
    if (value < 44.0) return 44.0;
    if (value > 58.0) return 58.0;
    return value;
}

static inline int NGHexNibbleC(char ch) {
    if (ch >= '0' && ch <= '9') return ch - '0';
    if (ch >= 'a' && ch <= 'f') return 10 + (ch - 'a');
    if (ch >= 'A' && ch <= 'F') return 10 + (ch - 'A');
    return -1;
}

static inline bool NGParseHexColorRGBC(const char *hex,
                                       unsigned int *outR,
                                       unsigned int *outG,
                                       unsigned int *outB) {
    if (!hex) return false;
    while (*hex == ' ' || *hex == '\t' || *hex == '\r' || *hex == '\n') {
        hex++;
    }
    if (*hex == '#') {
        hex++;
    }
    int nibbles[6];
    for (int i = 0; i < 6; i++) {
        int v = NGHexNibbleC(hex[i]);
        if (v < 0) return false;
        nibbles[i] = v;
    }
    const char *rest = hex + 6;
    while (*rest == ' ' || *rest == '\t' || *rest == '\r' || *rest == '\n') {
        rest++;
    }
    if (*rest != '\0') return false;
    if (outR) *outR = (unsigned int)((nibbles[0] << 4) | nibbles[1]);
    if (outG) *outG = (unsigned int)((nibbles[2] << 4) | nibbles[3]);
    if (outB) *outB = (unsigned int)((nibbles[4] << 4) | nibbles[5]);
    return true;
}

#endif /* NG_CORE_LOGIC_H */
