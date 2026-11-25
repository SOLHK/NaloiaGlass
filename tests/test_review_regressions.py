from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ReviewRegressionsTest(unittest.TestCase):
    def test_weak_controller_box_prevents_dangling_assign(self):
        coord = (ROOT / "src/Dock/NGDockCoordinator.m").read_text(encoding="utf-8")
        self.assertIn("NGWeakControllerBox", coord)
        self.assertIsNone(
            re.search(r"kNGManagedOwnerControllerKey\s*,\s*controller\s*,\s*OBJC_ASSOCIATION_ASSIGN", coord),
            "Must not store raw OBJC_ASSOCIATION_ASSIGN pointer to UITabBarController",
        )

    def test_window_fallback_gesture_attaches_when_window_becomes_available(self):
        coord = (ROOT / "src/Dock/NGDockCoordinator.m").read_text(encoding="utf-8")
        self.assertIn("kNGNotifiedWindowAttachKey", coord)
        self.assertIn("bar.window", coord)

    def test_hidden_ancestor_wrapper_skips_descendant_badge_scan(self):
        badge = (ROOT / "src/Dock/NGBadgeSync.m").read_text(encoding="utf-8")
        # Before enqueuing sub.subviews, hidden or <=0.05 alpha containers must short-circuit
        loop_body = badge.split("for (NSUInteger idx = 0;", 1)[1]
        skip_pos = loop_body.find("if (sub.hidden || sub.alpha <= 0.05)")
        enqueue_pos = loop_body.find("[queue addObjectsFromArray:sub.subviews]")
        self.assertNotEqual(skip_pos, -1, "Missing early skip for hidden/transparent container view")
        self.assertLess(skip_pos, enqueue_pos, "Early skip must precede sub.subviews enqueue")

    def test_floating_capsule_suppresses_wechat_legacy_backdrops(self):
        styler_h = (ROOT / "src/Dock/NGNativeSolariumStyler.h").read_text(encoding="utf-8")
        coord_m = (ROOT / "src/Dock/NGDockCoordinator.m").read_text(encoding="utf-8")
        self.assertIn("suppressWeChatLegacyBackdropsInTabBar:", styler_h)
        capsule_branch = coord_m.split("if (mode == NGDockModeFloatingCapsule)", 1)[1]
        self.assertIn("suppressWeChatLegacyBackdropsInTabBar:", capsule_branch)

    def test_retap_active_tab_does_not_double_fire_did_select(self):
        dock_m = (ROOT / "src/Dock/NGCapsuleDockView.m").read_text(encoding="utf-8")
        tap_fn = dock_m.split("- (void)handleSlotTapped:", 1)[1].split("- (void)refreshAppearanceAndSelectionAnimated:", 1)[0]
        self.assertIn("BOOL forwardedToNativeControl = NO;", tap_fn)
        self.assertIn("if (!forwardedToNativeControl", tap_fn)

    def test_symbol_weight_uses_typed_enum_constant(self):
        settings_m = (ROOT / "src/Settings/NGSettingsViewController.m").read_text(encoding="utf-8")
        uikit_h = (ROOT / "tests/sdk_shims/UIKit/UIKit.h").read_text(encoding="utf-8")
        self.assertNotIn("weight:5]", settings_m)
        self.assertIn("weight:UIImageSymbolWeightMedium]", settings_m)
        self.assertIn("UIImageSymbolWeightMedium", uikit_h)

    def test_dock_height_slider_up_to_58pt_is_not_clamped_to_49pt(self):
        coord_m = (ROOT / "src/Dock/NGDockCoordinator.m").read_text(encoding="utf-8")
        dock_m = (ROOT / "src/Dock/NGCapsuleDockView.m").read_text(encoding="utf-8")
        # Host frame must expand up to prefs.dockHeight rather than hard-capping at 49pt
        host_fn = coord_m.split("- (CGRect)capsuleHostFrameForTabBar:", 1)[1].split("- (void)applyCurrentModeToController:", 1)[0]
        self.assertIn("NGPreferences.shared.dockHeight", host_fn)
        self.assertNotIn("MIN(prefs.dockHeight, MAX(38.0, CGRectGetHeight(self.bounds)))", dock_m)


if __name__ == "__main__":
    unittest.main()
