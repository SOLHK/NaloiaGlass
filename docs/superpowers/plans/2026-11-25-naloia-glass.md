# Naloia Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建零越狱库依赖、严格锁定微信官方包名 `com.tencent.xin` 的 iOS 26+ 微信液态玻璃 Dock 栏插件 `NaloiaGlass.dylib`，并推送到 `https://github.com/SOLHK/NaloiaGlass` 触发自动化构建与重签验证。

**Architecture:** 插件采用「iOS 26 系统真原生 Solarium 解锁 + 自绘 `UIGlassEffect` 悬浮胶囊/右侧分离圆钮」双模合一架构。底层通过 `objc/runtime` 幂等 IMP Swizzle 挂载公开 `UITabBarController` / `UITabBar` 生命周期，iOS 26 新增玻璃与胶囊圆角 API 全部走类型安全的运行时动态桥接，确保任意 Xcode SDK 可零警告编译出 `@rpath/NaloiaGlass.dylib` 供 IPA 重签工具直接注入。

**Tech Stack:** Objective-C (ARC), UIKit / QuartzCore / CoreFoundation / `libobjc`, Python 3 (`unittest`), LLVM Clang (`arm64-apple-ios16.0` 本地语法/类型检查 + GitHub Actions `macos-latest` 真 SDK 链接与 `codesign` 重签校验).

**Spec:** `docs/superpowers/specs/2026-11-25-naloia-glass-design.md`（同步自已确认的 `naloia_glass_design.md`）

## Global Constraints

- 宿主激活条件严格锁定 `[NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.tencent.xin"]` 且包路径不以 `.appex` 结尾；不做多开改包名模糊匹配。
- 运行系统低于 iOS 26.0 时安全静默，不注入任何 UI 改动，不写入 `IgnoreSolariumLinkedOnCheck`。
- 动态库 `LC_ID_DYLIB` 必须为 `@rpath/NaloiaGlass.dylib`，仅链接系统公开框架（`UIKit`、`Foundation`、`QuartzCore`、`CoreFoundation`、`CoreGraphics`、`libobjc`），严禁依赖 `CydiaSubstrate`、`ElleKit`、`Orion` 或 `/var/jb` 路径。
- 严禁全局 Hook `-[UIView addSubview:]`、全局拦截 `UIVisualEffectView` 或按 `"ExtraLight"` 全局隐藏视图；严禁修改非微信主底栏的 `UITabBarItem`。
- 除模式 A 必需的 `com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck` 外，插件自有配置全部隔离在 `com.solhk.naloiaglass.*` 键空间内。
- 所有源码必须在 `-fobjc-arc -Wall -Wextra -Werror` 下零警告通过编译。

## Review Focus

1. **IPA 签名器将 `.dylib` 同时注入进微信 `.appex` 扩展进程（如分享扩展/通知扩展）**：若在扩展进程激活 UI Hook 或写偏好键会导致扩展崩溃或超内存 → `NGEnvironment` 必须同时校验 `bundleID == "com.tencent.xin"` 且 `!bundlePath.hasSuffix(".appex")`（Task 1 测试覆盖）。
2. **从「系统真原生模式」切换到「自绘悬浮胶囊模式」后残留 `IgnoreSolariumLinkedOnCheck`**：下次启动会出现系统原生玻璃与自绘胶囊双层叠加 → `NGPreferences` 必须仅在 `enabled && dockMode == NGDockModeSystemNative` 时写入该键，其余任何模式/关闭状态立即清除该键（Task 1 测试覆盖）。
3. **微信切换深浅色或语言时 UIKit 销毁重建内部 `UITabBarButton`**：若按旧缓存跳过处理，新生成的原生按钮会透出在悬浮胶囊下方 → `NGDockCoordinator` 每次布局必须校验当前 `UITabBarButton` 实例集合与隐藏快照完全一致，不一致则立即恢复重绑（Task 3 测试覆盖）。
4. **微信「发现」页朋友圈更新仅显示无文字纯红点（`badgeValue == nil`）与大图误判**：必须识别 `4..28pt × 4..22pt` 的可见红点/徽标子视图，同时排除隐藏视图、低透明度视图及图标主视图（Task 2 测试覆盖）。
5. **导入手改或损坏的 JSON 配置（超界边距导致负宽度、非法模式枚举、错误 `#RRGGBB`）**：`NGPreferences` 必须对数值做区间钳制（边距 `8..28`、高度 `44..58`、模式 `{1,2}`）并校验 6 位十六进制颜色，非法值回退默认微信绿 `#07C160`（Task 1 测试覆盖）。

