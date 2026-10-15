# Privacy（IMBaseKit）

框架自带的隐私清单，以及宿主 App 仍需自己配置的部分。

## 隐私清单（`PrivacyInfo.xcprivacy`）

源码路径：`IMBaseKit/Resources/PrivacyInfo.xcprivacy`。

| Key | 取值 |
|-----|------|
| `NSPrivacyTracking` | `false`。框架不做跨 App / 网站追踪。 |
| `NSPrivacyTrackingDomains` | 空。 |
| `NSPrivacyCollectedDataTypes` | `NSPrivacyCollectedDataTypeOtherDiagnosticData`：崩溃与行为日志写在本机，关联用户、不用于追踪，目的是 App 功能。 |
| `NSPrivacyAccessedAPITypes` | 见下表。 |

| API | 原因码 | 代码里的用途 |
|-----|--------|----------------|
| UserDefaults | `C56D.1` | 第三方 SDK 封装。仅当宿主调用 `IMCacheManager.clearAllCache` / `clearUserDefaults` / `migrateFromUserDefaults` / `migrateAllUserDefaults` 时读写 `UserDefaults.standard`。不把这份数据用于 SDK 自身目的，也不外传。 |
| File timestamp | `C617.1` | `IMSandBoxManager.fileSize` 与缓存体积统计通过 `FileManager.attributesOfItem` 读取 App 容器（Caches / tmp）内文件大小。 |

## 二进制消费者拿到清单的两个位置

1. **每个 XCFramework 切片内**：`IMBaseKit.framework/PrivacyInfo.xcprivacy`。Xcode / App Store 聚合隐私报告时会读它。
2. **CocoaPods resource bundle** `IMBaseKit.bundle`：静态链接不会把 framework 目录嵌进 App，清单还放在 `IMBaseKit` 资源包根目录，随 `[CP] Copy Pods Resources` 进包。源码 pod 与 `IMBaseKitBinary.podspec` 都是这个 bundle 名。`IMLocalizedString` 也只在这个 bundle 里查表，不要改名。

## 宿主仍需自己声明的权限

`IMSystemAuthManager` 会查询蓝牙、相机、相册、麦克风、定位、蜂窝网络和推送。对应的用途文案（`NSBluetoothAlwaysUsageDescription`、`NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`、`NSMicrophoneUsageDescription`、`NSLocationWhenInUseUsageDescription` 等）写在宿主 Info.plist，不由本框架清单代替。

第三方库（Moya、MMKV、Kingfisher 等）各自的隐私清单随它们自己的 pod 进包，不打进 IMBaseKit。
