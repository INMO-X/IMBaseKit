# IMBaseKit Example

可运行 Demo，按 [docs/USAGE.md](../docs/USAGE.md) 的场景调用公开 API。依赖公开仓 tag `0.1.0` 的静态 XCFramework。

```bash
cd Example
pod install
open IMBaseKit.xcworkspace
```

选择 scheme **IMBaseKit_Example**，部署目标 iOS 15+。菜单项会弹出结果说明。`clearAllCache` 会清空本 App 的 MMKV、UserDefaults 与图片缓存，需要二次确认。

本地未推送 tag 时，把 Podfile 里的 `:git` 行换成注释中的 `:path => '../'`。