---

### Task 1: 仓库初始化、核心环境识别、配置中心与 iOS 26 运行时桥接

**Files:**
- Create: `D:/Gemini/NaloiaGlass/VERSION`
- Create: `D:/Gemini/NaloiaGlass/.gitignore`
- Create: `D:/Gemini/NaloiaGlass/LICENSE`
- Create: `D:/Gemini/NaloiaGlass/docs/superpowers/specs/2026-11-25-naloia-glass-design.md`
- Create: `D:/Gemini/NaloiaGlass/docs/superpowers/plans/2026-11-25-naloia-glass.md`
- Create: `D:/Gemini/NaloiaGlass/tests/sdk_shims/`（最小化 UIKit/Foundation/QuartzCore/objc 头声明桩，供本地 Windows Clang `-target arm64-apple-ios16.0 -fsyntax-only` 对全部 `.m` 做真实编译器类型检查）
- Create: `D:/Gemini/NaloiaGlass/src/Core/NGEnvironment.h`
- Create: `D:/Gemini/NaloiaGlass/src/Core/NGEnvironment.m`
- Create: `D:/Gemini/NaloiaGlass/src/Core/NGPreferences.h`
- Create: `D:/Gemini/NaloiaGlass/src/Core/NGPreferences.m`
- Create: `D:/Gemini/NaloiaGlass/src/Core/NGRuntimeBridge.h`
- Create: `D:/Gemini/NaloiaGlass/src/Core/NGRuntimeBridge.m`
- Test: `D:/Gemini/NaloiaGlass/tests/test_core_contracts.py`

**Interfaces:**
- Produces:
  - `typedef NS_ENUM(NSInteger, NGDockMode) { NGDockModeDisabled = 0, NGDockModeSystemNative = 1, NGDockModeFloatingCapsule = 2 };`
  - `NGEnvironment`:
    - `+ (BOOL)isWeChatMainAppBundle:(nullable NSString *)bundleID bundlePath:(nullable NSString *)bundlePath;`
    - `+ (BOOL)isWeChatHostProcess;`
    - `+ (BOOL)isIOS26OrNewer;`
    - `+ (BOOL)shouldActivatePlugin;`
    - `+ (NSString *)diagnosticSummary;`
  - `NGPreferences`:
    - `extern NSNotificationName const NGPreferencesDidChangeNotification;`
    - `+ (instancetype)shared;`
    - Properties: `BOOL enabled` (default `YES`), `NGDockMode dockMode` (default `NGDockModeSystemNative`), `BOOL clearGlass` (`NO`), `BOOL hideTabTitles` (`NO`), `BOOL detachedRightButton` (`NO`), `BOOL hapticEnabled` (`YES`), `CGFloat horizontalInset` (`16.0`, clamped `8.0..28.0`), `CGFloat dockHeight` (`52.0`, clamped `44.0..58.0`), `NSString *accentHex` (`@"#07C160"`).
    - `- (NGDockMode)effectiveDockMode;`
    - `- (BOOL)syncSolariumPreferenceKey;`（返回当前应用域是否处于激活 Solarium 键状态）
    - `- (nullable NSString *)exportJSONString;`
    - `- (BOOL)importJSONString:(NSString *)json error:(NSError * _Nullable * _Nullable)error;`
    - `- (void)resetToDefaults;`
  - `NGRuntimeBridge`:
    - `BOOL NGSwizzleInstanceMethod(Class cls, SEL originalSel, IMP replacementImp, IMP _Nullable * _Nonnull outOriginalImp);`
    - `UIVisualEffectView * _Nullable NGCreateLiquidGlassView(BOOL clearVariant, BOOL interactive);`
    - `void NGApplyCapsuleCorners(UIView *view, CGFloat fallbackRadius);`
    - `UIColor *NGColorFromHexString(NSString * _Nullable hex, UIColor *fallback);`

