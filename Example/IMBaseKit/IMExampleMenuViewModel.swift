//
//  IMExampleMenuViewModel.swift
//  IMBaseKit Example
//
//  列表项与 docs/USAGE.md Part A 的场景一一对应。
//

import Foundation
import IMBaseKit

struct IMExampleAction {
    let title: String
    let detail: String
    /// 打开页面本身就是结果时不再叠一层弹窗。
    let presentsResult: Bool
    let confirms: Bool
    let perform: (@escaping (String) -> Void) -> Void
}

struct IMExampleSection {
    let title: String
    let actions: [IMExampleAction]
}

final class IMExampleMenuViewModel {
    private let profile = IMExampleProfileService()
    private let auth = IMSystemAuthManager()
    private(set) var sections: [IMExampleSection] = []

    init() {
        sections = makeSections()
    }

    private func makeSections() -> [IMExampleSection] {
        [
            IMExampleSection(title: "2 启动", actions: [
                IMExampleAction(title: "查看启动结果", detail: "崩溃收集、网络监听、身份、启动项", presentsResult: true, confirms: false) { done in
                    done(Self.startupSummary())
                }
            ]),
            IMExampleSection(title: "2 身份", actions: [
                IMExampleAction(title: "写入示例 token", detail: "IMUtils.set(uid:token:)", presentsResult: true, confirms: false) { done in
                    IMUtils.set(uid: "example-user", token: "example-token")
                    done("已写入内存。token 非空时，后续请求头带 Authorization: Bearer example-token。")
                },
                IMExampleAction(title: "清空 token", detail: "退出登录传 nil", presentsResult: true, confirms: false) { done in
                    IMUtils.set(uid: nil, token: nil)
                    done("已清空。token 为空时不加 Authorization。")
                }
            ]),
            IMExampleSection(title: "4 网络", actions: [
                IMExampleAction(title: "请求个人资料", detail: "IMCommonProvider + netFirst", presentsResult: true, confirms: false) { [weak self] done in
                    self?.fetchProfile(done: done)
                }
            ]),
            IMExampleSection(title: "5 缓存 / 钥匙串 / 沙盒", actions: [
                IMExampleAction(title: "写入并读回", detail: "Bool 与 Codable", presentsResult: true, confirms: false) { done in
                    done(Self.roundTripCache())
                },
                IMExampleAction(title: "缓存体积", detail: "totalCacheSize", presentsResult: true, confirms: false) { done in
                    IMCacheManager.totalCacheSize { bytes in
                        DispatchQueue.main.async {
                            done(IMCacheManager.formatCacheSize(bytes))
                        }
                    }
                },
                IMExampleAction(title: "清空全部缓存", detail: "会清 MMKV 和 UserDefaults", presentsResult: true, confirms: true) { done in
                    IMCacheManager.clearAllCache {
                        DispatchQueue.main.async {
                            done("已清空，并已发送 .im.allCacheCleared。语言选项也在 MMKV 里，需要重新选择。")
                        }
                    }
                },
                IMExampleAction(title: "钥匙串", detail: "IMKeychainStore", presentsResult: true, confirms: false) { done in
                    let key = "example.lastAccount"
                    _ = IMKeychainStore.shared.save(key: key, value: "13800000000")
                    let loaded = IMKeychainStore.shared.load(key: key) ?? "(空)"
                    done("save / load \(key) = \(loaded)")
                },
                IMExampleAction(title: "沙盒与摘要", detail: "Documents、SHA256", presentsResult: true, confirms: false) { done in
                    let docs = IMSandBoxManager.documentPath() ?? "(无)"
                    done("Documents\n\(docs)\nsha256(imbasekit) = \("imbasekit".sha256())")
                }
            ]),
            IMExampleSection(title: "6 多语言与地区", actions: [
                IMExampleAction(title: "切换语言", detail: "zh-Hans → en → ar", presentsResult: true, confirms: false) { done in
                    done(Self.cycleLanguage())
                },
                IMExampleAction(title: "切换地区", detail: "CN / US，写入钥匙串", presentsResult: true, confirms: false) { done in
                    let next: RegionOption = IMLocalizedService.shared.currentRegion == .CN ? .US : .CN
                    IMLocalizedService.shared.modifyCurrentRegion(next)
                    let region = IMLocalizedService.shared.currentRegion
                    done("\(region.rawValue) \(region.name) \(region.code)")
                }
            ]),
            IMExampleSection(title: "7 日志", actions: [
                IMExampleAction(title: "写四类日志", detail: "控制台 / 网络 / 行为 / 崩溃", presentsResult: true, confirms: false) { done in
                    done(Self.writeLogs())
                }
            ]),
            IMExampleSection(title: "8 路由", actions: [
                IMExampleAction(title: "账号与安全", detail: "inmox://hostApp/...", presentsResult: false, confirms: false) { done in
                    openRouter(IMRouterURL.accountSecurity)
                    done("已打开账号与安全")
                },
                IMExampleAction(title: "搜索设备", detail: "参数 deviceType=C100", presentsResult: false, confirms: false) { done in
                    openRouter(IMRouterURL.searchDevice, params: [IMRouterParamKey.deviceType: "C100"])
                    done("已打开搜索设备")
                },
                IMExampleAction(title: "地区选择", detail: "host 是 accountKit，openRouter 不处理", presentsResult: true, confirms: false) { done in
                    let opened = openRouter(IMRouterURL.regionSelect)
                    done(opened == nil ? "没有打开。这条 URL 要账号模块自己的入口。" : "意外打开了地区选择")
                }
            ]),
            IMExampleSection(title: "9 编译标记", actions: [
                IMExampleAction(title: "查看区域与标记", detail: "bundle id 决定 IMBuildRegion", presentsResult: true, confirms: false) { done in
                    done(Self.regionSummary())
                }
            ]),
            IMExampleSection(title: "10 系统权限", actions: [
                IMExampleAction(title: "查询可用性", detail: "相机、相册、麦克风、定位", presentsResult: true, confirms: false) { [weak self] done in
                    self?.queryAuth(done: done)
                }
            ])
        ]
    }

