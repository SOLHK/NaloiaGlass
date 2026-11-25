# Naloia Glass

专为 **`.dylib` 注入签 IPA** 设计的 **iOS 26+ 微信（`com.tencent.xin`）液态玻璃 Dock 栏插件**。

融合了系统级原生解锁与自绘悬浮胶囊两条技术路线的优点，**零越狱框架依赖**（不依赖 `CydiaSubstrate` / `ElleKit` / `libhooker`），保持微信官方原包名 `com.tencent.xin` 注入重签即可稳定加载。

---

## 核心特性

1. **双模合一液态玻璃引擎**
   - **模式 A：iOS 26 系统真原生模式（Solarium，默认）**
     - 在启动超早期同步应用域 `IgnoreSolariumLinkedOnCheck` 解锁 iOS 26 系统真原生 `UITabBar` 液态玻璃（真实 GPU 光学折射、高光边缘与拖动液态透镜反馈）。
     - **局部精准去遮罩**：仅在微信主底栏子树内剥离遗留遮挡层（如 `tag=102289`），绝不全局 Hook `UIView addSubview:` 或按 `"ExtraLight"` 盲目隐藏模糊视图，零误伤微信弹窗与小程序。
   - **模式 B：自绘悬浮胶囊模式（Floating Capsule Dock，免重启实时热调）**
     - 动态桥接 iOS 26 `UIGlassEffect`（支持常规 `Regular` 与清透 `Clear` 变体，开启 `interactive`）与 `UICornerConfiguration` 胶囊圆角。
     - 支持**右侧独立分离液态圆钮**（如将「我」独立为右侧圆形玻璃按钮）、弹性选中滑块（默认微信绿 `#07C160`，支持预设与 `#RRGGBB` 自定义）、左右边距与胶囊高度滑块微调、可选点击轻触感反馈。
     - **完整角标 + 朋友圈纯红点同步**：既同步 `badgeValue` 数字未读角标，又实时扫描原生按钮内的微信纯红点视图（「发现」页朋友圈动态红点不丢失），并保留双击底栏滚回未读消息的原生代理行为。
2. **原生包名精准锁定与进程隔离**
   - 严格限定官方主应用 `com.tencent.xin`，自动排除 `.appex` 扩展进程（分享扩展/通知扩展），低版本系统（< iOS 26）自动保持静默无副作用。
3. **双入口可视化设置与实时预览**
   - **入口 1**：微信 `我 → 设置` 首分组自动展示 `Naloia Glass` 入口。
   - **入口 2**：在微信主界面**长按底部 Dock 栏 0.8 秒**（或主窗口三指三击）随时呼出设置面板，内置可点按交互的实时液态胶囊预览区、底栏层级诊断信息一键复制及 JSON 配置导入/导出/重置。

---

## IPA 注入与重签安装指南（推荐）

1. 前往本仓库 **GitHub Actions** 最新构建记录下载 **`NaloiaGlass-ipa-dylib`** 产物，解压得到 `NaloiaGlass.dylib`。
2. 打开你常用的 IPA 签名/注入工具（**Feather / ESign / TrollFools / Sideloadly / Azule** 等）：
   - 选择未砸壳加密之外的正常解密微信 IPA。
   - 在「注入动态库 / Frameworks / Dylibs」中添加 **`NaloiaGlass.dylib`**（插件内置 `@rpath/NaloiaGlass.dylib`，无需勾选附加 `CydiaSubstrate` 库）。
   - **保持 Bundle Identifier 为原版 `com.tencent.xin` 不变**，使用你的证书或 TrollStore 签名安装即可。
3. 若使用越狱 Rootless 环境，也可直接下载附产物 `NaloiaGlass-rootless-deb` 安装 `.deb`。

---

## 本地测试与编译

```bash
# 运行源码契约、原生 C 逻辑测试与 arm64 Objective-C 严格语法/类型检查
python3 -m unittest discover -s tests -p "test_*.py" -v

# 在 macOS (Xcode 16+ / 26+) 构建 @rpath/NaloiaGlass.dylib 及打包产物
make dylib
make deb
```

## 开源许可

MIT License