- [ ] **Step 1: 克隆空仓库 `SOLHK/NaloiaGlass` 到 `D:/Gemini/NaloiaGlass`，落盘设计文档与计划，并编写失败测试 `tests/test_core_contracts.py`**

断言覆盖：
1. `NGEnvironment` 仅接受精确 `com.tencent.xin` 且拒绝 `.appex` 后缀路径，包含 `majorVersion >= 26` 判定。
2. `NGPreferences` 所有持久化键均以 `com.solhk.naloiaglass.` 开头；`IgnoreSolariumLinkedOnCheck` 仅在 `enabled && dockMode == NGDockModeSystemNative` 分支写入，其余分支清理；包含 `8.0..28.0` / `44.0..58.0` 钳制与 `#07C160` 十六进制校验。
3. `NGRuntimeBridge` 动态解析 `UIGlassEffect`（`effectWithStyle:` `0`/`1`、`setInteractive:`）与 `UICornerConfiguration`（`capsuleConfiguration`、`setCornerConfiguration:`），并检查 `UIAccessibilityIsReduceTransparencyEnabled()`。
4. 调用本地 `clang -target arm64-apple-ios16.0 -fsyntax-only -fobjc-arc -Wall -Wextra -Werror -isystem tests/sdk_shims -Isrc` 编译检查 `src/Core/*.m` 零错误。

- [ ] **Step 2: 运行测试确认失败（RED）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: FAIL（`src/Core/*` 尚未创建）

- [ ] **Step 3: 实现 `VERSION` (`1.0.0`)、`.gitignore`、`LICENSE`、`tests/sdk_shims/*` 与 `src/Core/*`**

确保 `NGPreferences` 提供纯 C 数值钳制与 Hex 校验辅助函数以便静态/语法双重校验，`NGSwizzleInstanceMethod` 使用全局集合按 `(Class, SEL)` 防重复 Hook。

- [ ] **Step 4: 运行测试确认全部通过（GREEN）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: PASS（含 Clang `arm64-apple-ios16.0` `-Werror` 语法与类型检查通过）

- [ ] **Step 5: Git 提交 Task 1**

Run: `git -C D:/Gemini/NaloiaGlass add . && git -C D:/Gemini/NaloiaGlass commit -m "feat(core): bootstrap NaloiaGlass environment, isolated prefs, and iOS 26 runtime bridge"`

---

### Task 2: 双通道未读红点同步器与悬浮胶囊 / 右侧分离圆钮视图

**Files:**
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGBadgeSync.h`
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGBadgeSync.m`
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGCapsuleDockView.h`
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGCapsuleDockView.m`
- Test: `D:/Gemini/NaloiaGlass/tests/test_dock_views.py`

**Interfaces:**
- Consumes: `NGPreferences`, `NGRuntimeBridge` from Task 1.
- Produces:
  - `NGBadgeState`: `@property (nonatomic, copy, nullable, readonly) NSString *textBadge;`, `@property (nonatomic, assign, readonly) BOOL showsDot;`
  - `NGBadgeSync`:
    - `+ (NGBadgeState *)resolveBadgeForItem:(nullable UITabBarItem *)item nativeButton:(nullable UIView *)nativeButton;`
    - `BOOL NGIsLikelyUnreadIndicatorView(const char * _Nullable className, CGFloat width, CGFloat height, BOOL hidden, CGFloat alpha, BOOL isRedTinted);`
  - `NGCapsuleDockView : UIView`:
    - `@property (nonatomic, weak, nullable) UITabBarController *controller;`
    - `@property (nonatomic, copy, nullable) NSArray<UIView *> *nativeButtonsSnapshot;`
    - `- (void)reloadFromController;`
    - `- (void)refreshBadgeStatesOnly;`
    - `- (void)refreshAppearanceAndSelectionAnimated:(BOOL)animated;`
    - `- (void)configureForPreviewItems:(NSArray<UITabBarItem *> *)items selectedIndex:(NSUInteger)selectedIndex;`

- [ ] **Step 1: 编写失败测试 `tests/test_dock_views.py`**

