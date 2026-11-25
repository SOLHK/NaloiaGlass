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


class DockViewsTest(unittest.TestCase):
    def test_dock_view_files_exist(self):
        expected = [
            ROOT / "src/Dock/NGBadgeLogic.h",
            ROOT / "src/Dock/NGBadgeSync.h",
            ROOT / "src/Dock/NGBadgeSync.m",
            ROOT / "src/Dock/NGCapsuleDockView.h",
            ROOT / "src/Dock/NGCapsuleDockView.m",
        ]
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing file: {path}")

    def test_native_badge_and_geometry_c_harness(self):
        clang = find_clang()
        harness = r'''
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "NGBadgeLogic.h"

int main(void) {
    // Review Focus #4: WeChat Moments pure red-dot vs false positives
    assert(NGIsLikelyUnreadIndicatorViewC("MMBadgeView", 10.0, 10.0, false, 1.0, false) == true);
    assert(NGIsLikelyUnreadIndicatorViewC("MMTabBarRedPointView", 8.0, 8.0, false, 1.0, false) == true);
    assert(NGIsLikelyUnreadIndicatorViewC("_UIBadgeView", 18.0, 18.0, false, 1.0, false) == true);
    assert(NGIsLikelyUnreadIndicatorViewC("UIView", 9.0, 9.0, false, 1.0, true) == true);

    // Reject hidden, nearly-transparent, oversized selection plates, and tiny artifacts
    assert(NGIsLikelyUnreadIndicatorViewC("MMBadgeView", 10.0, 10.0, true, 1.0, true) == false);
    assert(NGIsLikelyUnreadIndicatorViewC("MMBadgeView", 10.0, 10.0, false, 0.01, true) == false);
    assert(NGIsLikelyUnreadIndicatorViewC("UIView", 64.0, 48.0, false, 1.0, true) == false);
    assert(NGIsLikelyUnreadIndicatorViewC("UIView", 9.0, 9.0, false, 1.0, false) == false);
    assert(NGIsLikelyUnreadIndicatorViewC("UITabBarSwappableImageView", 24.0, 24.0, false, 1.0, false) == false);
    assert(NGIsLikelyUnreadIndicatorViewC("UITabBarButtonLabel", 20.0, 12.0, false, 1.0, false) == false);

    // Detached right orb layout math: active when detached=true and itemCount >= 3
    NGDockLayoutMetrics m4 = NGComputeDockLayoutC(390.0, 16.0, 52.0, 4, true);
    assert(m4.hasDetachedOrb == true);
    assert(m4.capsuleItemCount == 3);
    assert(fabs(m4.orbWidth - 52.0) < 1e-6);
    assert(fabs((m4.capsuleWidth + m4.orbSpacing + m4.orbWidth) - (390.0 - 32.0)) < 1e-6);

    // Fallback when itemCount < 3: never leave capsule with < 2 items
    NGDockLayoutMetrics m2 = NGComputeDockLayoutC(390.0, 16.0, 52.0, 2, true);
    assert(m2.hasDetachedOrb == false);
    assert(m2.capsuleItemCount == 2);

    printf("dock_logic_ok\n");
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
            self.assertIn("dock_logic_ok", res.stdout)

    def test_capsule_dock_delegate_and_haptic_wiring(self):
        src = (ROOT / "src/Dock/NGCapsuleDockView.m").read_text(encoding="utf-8")
        self.assertIn("tabBarController:shouldSelectViewController:", src)
        self.assertIn("tabBarController:didSelectViewController:", src)
        self.assertIn("UIImpactFeedbackGenerator", src)
        self.assertIn("NGApplyCapsuleCorners", src)
        self.assertIn("NGCreateLiquidGlassView", src)

    def test_objc_arm64_ios_syntax_and_type_check(self):
        clang = find_clang()
        shims = ROOT / "tests/sdk_shims"
        for name in ["NGBadgeSync.m", "NGCapsuleDockView.m"]:
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
