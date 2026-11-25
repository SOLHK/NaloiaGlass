import os
from pathlib import Path
import re
import shutil
import subprocess
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


class SettingsAndEntryTest(unittest.TestCase):
    def test_files_exist(self):
        expected = [
            ROOT / "src/Settings/NGSettingsViewController.h",
            ROOT / "src/Settings/NGSettingsViewController.m",
            ROOT / "src/Settings/NGWeChatSettingsEntry.h",
            ROOT / "src/Settings/NGWeChatSettingsEntry.m",
            ROOT / "src/NGEntry.m",
        ]
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing file: {path}")

    def test_entry_hook_surface_and_anti_goals(self):
        entry_m = (ROOT / "src/NGEntry.m").read_text(encoding="utf-8")
        self.assertIn("__attribute__((constructor(101)))", entry_m)
        self.assertIn("isWeChatHostProcess", entry_m)
        self.assertIn("syncSolariumPreferenceKey", entry_m)
        self.assertIn("UITabBarController.class", entry_m)
        self.assertIn("UITabBar.class", entry_m)

        # Scan entire src/ tree for Anti-Goals:
        # 1. Never swizzle UIView addSubview:, UIVisualEffectView, or UITabBarItem
        # 2. Never match "ExtraLight" globally
        for m_file in (ROOT / "src").rglob("*.m"):
            txt = m_file.read_text(encoding="utf-8")
            self.assertNotIn("ExtraLight", txt, f"Forbidden global ExtraLight string in {m_file.name}")
            self.assertIsNone(
                re.search(r"NGSwizzleInstanceMethod\s*\(\s*(?:UIView|UIVisualEffectView|UITabBarItem)", txt),
                f"Forbidden global class swizzle in {m_file.name}",
            )

    def test_wechat_settings_dynamic_resolution_and_gestures(self):
        entry_src = (ROOT / "src/Settings/NGWeChatSettingsEntry.m").read_text(encoding="utf-8")
        self.assertIn('"NewSettingViewController"', entry_src)
        self.assertIn("objc_getClass(", entry_src)
        self.assertIn('objc_getClass("WCTableViewNormalCellManager")', entry_src)
        self.assertIn("UILongPressGestureRecognizer", entry_src)
        self.assertIn("UITapGestureRecognizer", entry_src)
        self.assertIn("NGDockDidAttachMainTabBarNotification", entry_src)
        # Ensure zero link-time @implementation or direct symbol reference to WeChat private classes
        self.assertNotIn("@implementation MMTableView", entry_src)

    def test_all_objc_sources_compile_cleanly_for_arm64_ios(self):
        clang = find_clang()
        shims = ROOT / "tests/sdk_shims"
        m_files = sorted((ROOT / "src").rglob("*.m"))
        self.assertGreaterEqual(len(m_files), 10)
        for target in m_files:
            proc = subprocess.run(
                [
                    clang,
                    "-target",
                    "arm64-apple-ios16.0",
                    "-nostdlibinc",
                    "-fsyntax-only",
                    "-fobjc-arc",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-isystem",
                    str(shims),
                    f"-I{ROOT / 'src/Core'}",
                    f"-I{ROOT / 'src/Dock'}",
                    f"-I{ROOT / 'src/Settings'}",
                    str(target),
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, f"Clang failed on {target.name}:\n{proc.stderr}")


if __name__ == "__main__":
    unittest.main()