断言覆盖：
1. `NGBadgeSync` 包含 `badgeValue` 优先逻辑及无文字红点几何/类名判定函数 `NGIsLikelyUnreadIndicatorView`（宽度 `4..28`、高度 `4..22`、`!hidden`、`alpha > 0.05`、识别 `Badge`/`Dot`/`RedPoint`/`Unread` 或红色背景圆点，排除图标与文字主视图）；同时用宿主机 Clang 编译纯 C 判定逻辑二进制直接跑真值断言测试！
2. `NGCapsuleDockView` 支持主胶囊 + `detachedRightButton`（当 `items.count >= 3` 时分离最右侧 Tab 为独立圆形 `UIVisualEffectView` 液态玻璃圆钮）、弹性滑块 `selectionLens`、可选标题隐藏、可选 `UIImpactFeedbackGenerator`、调用 `tabBarController:shouldSelectViewController:` / `tabBarController:didSelectViewController:` 及重复点击已选中 Tab 的转发逻辑。
3. Clang `-target arm64-apple-ios16.0 -fsyntax-only -Werror` 编译通过 `NGBadgeSync.m` 与 `NGCapsuleDockView.m`。

- [ ] **Step 2: 运行测试确认失败（RED）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: FAIL（`NGBadgeSync` 与 `NGCapsuleDockView` 尚未实现）

- [ ] **Step 3: 实现 `NGBadgeSync` 与 `NGCapsuleDockView`**

将红点几何分类器提取为可被宿主机 C 编译器直接链接单测的无副作用纯函数，并在 `NGCapsuleDockView` 中将触控按钮置于 `UIVisualEffectView` 上层兄弟节点以防 iOS 26 玻璃内部子视图吞点击。

- [ ] **Step 4: 运行全量测试确认通过（GREEN）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: PASS（含宿主机 C 二进制单测与 iOS arm64 Clang 语法检查全部通过）

- [ ] **Step 5: Git 提交 Task 2**

Run: `git -C D:/Gemini/NaloiaGlass add . && git -C D:/Gemini/NaloiaGlass commit -m "feat(dock): add dual-channel WeChat badge sync and floating capsule/detached orb view"`

---

### Task 3: 系统真原生 Solarium 局部清理器与主底栏协调器

