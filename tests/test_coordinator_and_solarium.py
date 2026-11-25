import os
from pathlib import Path
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


class CoordinatorAndSolariumTest(unittest.TestCase):
    def test_files_exist(self):
        expected = [
            ROOT / "src/Dock/NGSolariumLogic.h",
            ROOT / "src/Dock/NGNativeSolariumStyler.h",
            ROOT / "src/Dock/NGNativeSolariumStyler.m",
            ROOT / "src/Dock/NGDockCoordinator.h",
            ROOT / "src/Dock/NGDockCoordinator.m",
        ]
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing file: {path}")

    def test_native_solarium_backdrop_filter_c_harness(self):
        clang = find_clang()
        harness = r'''
#include <assert.h>
#include <stdio.h>
#include "NGSolariumLogic.h"

int main(void) {
    // Must hide WeChat's legacy tag 102289 blur/backdrop view
    assert(NGShouldHideWeChatTabBarBackdropViewC("UIVisualEffectView", 102289, true, 430.0, 430.0, 87.0) == true);
    // Must hide WeChat's custom full-width non-system blur overlay placed directly inside UITabBar
    assert(NGShouldHideWeChatTabBarBackdropViewC("MMTabBarBlurView", 0, true, 390.0, 390.0, 83.0) == true);

    // Must NEVER hide UIKit's native _UIBarBackground or iOS 26 Solarium / Glass / Portal / Lens layers!
    assert(NGShouldHideWeChatTabBarBackdropViewC("_UIBarBackground", 0, false, 390.0, 390.0, 83.0) == false);
    assert(NGShouldHideWeChatTabBarBackdropViewC("_UIGlassPortalView", 0, false, 390.0, 390.0, 83.0) == false);
    assert(NGShouldHideWeChatTabBarBackdropViewC("_UISolariumLensView", 0, true, 390.0, 390.0, 83.0) == false);
    assert(NGShouldHideWeChatTabBarBackdropViewC("UITabBarButton", 0, false, 90.0, 390.0, 49.0) == false);
    assert(NGShouldHideWeChatTabBarBackdropViewC("NGCapsuleDockView", 0, false, 358.0, 390.0, 52.0) == false);
    // Must NOT hide small non-full-width subviews
    assert(NGShouldHideWeChatTabBarBackdropViewC("UIVisualEffectView", 0, true, 48.0, 390.0, 48.0) == false);

    printf("solarium_filter_ok\n");
    return 0;
}
'''
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            src_c = tmp_dir / "harness.c"
            exe = tmp_dir / ("harness.exe" if os.name == "nt" else "harness")
            src_c.write_text(harness, encoding="utf-8")
            subprocess.run(
                [clang, "-std=c11", "-Wall", "-Wextra", "-Werror", f"-I{ROOT / 'src/Dock'}", str(src_c), "-o", str(exe)],
                check=True,
                capture_output=True,
                text=True,
            )
            res = subprocess.run([str(exe)], check=True, capture_output=True, text=True)
            self.assertIn("solarium_filter_ok", res.stdout)

    def test_stale_tab_button_snapshot_check_and_full_restore(self):
        coord_m = (ROOT / "src/Dock/NGDockCoordinator.m").read_text(encoding="utf-8")
        # Review Focus #3: verify stale UITabBarButton detection on UIKit rebuilds
        self.assertIn("UITabBarButton", coord_m)
        self.assertIn("areHiddenSnapshotsCurrentForTabBar:", coord_m)
        self.assertIn("restoreTabBarToNativeState:", coord_m)
        self.assertIn("MMTabBarController", coord_m)

        solarium_m = (ROOT / "src/Dock/NGNativeSolariumStyler.m").read_text(encoding="utf-8")
        # Ensure no global addSubview or global UITabBarItem swizzling exists
        self.assertNotIn("method_setImplementation", solarium_m)
        self.assertNotIn("method_exchangeImplementations", solarium_m)
        self.assertIn("restoreTabBar:", solarium_m)

    def test_objc_arm64_ios_syntax_and_type_check(self):
        clang = find_clang()
        shims = ROOT / "tests/sdk_shims"
        for name in ["NGNativeSolariumStyler.m", "NGDockCoordinator.m"]:
            target = ROOT / "src/Dock" / name
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
                    f"-I{ROOT / 'src/Dock'}",
                    str(target),
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, f"Clang failed on {name}:\n{proc.stderr}")


if __name__ == "__main__":
    unittest.main()
