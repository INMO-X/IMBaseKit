//
//  IMExampleLaunch.swift
//  IMBaseKit Example
//
//  docs/USAGE.md §3 启动项、§4 全局错误处理。
//

import Foundation
import IMBaseKit

@objcMembers
final class IMExampleSDKLaunch: NSObject, IMLaunchRegistrant {
    var imLaunchKey: String { IMLaunchKey.sdk }
    var imLaunchName: String { "ExampleSDK" }

    func imLaunchExecute() {
        TheRouter.registerService(IMExampleHostRouter.self, instance: IMExampleHostRouter())
    }
}

final class IMExampleLaunchLog: IMLaunchItemLogger {
    static let shared = IMExampleLaunchLog()

    private(set) var names: [String] = []
    private(set) var closureDidRun = false

    func willExecuteFunction(_ name: String, forKey key: String) {
        names.append("\(key)/\(name)")
    }

    func markClosureRegistered() {
        closureDidRun = true
    }
}

/// `IMNetworkErrorCenter.errorHandler` 是 weak，必须由单例强持有。
final class IMExampleErrorHandler: IMNetworkErrorHandling {
    static let shared = IMExampleErrorHandler()

    private(set) var lastStatusCode: Int?

    func reset() {
        lastStatusCode = nil
    }

    func handle(statusCode: Int, request: URLRequest?, data: Data?) -> Bool {
        lastStatusCode = statusCode
        return true
    }
}