**Files:**
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGNativeSolariumStyler.h`
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGNativeSolariumStyler.m`
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGDockCoordinator.h`
- Create: `D:/Gemini/NaloiaGlass/src/Dock/NGDockCoordinator.m`
- Test: `D:/Gemini/NaloiaGlass/tests/test_coordinator_and_solarium.py`

**Interfaces:**
- Consumes: `NGEnvironment`, `NGPreferences`, `NGRuntimeBridge`, `NGBadgeSync`, `NGCapsuleDockView`.
- Produces:
  - `NGNativeSolariumStyler`:
    - `+ (void)applyToMainTabBar:(UITabBar *)tabBar hideTitles:(BOOL)hideTitles;`
    - `+ (void)restoreTabBar:(UITabBar *)tabBar;`
  - `NGDockCoordinator`:
    - `+ (instancetype)shared;`
    - `+ (NSArray<NSString *> *)mainTabBarControllerCandidates;`
    - `- (BOOL)isEligibleMainTabBarController:(UITabBarController *)controller;`
    - `- (BOOL)isManagedMainTabBar:(UITabBar *)tabBar;`
    - `- (void)attachIfEligible:(UITabBarController *)controller;`
    - `- (void)handleManagedTabBarLayout:(UITabBar *)tabBar;`
    - `- (void)refreshAllManagedTabBars;`
    - `- (NSString *)hierarchyDiagnosticReport;`

- [ ] **Step 1: 编写失败测试 `tests/test_coordinator_and_solarium.py`**

断言覆盖：
1. `NGNativeSolariumStyler` 严格遍历传入的 `tabBar` 子树（有界深度与节点上限），识别 `tag == 102289` 及位于按钮下方的非系统遮罩层，保护 `_UIBarBackground` 与类名含 `Glass`/`Solarium`/`Portal`/`Lens` 的系统层；仅快照修改该 `tabBar.items` 的标题与 `imageInsets` 并在 `restoreTabBar:` 完整恢复；绝无全局 `UIView` / `UITabBarItem` Hook。
2. `NGDockCoordinator` 校验 `MMTabBarController` 候选类或根窗口主 TabBar（`items.count` 在 `3..6`），在 `FloatingCapsule` 模式下对 `UITabBarButton` 快照做实时一致性核对（UIKit 重建按钮时自动失效重绑），切换模式前总是先完整 `restore` 旧状态避免叠层。
3. Clang `-target arm64-apple-ios16.0 -fsyntax-only -Werror` 编译通过。

- [ ] **Step 2: 运行测试确认失败（RED）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: FAIL

- [ ] **Step 3: 实现 `NGNativeSolariumStyler` 与 `NGDockCoordinator`**

使用 `NSHashTable.weakObjectsHashTable` 持有受管 `UITabBarController`，用 `styleStamp` + `bounds.size` 防布局重入死循环。

- [ ] **Step 4: 运行全量测试确认通过（GREEN）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: PASS

- [ ] **Step 5: Git 提交 Task 3**

Run: `git -C D:/Gemini/NaloiaGlass add . && git -C D:/Gemini/NaloiaGlass commit -m "feat(dock): add scoped Solarium backdrop cleaner and master dock coordinator"`

---

### Task 4: 微信双入口设置挂载、实时交互设置面板与启动构造器

**Files:**
- Create: `D:/Gemini/NaloiaGlass/src/Settings/NGSettingsViewController.h`
- Create: `D:/Gemini/NaloiaGlass/src/Settings/NGSettingsViewController.m`
- Create: `D:/Gemini/NaloiaGlass/src/Settings/NGWeChatSettingsEntry.h`
- Create: `D:/Gemini/NaloiaGlass/src/Settings/NGWeChatSettingsEntry.m`
- Create: `D:/Gemini/NaloiaGlass/src/NGEntry.m`
- Test: `D:/Gemini/NaloiaGlass/tests/test_settings_and_entry.py`

**Interfaces:**
- Consumes: All `Core` & `Dock` interfaces from Tasks 1–3.
- Produces:
  - `NGSettingsViewController : UITableViewController`
  - `NGWeChatSettingsEntry`:
    - `+ (void)installEntryHooks;`
    - `+ (void)attachQuickGesturesToTabBar:(UITabBar *)tabBar;`
    - `+ (void)attachFallbackGestureToWindow:(nullable UIWindow *)window;`
    - `+ (void)presentSettingsFromViewController:(nullable UIViewController *)presenter;`
  - `NGEntry.m`: `__attribute__((constructor(101)))` 早期入口。

- [ ] **Step 1: 编写失败测试 `tests/test_settings_and_entry.py`**

断言覆盖：
1. `NGEntry.m` 拥有 `__attribute__((constructor(101)))`，先检查 `[NGEnvironment isWeChatHostProcess]`，在 iOS 26+ 调用 `[[NGPreferences shared] syncSolariumPreferenceKey]`，且仅 Swizzle `UITabBarController` 与 `UITabBar`（全工程扫描确认不存在对 `UIView`、`UIVisualEffectView`、`UITabBarItem` 的方法交换）。
2. `NGWeChatSettingsEntry` 通过 `objc_getClass` 动态探测 `NewSettingViewController` / `MMNewSettingViewController` / `WCNewSettingViewController` / `SettingViewController` 注入 `"Naloia Glass"` 入口（零链接期微信类引用），并挂载 `0.8s` 底栏长按与三指三击手势（防重复弹窗栈）。
3. `NGSettingsViewController` 内置 `NGCapsuleDockView` 实时预览头视图、模式切换（仅在 Solarium 键状态变化时弹出可选重启确认框，胶囊各项参数实时生效）、颜色预设与 `#RRGGBB` 输入、诊断复制与 JSON 导入导出/重置。
4. 全量 `src/**/*.m` 通过 Clang `-target arm64-apple-ios16.0 -fsyntax-only -Werror`。

- [ ] **Step 2: 运行测试确认失败（RED）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: FAIL

- [ ] **Step 3: 实现 `NGSettingsViewController`、`NGWeChatSettingsEntry` 与 `NGEntry.m`**

并在 `NGDockCoordinator` 首次绑定主底栏时调用 `[NGWeChatSettingsEntry attachQuickGesturesToTabBar:bar]` 与 `[NGWeChatSettingsEntry attachFallbackGestureToWindow:bar.window]`。

- [ ] **Step 4: 运行全量测试确认通过（GREEN）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: PASS