    private static func startupSummary() -> String {
        let log = IMExampleLaunchLog.shared
        let names = log.names.isEmpty ? "(没有扫到启动项)" : log.names.joined(separator: "\n")
        return [
            "网络已连接：\(IMNetworkListener.shared.isConnected)",
            "闭包启动项已执行：\(log.closureDidRun)",
            "启动项：",
            names,
            "日志目录：\(IMLogsDirectory)"
        ].joined(separator: "\n")
    }

    private func fetchProfile(done: @escaping (String) -> Void) {
        IMExampleErrorHandler.shared.reset()
        let connected = IMNetworkListener.shared.isConnected
        profile.fetch(userId: "example-user") { response in
            DispatchQueue.main.async {
                let code = response?.code.map(String.init) ?? "(无)"
                let message = response?.message ?? "(无)"
                let nickname = response?.nickname ?? "(无)"
                let handler = IMExampleErrorHandler.shared.lastStatusCode.map(String.init) ?? "(未回调)"
                done([
                    "发起时已连接：\(connected)",
                    "isSuccess：\(response?.isSuccess == true)",
                    "isCache：\(response?.isCacheResponse == true)",
                    "code：\(code)",
                    "message：\(message)",
                    "nickname：\(nickname)",
                    "错误处理 status：\(handler)"
                ].joined(separator: "\n"))
            }
        }
    }

