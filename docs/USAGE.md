# IMBaseKit 使用指南

本文档面向 **业务 / UI 层开发者**。通过 CocoaPods 引入（`import IMBaseKit`）。安装见仓库根目录 [README.md](../README.md)，隐私清单见 [PRIVACY.md](PRIVACY.md)。

- **Part A**：场景化用法（启动 → 身份与网络 → 缓存 → 多语言 → 日志 → 路由）
- **Part B**：[公开 API 参考](#公开-api-参考)（符号一览，与源码 `///` 对齐）

二进制是 **static XCFramework**。Kingfisher、MMKV、CryptoSwift、CocoaLumberjack、Connectivity、Moya、ObjectMapper 不打进包，由宿主链接同一份。业务代码用到这些类型时仍要 `import` 对应模块。

---

## 目录

### Part A — 场景

1. [整体架构](#1-整体架构)
2. [快速开始](#2-快速开始)
   - 2.A [新手教程：跟着启动顺序走一遍](#2a-新手教程跟着启动顺序走一遍)
3. [启动项](#3-启动项)
4. [网络](#4-网络)
5. [缓存 / 钥匙串 / 沙盒](#5-缓存--钥匙串--沙盒)
6. [多语言、地区与图片](#6-多语言地区与图片)
7. [日志与崩溃](#7-日志与崩溃)
8. [路由](#8-路由)
9. [国内 / 海外与编译标记](#9-国内--海外与编译标记)
10. [系统权限](#10-系统权限)
11. [常见问题](#11-常见问题)

### Part B — [公开 API 参考](#公开-api-参考)

- [Base](#base) · [Cache](#cache) · [Cryptor](#cryptor) · [Localized](#localized) · [Logger / Crasher](#logger--crasher) · [Network](#network) · [Router](#router)

---

## 1. 整体架构

```
┌──────────────────────────────────────────────┐
│              App / 业务模块                    │  import IMBaseKit
│  启动、页面、请求描述、路由实现                  │  需要时再 import Moya / ObjectMapper
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│                 IMBaseKit                     │  一个 Swift module
│  Base / Cache / Cryptor / Localized           │
│  Logger / Crasher / Network / Router          │
└──────────────┬───────────────────────────────┘
               │  编译期依赖，不打进 XCFramework
               ▼
┌──────────────────────────────────────────────┐
│  Moya · ObjectMapper · MMKV · Kingfisher      │
│  CryptoSwift · CocoaLumberjack · Connectivity │
└──────────────────────────────────────────────┘
```

资源不在静态库二进制里。多语言和 `Assets.xcassets` 由 CocoaPods 打成 **`IMBaseKit.bundle`** 拷进 App。`IMLocalizedString` 只在这个 bundle 里查表，不要改名。

源码 pod 可以按子规格引入（`pod 'IMBaseKit/Cache'`）。二进制 pod 是整包，没有子规格。

---

## 2. 快速开始

可运行示例在 [Example/](../Example)。在该目录执行 `pod install`，打开 `IMBaseKit.xcworkspace`，运行 `IMBaseKit_Example`。列表按本文场景调用同一套 API。Example 的 bundle id 是 `com.inmox.next`，用来让 `IMBuildRegion.isDomestic` 为 true。

`application(_:didFinishLaunchingWithOptions:)` 里按这个顺序：

```swift
import IMBaseKit

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    IMCrasher.registerCrashHandler()
    IMLogger.shared.logTrack(.app, event: "didFinishLaunching")
    IMNetworkListener.shared.start()
    IMUtils.set(uid: savedUserId, token: savedAccessToken)
    IMNetworkErrorCenter.shared.errorHandler = MyNetworkErrorHandler.shared
    IMLaunchManager.shared.launch(forKey: IMLaunchKey.sdk)
    return true
}
```

`IMLogger` 和 `IMCacheManager` 首次使用时自己初始化。MMKV 根目录在 Documents。多语言首次调用 `IMLocalizedString` 时按已保存语言或系统语言加载。

---

## 2.A 新手教程：跟着启动顺序走一遍

```
App 启动
  ├─ ① IMCrasher.registerCrashHandler()
  ├─ ② IMNetworkListener.shared.start()
  ├─ ③ 已登录则 IMUtils.set(uid:token:)
  └─ ④ IMLaunchManager.shared.launch(forKey: IMLaunchKey.sdk)
登录成功
  └─ ⑤ 再次 IMUtils.set(uid:token:)，之后请求头才带 Authorization
页面
  ├─ ⑥ IMLocalizedString 取文案
  ├─ ⑦ IMCommonProvider.request 发请求
  └─ ⑧ openRouter 跳转，不 import 目标页面
退出登录
  └─ ⑨ IMUtils.set(uid: nil, token: nil)
```

### ① 崩溃收集

越早越好。之后的未捕获 `NSException` 和信号会写入 `{IMLogsDirectory}/Crash`，再交给原来的 handler。

### ② 网络连通性

`IMCommonProvider` 在 `IMNetworkListener.shared.isConnected == false` 时不发请求：有缓存走缓存，没有则回一条「网络不可用」。变化时发 `.im.connectivityChanged`，这条通知在后台队列，刷 UI 要回主线程。

### ③④ 身份与启动项

`IMUtils.set(uid:token:)` 只放内存，不落盘。公共请求头在 token 非空时附加 `Authorization: Bearer <token>`。启动项见 [§3](#3-启动项)。

### ⑤ 登录后再注入一次

登录接口返回的 token 要立刻写回去，否则后续请求没有 `Authorization`。退出登录传 `nil`。

### ⑥ 文案

```swift
titleLabel.text = IMLocalizedString("common_done", "完成")
```

第二个参数是 key 不存在时的兜底。查表范围见 [§6](#6-多语言地区与图片)。

### ⑦ 请求

一个业务模块 = 一个 `IMCommonRequestTarget` + 若干 `IMCommonResponse` 子类 + 一个 `IMCommonProvider`。见 [§4](#4-网络)。

### ⑧ 跳转

```swift
openRouter(IMRouterURL.searchDevice, params: [IMRouterParamKey.deviceType: "C100"])
```

只处理 `inmox://`。`host` 为 `hostApp` 时进宿主实现的 `IMHostAppRouterServiceProtocol`，为 `uiKit` 时进 IMUIKit，为 `accountKit` 时进 `IMAccountKitRouterServiceProtocol`。见 [§8](#8-路由)。

---

## 3. 启动项

私有 SDK 实现 `IMLaunchRegistrant`。`launch(forKey:)` 会扫 dyld 已加载镜像，同名 `imLaunchName` 只执行一次。

```swift
import IMBaseKit

@objcMembers
public final class MySDKLaunch: NSObject, IMLaunchRegistrant {
    public var imLaunchKey: String { IMLaunchKey.sdk }
    public var imLaunchName: String { "MySDK" }
    public func imLaunchExecute() {
        TheRouter.registerService(MyHostAppRouterService.self, instance: MyHostAppRouterService())
    }
}
```

类必须是 `@objcMembers` 的 `NSObject` 子类，并保留无参 `init`。静态库没有独立镜像，类合并进主程序后仍会被扫到。

宿主也可以登记闭包：

```swift
IMLaunchItem.register(key: IMLaunchKey.sdk, name: "Analytics") {
    // ...
}
```

ObjC 可用 `IM_FUNCTION_EXPORT(SDK, MySDK) { ... }` 写入 Mach-O `__SDK` 段。`IMLaunchKey.sdk` 的值是 `"SDK"`，section 名是 `__SDK`。

`TheRouter.registerService` 在串行队列里异步写入。注册后立刻调用 `hostAppRouter()` 可能拿到 `nil`，把注册放在启动项里、业务跳转放在之后。

---

## 4. 网络

```swift
import IMBaseKit
import Moya
import ObjectMapper

enum ProfileRequest {
    case detail(userId: String)
}

extension ProfileRequest: IMCommonRequestTarget {
    var baseURL: URL { URL(string: IMEnvironmentManager.shared.environment.baseUrlString)! }
    var path: String { "/api/v1/user/profile" }
    var task: Task { .requestParameters(parameters: parameter ?? [:], encoding: JSONEncoding.default) }
    var parameter: [String: Any]? {
        switch self {
        case .detail(let userId): return ["userId": userId]
        }
    }
    var cache: CachePolicy { .netFirst }
    var showsDefaultAlertOnError: Bool { true }
}

class ProfileResponse: IMCommonResponse {
    var nickname: String?
    override func mapping(map: Map) {
        super.mapping(map: map)
        nickname <- map["data.nickname"]
    }
}

final class ProfileService {
    private let provider = IMCommonProvider<ProfileRequest>(with: [
        IMLoggerPlugin(configuration: .init(logOptions: .verbose)),
        IMStatusCodeAlertPlugin()
    ])

    func fetch(userId: String, completion: @escaping (ProfileResponse?) -> Void) {
        provider.request(.detail(userId: userId), convertible: ProfileResponse.self) { response in
            guard let response, response.isSuccess else {
                completion(nil)
                return
            }
            completion(response)
        }
    }
}
```

要点：

- `request` 成功失败都会回调。`isSuccess` 为 `code == 0 || code == 200`。`isCacheResponse == true` 表示这次是缓存。断网直接回缓存时返回的 `Cancellable?` 是 `nil`。
- 走网络时 completion 在主线程（Moya 默认队列）。断网直接回缓存或错误时，在调用线程同步回调。
- 默认 `method` 是 POST，默认 `cache` 是 `.noCache`。`.netFirst` 才在失败时回上一次成功响应。
- 上传、下载用 `provider.upload` / `provider.download`，回调是 Moya 的 `Result`。
- Token 失效不走 completion，而发通知：`.im.expiredToken`（40102，静默刷新）、`.im.invalidToken`（40100 / 40101 / 40103，登出）、`.im.invalidRefreshToken`（10103）。
- 全局错误弹窗由接入方实现 `IMNetworkErrorHandling`，赋给 `IMNetworkErrorCenter.shared.errorHandler`。这个属性是 `weak`，handler 必须自己被强持有（做成单例）。
- 超时：普通请求 15 秒；上传空闲 60 秒、总时长 300 秒；下载空闲 30 秒、总时长 300 秒。不能按单次请求改。

`allowsEnvironmentSwitch` 默认 false，此时 `switchToEnviroment` 直接返回，环境保持 `.release`。主工程在 DEBUG 或 ADHOC 把它设为 true。见 [§9](#9-国内--海外与编译标记)。

---

## 5. 缓存 / 钥匙串 / 沙盒

```swift
import IMBaseKit

IMCacheManager.shared.setBool(true, forKey: "onboarded")
let onboarded = IMCacheManager.shared.bool(forKey: "onboarded", defaultValue: false)

struct Draft: Codable { let id: String; let text: String }
IMCacheManager.shared.set(Draft(id: "1", text: "hi"), forKey: "draft")
let draft = IMCacheManager.shared.codable(of: Draft.self, forKey: "draft")

IMCacheManager.totalCacheSize { bytes in
    label.text = IMCacheManager.formatCacheSize(bytes)
}
IMCacheManager.clearAllCache {
    // 完成后发 .im.allCacheCleared
}

IMKeychainStore.shared.save(key: "lastAccount", value: "13800000000")
let account = IMKeychainStore.shared.load(key: "lastAccount")

let docs = IMSandBoxManager.documentPath()
```

`setString` / `setData` / `setDate` 传 `nil` 等于删除。`clearAllCache` 会清掉 MMKV 全部 key、`UserDefaults.standard` 全部 key、Kingfisher 图片、WKWebView 数据和 Caches 目录。需要跨清理保留的值放 `IMKeychainStore`。

密码和 token 不要放 UserDefaults，也不要放 MMKV。token 用 `IMUtils.set` 放内存，登录地区用钥匙串。

---

## 6. 多语言、地区与图片

静态库里没有 `.lproj` 和 `Assets.car`。CocoaPods 按 podspec 的 `resource_bundles` 生成 **`IMBaseKit.bundle`**，拷进 App。查找顺序：

1. 类所在 bundle 里的 `IMBaseKit.bundle`（动态框架会嵌在 framework 内）
2. 主 bundle 里的 `IMBaseKit.bundle`（静态链接时资源在这里）

```swift
titleLabel.text = IMLocalizedString("common_done", "完成")

let lang = IMLocalizedService.shared.languageService.selectedOption
IMLocalizedService.shared.languageService.updateSelection(to: .english)

let region = IMLocalizedService.shared.currentRegion   // .CN / .US
IMLocalizedService.shared.modifyCurrentRegion(.CN)     // 变化时发 .im.regionDidChange

if isRTL {
    stackView.semanticContentAttribute = .forceRightToLeft
}
```

现有文案只有 `zh-Hans` 和 `en`。`LanguageOption.arabic` 没有 `ar.lproj`，会退回英文。`Accept-Language` 用 `rawValue`（`zh-Hans` / `en` / `ar`），接口短码用 `parameter`（`zh` / `en` / `ar`）。

切换语言后 SDK 不发通知，接入方自己刷新界面。`IMLocalizedString` 不读宿主工程的 `Localizable.strings`。

`Assets.xcassets` 目前没有图片。只把 XCFramework 拖进工程、不带 podspec 资源包时，文案会一直落到兜底参数。

登录地区存在钥匙串，key 为 `im_account_login_region`。语言选项存在 MMKV。

---

## 7. 日志与崩溃

```swift
import IMBaseKit
import CocoaLumberjack

IMLogger.shared.enable = true
IMLogger.shared.logConsole("console when enable is true")
IMLogger.shared.logNet("GET /api ... 200")
IMLogger.shared.logTrack(.page, event: "tapPurchase", fields: ["sku": "C100"])
IMLogger.shared.logCrash("custom fatal")
```

| 方法 | 目录 | 控制台 |
|---|---|---|
| `logConsole` | 无 | `IMLogger.shared.enable == true` 时才显示，默认 false |
| `logNet` | `{IMLogsDirectory}/Network` | 跟随 `enable` |
| `logTrack` | `/Track` | 否 |
| `logCrash` | `/Crash` | 跟随 `enable`，并且同步写盘 |

`logConsole` 还会调用 `IMLogger.persistentSink`。宿主注入这个闭包后，Debug 和 Release 都会落盘。主工程只在 `#if DEBUG` 里把 `enable` 设为 true。

每类最多 2 个文件（当前文件加 1 个归档）、单文件 3 MB。`IMLogsDirectory` 是 CocoaLumberjack 默认目录（Library/Caches/Logs）。

`UIViewController` 的 `viewDidLoad` / `viewWillAppear` / `viewDidAppear` / `viewWillDisappear` / `viewDidDisappear` / `dealloc` 会在 `+load` 时 swizzle，写入 `/Track`。系统库里的控制器会跳过。

静态库按 Release 打包时，库内 `#if DEBUG` 分支不在包里。`logConsole` 本身还在，控制台要宿主把 `enable` 设为 true。

---

## 8. 路由

业务侧只依赖 URL，不 import 目标页面所在模块。

```swift
openRouter(IMRouterURL.accountSecurity)
openRouter(IMRouterURL.searchDevice, params: [IMRouterParamKey.deviceType: "C100"])
openRouter(IMRouterURL.innerWeb, params: [IMRouterParamKey.url: "https://example.com/help"])
```

宿主必须实现并注册 `IMHostAppRouterServiceProtocol`，否则 `host` 为 `hostApp` 的 URL 没有跳转：

```swift
@objc final class MyHostAppRouterService: NSObject, IMHostAppRouterServiceProtocol {
    required override init() {}
    static var seriverName: String { String(describing: MyHostAppRouterService.self) }

    func toAccountSecurity(_ params: [String: Any]?, completion: ComplateHandler) {
        DispatchQueue.main.async {
            let vc = AccountSecurityViewController()
            currentNavigationController()?.pushViewController(vc, animated: true)
            completion?(nil, vc)
        }
    }
    // 协议里其余 toXxx 一并实现
}

TheRouter.registerService(MyHostAppRouterService.self, instance: MyHostAppRouterService())
```

`openRouter` 同时分发 `accountKit`。`IMRouterURL.regionSelect` 是 `inmox://accountKit/regionSelect`，`IMRouterURL.unregisterAccount` 是 `inmox://accountKit/unregisterAccount`。这两条交给已注册的 `IMAccountKitRouterServiceProtocol`（`toRegionSelect` / `toUnregisterAccount`）。注销账号不再走 `IMHostAppRouterServiceProtocol`。账号与安全仍是 `inmox://hostApp/accountSecurity`。

R2 也走 `hostApp`：`inmox://hostApp/r2DeviceSetting`、`r2NewbieGuide`、`r2ModifyGlassName`、`r2AboutGlass`，对应 `toR2DeviceSetting`、`toR2NewbieGuide`、`toR2ModifyGlassName`、`toR2AboutGlass`。前两个返回 `Bool`。

`TheRouter.push` / `modal` / `popToRootVC` / `visibleVC` / `getKeyWindow` 不走 URL。`currentViewController()` 和 `UIWindow.im.currentWindow` 只在主线程有值。

---

## 9. 国内 / 海外与编译标记

`IMBuildRegion` 看主工程 bundle id，不看编译标记，也没有 `current`、`identifier`、`configure()`。

| bundle id | `AppType` | `isDomestic` | `isGlobal` |
|---|---|---|---|
| `com.inmox.next` | `.INMO_Moment` | true | false |
| `com.inmox.next.global` | `.INMO_R_Global` | false | true |
| 其它 | `.unknown` | false | false |

`.INMO_R` 和 `.INMO_Moment_Global` 的 id 目前是空字符串，真实 bundle id 不会匹配它们。对不上时两个属性都是 false。

```swift
if IMBuildRegion.isGlobal {
    // 当前 App bundle id 是海外包
}
```

`#if INMOX_DOMESTIC` / `#if INMOX_GLOBAL` 是另一条路。`./Scripts/build_xcframeworks.sh` 默认把 `INMOX_DOMESTIC` 编进静态库，`REGION=global` 则编进 `INMOX_GLOBAL`。这个标记只影响库里的 `#if`。当前 `IMBuildRegion.swift` 不读它，换包不会改变 `isDomestic` / `isGlobal`。

`#if DEBUG` 和 `#if ADHOC` 也在打包时决定。脚本打的是 Release，库内这两支代码不在包里。控制台和切环境不靠这两支：分别看运行时的 `IMLogger.shared.enable`（默认 false）和 `IMEnvironmentManager.shared.allowsEnvironmentSwitch`（默认 false，为 false 时 `switchToEnviroment` 直接返回）。源码 pod 仍由主工程 `Podfile` 的 `post_install` 注入编译标记；主工程自己在 DEBUG 打开日志、在 DEBUG 或 ADHOC 打开环境切换。

---

## 10. 系统权限

```swift
let auth = IMSystemAuthManager()
auth.isAvailable(for: .bluetooth) { available, error in
    // 调用期间保持 auth 的强引用，蓝牙 / 定位回调依赖内部 manager
}
```

`AuthType`：`.bluetooth`、`.camera`、`.album`、`.addImage`、`.microphone`、`.location`、`.cellular`、`.apns`。

用途文案写在宿主 Info.plist（蓝牙、相机、相册、麦克风、定位等）。框架隐私清单不代替这些 key。见 [PRIVACY.md](PRIVACY.md)。

---

## 11. 常见问题

**`IMLocalizedString` 总是返回兜底文案？**  
确认 App 包里有 `IMBaseKit.bundle`，且里面有 `zh-Hans.lproj` / `en.lproj`。只链 XCFramework、没走 podspec 的 `resource_bundles` 时不会有这个 bundle。宿主自己的 strings 文件不会被读。

**请求头没有 `Authorization`？**  
登录成功后调用 `IMUtils.set(uid:token:)`。token 为空时不加这个头。

**`clearAllCache` 把我的 UserDefaults 也清了？**  
会清 `UserDefaults.standard` 的全部 key。要保留的放钥匙串，或监听 `.im.allCacheCleared` 后重建。

**Release 包看不到控制台日志，也切不了环境？**  
把 `IMLogger.shared.enable` 和 `IMEnvironmentManager.shared.allowsEnvironmentSwitch` 设为 true。二者默认都是 false。静态库按 Release 打包时，库内部的 `#if DEBUG` / `#if ADHOC` 不在包里。

**页面路由没反应？**  
宿主已实现并 `TheRouter.registerService` 了对应协议；scheme 必须是 `inmox`。`openRouter` 分发 `hostApp`、`uiKit`、`accountKit`。地区选择和注销账号要注册 `IMAccountKitRouterServiceProtocol`。

**为什么业务文件还要 `import Moya`？**  
`IMCommonRequestTarget` 继承 `Moya.TargetType`，响应模型继承 ObjectMapper 的 `Mappable`。这些库由宿主链接，不在 IMBaseKit 二进制里。

---

# 公开 API 参考

> Part B：符号一览。场景细节见 Part A。扩展方法都在 `im` 命名空间下，这里不逐条列出。

## Base

| 符号 | 说明 |
|---|---|
| `IMKit` / `IMKitCompatible` | `xxx.im.` 命名空间 |
| `IMLaunchManager.shared` | 按 key 执行启动项 |
| `IMLaunchKey.sdk` | `"SDK"`，对应 Mach-O 段 `__SDK` |
| `launch(forKey:)` | 依次跑 Mach-O 导出、`IMLaunchRegistrant` 扫描、内存注册表 |
| `IMLaunchRegistrant` | SDK 自注册协议；`imLaunchKey` / `imLaunchName` / `imLaunchExecute` |
| `IMLaunchItem.register` | 宿主闭包注册 |
| `IMLaunchItemToken` | 文件级 token 注册 |
| `IMLaunchItemLogger` | 观察启动项执行顺序 |
| `IM_FUNCTION_EXPORT` | ObjC 宏，把函数写入 `__<key>` 段 |
| `IMBuildRegion` | `isDomestic` / `isGlobal`，按主 bundle 的 `AppType` 判断 |
| `IMSystemAuthManager` | 系统权限查询与申请 |
| `AuthType` / `AuthStatus` | 权限种类与授权结果 |
| `IMUtils.set(uid:token:)` | 注入内存中的用户 id 与 access token |
| `IMUtils.setPushToken` | 注入推送 token |
| `isJailbroken()` / `exitApp()` | 越狱检测、退出进程 |
| `AppType` | 按 bundle id 识别 Moment / R 的国内与海外包 |
| `Bundle.im` | `appName` / `appVersion` / `bundleIdentifier` 等，读的是主 bundle |
| `BlockTap` / `BlockPan` / `BlockLongPress` / `BlockPinch` / `BlockSwipe` | 闭包手势 |
| `currentViewController()` / `currentNavigationController()` | 仅主线程有值 |

## Cache

| 符号 | 说明 |
|---|---|
| `IMCacheManager.shared` | MMKV 键值缓存 |
| `set` / `codable` / `codableArray` | Codable 读写 |
| `setBool` / `setString` / `setData` / `setDate` | 基础类型；`nil` 等于删除 |
| `totalCacheSize` / `formatCacheSize` / `clearAllCache` | 体积与一键清理 |
| `migrateFromUserDefaults` / `migrateAllUserDefaults` | 从 UserDefaults 迁到 MMKV |
| `.im.allCacheCleared` | `clearAllCache` 完成后的通知 |
| `IMKeychainStore.shared` | 以 bundle id 为 service 的钥匙串 |
| `IMSandBoxManager` | Documents / Caches / tmp / Database 路径与文件大小 |

## Cryptor

| 符号 | 说明 |
|---|---|
| `IMAESCryptor` | AES128-ECB-PKCS7，返回 Base64 或 Data |
| `Data.aesEncrypt` / `aesDecrypt` | CBC，自定义 key / iv |
| `md5()` / `sha256()` | `Data` 与 `String` |
| `Data.random` / `randomIV` / `randomKey` | 随机字节 |

## Localized

| 符号 | 说明 |
|---|---|
| `IMLocalizedString(_:_:)` | 在 `IMBaseKit.bundle` 查表，第二个参数为兜底 |
| `IMLanguageService` / `LanguageOption` | 当前语言与切换；`.simplifiedChinese` / `.english` / `.arabic` |
| `IMLocalizedService` | 语言服务 + 登录地区 |
| `RegionOption` | `.CN` / `.US`；`name` / `code` |
| `modifyCurrentRegion` | 写入钥匙串；变化时发 `.im.regionDidChange` |
| `isRTL` | 当前语言为阿拉伯语时为 true |

## Logger / Crasher

| 符号 | 说明 |
|---|---|
| `IMLogger.shared` | 日志入口 |
| `logConsole` / `logNet` / `logTrack` / `logCrash` | 控制台、网络、行为、崩溃 |
| `IMTrackLogCategory` | `.app` / `.page` |
| `IMLogType` / `IMLogsDirectory` | 自定义文件日志类别与根目录 |
| `addFileLog` / `emitLog` | 追加一类文件日志 |
| `IMCrasher.registerCrashHandler()` | 注册未捕获异常与信号处理器 |

## Network

| 符号 | 说明 |
|---|---|
| `IMCommonProvider` | 统一请求；`request` / `upload` / `download` |
| `IMNetworkProvider` | 按档位构造 Moya provider |
| `IMCommonRequestTarget` | 请求描述；默认 POST、公共头、`cache`、`showsDefaultAlertOnError`、`showLoading` |
| `CachePolicy` | `.noCache` / `.netFirst` |
| `IMCommonResponse` | `code` / `message` / `isSuccess` / `isCacheResponse` |
| `IMNetworkListener.shared` | `start` / `stop` / `isConnected` / `isReachable` |
| `.im.connectivityChanged` | 连通性变化，后台队列发出 |
| `IMEnvironmentManager` | 测试 / 正式环境与 BaseURL |
| `IMNetworkErrorHandling` / `IMNetworkErrorCenter` | 全局错误钩子，`errorHandler` 为 weak |
| `IMStatusCodeAlertPlugin` | 把错误交给 `IMNetworkErrorCenter` |
| `IMLoggerPlugin` | 请求 / 响应日志 |
| `.im.expiredToken` / `.im.invalidToken` / `.im.invalidRefreshToken` | Token 失效通知 |

## Router

| 符号 | 说明 |
|---|---|
| `openRouter` | 只接受 `inmox://`，按 host 分发 `hostApp` / `uiKit` / `accountKit` |
| `IMRouterScheme` / `IMRouterHost` / `IMRouterPath` | scheme、host、path 常量 |
| `IMRouterURL` | 拼好的完整 URL。`regionSelect`、`unregisterAccount` 的 host 是 `accountKit` |
| `IMRouterParamKey` | 参数 key，如 `deviceType` / `url` / `title` |
| `IMHostAppRouterServiceProtocol` / `hostAppRouter()` | 宿主页面跳转。含 R2 设置、指引、改名、关于眼镜。不含注销账号 |
| `IMAccountKitRouterServiceProtocol` / `accountKitRouter()` | 地区选择、注销账号 |
| `IMUIKitRouterServiceProtocol` / `uikitRouter()` | 网页 / 扫码，由 IMUIKit 实现 |
| `TheRouter.registerService` | 注册服务；异步写入 |
| `TheRouter.push` / `modal` / `visibleVC` | 与 URL 无关的导航工具 |
| `ComplateHandler` | `(([String: Any]?, Any?) -> Void)?` |
