# IMBaseKit

INMO 私有基础开发套件的 **静态 XCFramework**。包含网络、缓存、钥匙串、加解密、多语言、日志、路由、启动项，以及 `xxx.im.` 命名空间下的 Foundation / UIKit 扩展。

Kingfisher、MMKV、CryptoSwift、CocoaLumberjack、Connectivity、Moya、ObjectMapper **不打进包**，由宿主工程链接同一份。业务代码用到这些类型时仍要 `import` 对应模块。

---

## 环境要求

- iOS 15.0+
- Swift 5
- Xcode 15+
- CocoaPods，并开启 `use_frameworks!`（静态或动态均可）

## 安装

```ruby
platform :ios, '15.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'IMBaseKit', :git => 'https://github.com/INMO-X/IMBaseKit.git', :tag => '0.1.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
```

依赖版本与打这个包时一致：

| 依赖 | 版本 | 用途 |
|---|---|---|
| Moya | 15.0.0 | 网络（同时带入 Alamofire 5.12.2） |
| ObjectMapper | 4.4.2 | 响应模型 |
| Connectivity | 8.0.1 | 连通性 |
| MMKV | 2.4.2 | 键值缓存 |
| Kingfisher | 8.12.0 | 图片缓存清理 |
| CryptoSwift | 1.10.0 | AES |
| CocoaLumberjack/Swift | 3.9.1 | 日志 |

`pod install` 后资源在 **`IMBaseKit.bundle`**（多语言、图片、隐私清单）。`IMLocalizedString` 只在这个 bundle 里查表，不要重命名。

## 宿主 Info.plist

按实际调用的能力补充用途说明：蓝牙、相机、相册读取、相册写入、麦克风、使用期间定位。隐私清单与导出合规见 [docs/PRIVACY.md](docs/PRIVACY.md)。

## 快速开始

```swift
import IMBaseKit

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    IMCrasher.registerCrashHandler()
    #if DEBUG
    IMLogger.shared.enable = true
    IMEnvironmentManager.shared.allowsEnvironmentSwitch = true
    #endif
    IMUtils.set(uid: userId, token: accessToken)
    return true
}
```

`IMBuildRegion.isDomestic` / `isGlobal` 看的是主工程 bundle id：`com.inmox.next` 为国内，`com.inmox.next.global` 为海外。编译这个二进制时的条件编译不会跟着宿主的 Debug / AdHoc 重新打开。

`openRouter` 分发 `hostApp`、`uiKit`、`accountKit`。地区选择是 `inmox://accountKit/regionSelect`，注销账号是 `inmox://accountKit/unregisterAccount`，都要注册 `IMAccountKitRouterServiceProtocol`。账号与安全仍是 `inmox://hostApp/accountSecurity`。R2 设置、新手指引、改名、关于眼镜分别是 `inmox://hostApp/r2DeviceSetting`、`r2NewbieGuide`、`r2ModifyGlassName`、`r2AboutGlass`。

## 示例

[Example/](Example/) 用 tag `0.1.0` 跑通 [docs/USAGE.md](docs/USAGE.md) 里的场景。

```bash
cd Example
pod install
open IMBaseKit.xcworkspace
```

## 文档

| 文档 | 说明 |
|---|---|
| [docs/USAGE.md](docs/USAGE.md) | 场景用法与公开 API |
| [docs/PRIVACY.md](docs/PRIVACY.md) | 隐私清单与宿主配置 |