    private static func roundTripCache() -> String {
        IMCacheManager.shared.setBool(true, forKey: "example.onboarded")
        let onboarded = IMCacheManager.shared.bool(forKey: "example.onboarded", defaultValue: false)
        let draft = IMExampleDraft(id: "1", text: "hi")
        _ = IMCacheManager.shared.set(draft, forKey: "example.draft")
        let loaded = IMCacheManager.shared.codable(of: IMExampleDraft.self, forKey: "example.draft")
        return "onboarded=\(onboarded)\ndraft=\(loaded?.id ?? "?") \(loaded?.text ?? "?")"
    }

    private static func cycleLanguage() -> String {
        let service = IMLocalizedService.shared.languageService
        let next: LanguageOption
        switch service.selectedOption {
        case .simplifiedChinese: next = .english
        case .english: next = .arabic
        case .arabic: next = .simplifiedChinese
        }
        service.updateSelection(to: next)
        let text = IMLocalizedString("common_done", "完成")
        return "当前 \(next.rawValue)，接口短码 \(next.parameter)\ncommon_done = \(text)\nisRTL = \(isRTL)"
    }

    private static func writeLogs() -> String {
        IMLogger.shared.logConsole("example console")
        IMLogger.shared.logNet("example GET /api 200")
        IMLogger.shared.logTrack(.page, event: "tapExample", fields: ["sku": "C100"])
        IMLogger.shared.logCrash("example non-fatal")
        let console: String
        #if DEBUG
        console = "DEBUG 构建会输出到控制台"
        #else
        console = "当前不是 DEBUG，logConsole 不进控制台"
        #endif
        return "\(console)\n文件在 \(IMLogsDirectory) 的 Network / Track / Crash"
    }

    private static func regionSummary() -> String {
        let flags = [
            Self.flag("DEBUG"),
            Self.flag("ADHOC"),
            Self.flag("INMOX_DOMESTIC"),
            Self.flag("INMOX_GLOBAL")
        ].joined(separator: " ")
        return [
            "bundle：\(Bundle.im.bundleIdentifier)",
            "AppType：\(Self.appTypeName(Bundle.im.appType))",
            "isDomestic：\(IMBuildRegion.isDomestic)",
            "isGlobal：\(IMBuildRegion.isGlobal)",
            "本 Target 编译条件：\(flags)",
            "Example 的 bundle id 是 com.inmox.next，用来演示 INMO_Moment。"
        ].joined(separator: "\n")
    }

    private static func flag(_ name: String) -> String {
        switch name {
        case "DEBUG":
            #if DEBUG
            return "DEBUG"
            #else
            return ""
            #endif
        case "ADHOC":
            #if ADHOC
            return "ADHOC"
            #else
            return ""
            #endif
        case "INMOX_DOMESTIC":
            #if INMOX_DOMESTIC
            return "INMOX_DOMESTIC"
            #else
            return ""
            #endif
        case "INMOX_GLOBAL":
            #if INMOX_GLOBAL
            return "INMOX_GLOBAL"
            #else
            return ""
            #endif
        default:
            return ""
        }
    }

    private static func appTypeName(_ type: AppType) -> String {
        switch type {
        case .INMO_Moment: return "INMO_Moment"
        case .INMO_Moment_Global: return "INMO_Moment_Global"
        case .INMO_R: return "INMO_R"
        case .INMO_R_Global: return "INMO_R_Global"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }

    private func queryAuth(done: @escaping (String) -> Void) {
        let group = DispatchGroup()
        var lines = [String](repeating: "", count: 4)
        let lock = NSLock()
        let types: [(Int, AuthType, String)] = [
            (0, .camera, "相机"),
            (1, .album, "相册"),
            (2, .microphone, "麦克风"),
            (3, .location, "定位")
        ]
        for item in types {
            group.enter()
            auth.isAvailable(for: item.1) { available, _ in
                lock.lock()
                lines[item.0] = "\(item.2)：\(available ? "可用" : "不可用")"
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) {
            done(lines.joined(separator: "\n") + "\n蓝牙和推送未在此查询，避免弹出系统授权。")
        }
    }
}

private struct IMExampleDraft: Codable {
    let id: String
    let text: String
}
