import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def find_clang() -> str:
    candidates = [
        os.environ.get("NG_CLANG", ""),
        r"C:\Program Files\LLVM\bin\clang.exe",
        shutil.which("clang") or "",
    ]
    for c in candidates:
        if c and Path(c).is_file():
            return c
    raise RuntimeError("LLVM clang executable not found")


class CoreContractsTest(unittest.TestCase):
    def test_core_files_exist(self):
        expected = [
            ROOT / "VERSION",
            ROOT / "src/Core/NGCoreLogic.h",
            ROOT / "src/Core/NGEnvironment.h",
            ROOT / "src/Core/NGEnvironment.m",
            ROOT / "src/Core/NGPreferences.h",
            ROOT / "src/Core/NGPreferences.m",
            ROOT / "src/Core/NGRuntimeBridge.h",
            ROOT / "src/Core/NGRuntimeBridge.m",
        ]
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing file: {path}")

    def test_native_core_c_logic_harness(self):
        clang = find_clang()
        harness = r'''
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "NGCoreLogic.h"

int main(void) {
    // 1. Exact com.tencent.xin match & .appex exclusion (Review Focus #1)
    assert(NGIsEligibleWeChatBundleC("com.tencent.xin", "/var/containers/Bundle/Application/A/WeChat.app") == true);
    assert(NGIsEligibleWeChatBundleC("com.tencent.xin2", "/var/containers/Bundle/Application/A/WeChat.app") == false);
    assert(NGIsEligibleWeChatBundleC("com.other.app", "/var/containers/Bundle/Application/A/WeChat.app") == false);
    assert(NGIsEligibleWeChatBundleC("com.tencent.xin", "/var/containers/Bundle/Application/A/WeChat.app/PlugIns/Share.appex") == false);
    assert(NGIsEligibleWeChatBundleC("com.tencent.xin", "/var/containers/Bundle/Application/A/Share.APPEX/") == false);
    assert(NGIsEligibleWeChatBundleC(NULL, "/WeChat.app") == false);
    assert(NGIsEligibleWeChatBundleC("", "/WeChat.app") == false);

    // 2. Solarium key strict sync/cleanup (Review Focus #2)
    assert(NGShouldWriteSolariumKeyC(true, 1, 26) == true);
    assert(NGShouldWriteSolariumKeyC(true, 1, 27) == true);
    assert(NGShouldWriteSolariumKeyC(true, 2, 26) == false);
    assert(NGShouldWriteSolariumKeyC(false, 1, 26) == false);
    assert(NGShouldWriteSolariumKeyC(true, 0, 26) == false);
    assert(NGShouldWriteSolariumKeyC(true, 1, 18) == false);

    // 3. Clamping and malformed input protection (Review Focus #5)
    assert(fabs(NGClampHorizontalInsetC(-20.0) - 8.0) < 1e-6);
    assert(fabs(NGClampHorizontalInsetC(500.0) - 28.0) < 1e-6);
    assert(fabs(NGClampHorizontalInsetC(18.5) - 18.5) < 1e-6);
    assert(fabs(NGClampHorizontalInsetC(NAN) - 16.0) < 1e-6);

    assert(fabs(NGClampDockHeightC(12.0) - 44.0) < 1e-6);
    assert(fabs(NGClampDockHeightC(120.0) - 58.0) < 1e-6);
    assert(fabs(NGClampDockHeightC(50.0) - 50.0) < 1e-6);
    assert(fabs(NGClampDockHeightC(NAN) - 52.0) < 1e-6);

    assert(NGSanitizeDockModeC(1) == 1);
    assert(NGSanitizeDockModeC(2) == 2);
    assert(NGSanitizeDockModeC(0) == 1);
    assert(NGSanitizeDockModeC(99) == 1);
    assert(NGSanitizeDockModeC(-3) == 1);

    unsigned int r = 0, g = 0, b = 0;
    assert(NGParseHexColorRGBC("#07C160", &r, &g, &b) == true && r == 7 && g == 193 && b == 96);
    assert(NGParseHexColorRGBC("0a84ff", &r, &g, &b) == true && r == 10 && g == 132 && b == 255);
    assert(NGParseHexColorRGBC("#GGGGGG", &r, &g, &b) == false);
    assert(NGParseHexColorRGBC("#123", &r, &g, &b) == false);
    assert(NGParseHexColorRGBC(NULL, &r, &g, &b) == false);

    printf("core_c_logic_ok\n");
    return 0;
}
'''
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            src_c = tmp_dir / "harness.c"
            exe = tmp_dir / ("harness.exe" if os.name == "nt" else "harness")
            src_c.write_text(harness, encoding="utf-8")
            subprocess.run(
                [clang, "-std=c11", "-Wall", "-Wextra", "-Werror", f"-I{ROOT / 'src/Core'}", str(src_c), "-o", str(exe)],
                check=True,
                capture_output=True,
                text=True,
            )
            res = subprocess.run([str(exe)], check=True, capture_output=True, text=True)
            self.assertIn("core_c_logic_ok", res.stdout)

    def test_preference_keys_isolated_and_solarium_cleaned(self):
        prefs_m = (ROOT / "src/Core/NGPreferences.m").read_text(encoding="utf-8")
        keys = re.findall(r'@"((?:com\.solhk\.naloiaglass|xg_|wclg_)[^"]*)"', prefs_m)
        self.assertTrue(keys, "Expected preference keys in NGPreferences.m")
        for key in keys:
            self.assertTrue(key.startswith("com.solhk.naloiaglass."), f"Non-isolated preference key: {key}")
        self.assertIn("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck", prefs_m)
        self.assertIn("removeObjectForKey:", prefs_m)
        self.assertIn("CFPreferencesSetAppValue", prefs_m)

    def test_objc_arm64_ios_syntax_and_type_check(self):
        clang = find_clang()
        shims = ROOT / "tests/sdk_shims"
        for name in ["NGEnvironment.m", "NGPreferences.m", "NGRuntimeBridge.m"]:
            target = ROOT / "src/Core" / name
            proc = subprocess.run(
                [
                    clang,
                    "-target",
                    "arm64-apple-ios16.0",
                    "-fsyntax-only",
                    "-fobjc-arc",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-isystem",
                    str(shims),
                    f"-I{ROOT / 'src/Core'}",
                    str(target),
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, f"Clang failed on {name}:\n{proc.stderr}")


if __name__ == "__main__":
    unittest.main()