- [ ] **Step 5: Git 提交 Task 4**

Run: `git -C D:/Gemini/NaloiaGlass add . && git -C D:/Gemini/NaloiaGlass commit -m "feat(settings): add WeChat settings injection, gesture fallback, live preview UI, and constructor entry"`

---

### Task 5: `.dylib` / `.deb` 构建脚本、IPA 重签兼容套件、文档与 GitHub Actions 流水线并推送远端

**Files:**
- Create: `D:/Gemini/NaloiaGlass/scripts/build_dylib.sh`
- Create: `D:/Gemini/NaloiaGlass/scripts/package_deb.sh`
- Create: `D:/Gemini/NaloiaGlass/Makefile`
- Create: `D:/Gemini/NaloiaGlass/NaloiaGlass.plist`
- Create: `D:/Gemini/NaloiaGlass/control`
- Create: `D:/Gemini/NaloiaGlass/.github/workflows/build.yml`
- Create: `D:/Gemini/NaloiaGlass/README.md`
- Test: `D:/Gemini/NaloiaGlass/tests/test_macho_and_ipa_compat.py`

**Interfaces:**
- Consumes: Complete `src/` tree and `VERSION`.
- Produces:
  - `scripts/build_dylib.sh` → `dist/NaloiaGlass.dylib`, `dist/NaloiaGlass-<version>-dylib.zip`, `dist/SHA256SUMS.txt`
  - `scripts/package_deb.sh` → `dist/com.solhk.naloiaglass_<version>_iphoneos-arm64.deb`
  - `.github/workflows/build.yml` → Ubuntu 静态与契约检查 + `macos-latest` 真机 `arm64` `.dylib` 编译、`otool -L` 零越狱库白名单断言、`codesign --force --sign -` 二次重签校验、`.zip` 与 `.deb` 产物上传。

- [ ] **Step 1: 编写失败测试 `tests/test_macho_and_ipa_compat.py`**

断言覆盖：
1. `NaloiaGlass.plist` 精确限定 `Bundles == ["com.tencent.xin"]`。
2. `Makefile` 与 `scripts/build_dylib.sh` 编译源码列表与 `src/` 中所有 `.m` 文件 1:1 严格对齐（不漏编任何文件），`-install_name @rpath/NaloiaGlass.dylib` 且无 `CydiaSubstrate` / `-lsubstrate` 链接项。
3. Mach-O 合成审计器测试：校验 `LC_ID_DYLIB` 为 `@rpath/NaloiaGlass.dylib`、拒绝含 `/var/jb` 或 `CydiaSubstrate` 的 `LC_LOAD_DYLIB`、验证 `@rpath` / `Frameworks/` / `Dylibs/` 三种常见 IPA 签名器布局。
4. `.github/workflows/build.yml` 包含静态测试、`macos-latest` 编译、`otool -L` 审计、`codesign --force --sign -` 重签测试与产物上传步骤。

- [ ] **Step 2: 运行测试确认失败（RED）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: FAIL

- [ ] **Step 3: 实现 `scripts/*`、`Makefile`、`NaloiaGlass.plist`、`control`、`.github/workflows/build.yml` 与 `README.md`**

`README.md` 明确写明不改包名（保留 `com.tencent.xin`）的 Feather / ESign / TrollFools / Sideloadly `.dylib` 注入重签步骤、双模式说明、手势入口及构建下载方法。

- [ ] **Step 4: 运行全量本地测试套件确认 100% 通过（GREEN）**

Run: `python -m unittest discover -s D:/Gemini/NaloiaGlass/tests -p "test_*.py" -v`
Expected: PASS（0 failures, 0 errors）

- [ ] **Step 5: 提交并推送到 `https://github.com/SOLHK/NaloiaGlass.git`（`main` 分支），验证远端 GitHub Actions 编译产物**

Run: `git -C D:/Gemini/NaloiaGlass add . && git -C D:/Gemini/NaloiaGlass commit -m "build(ci): add dylib/deb packaging, IPA signing audits, and GitHub Actions workflow" && git -C D:/Gemini/NaloiaGlass push -u origin main`
Expected: Push 成功，并跟踪核实 GitHub Actions `macos-latest` 实际编译出 `NaloiaGlass-1.0.0-dylib.zip` 且零错误通过。
