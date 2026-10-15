//
//  AppDelegate.swift
//  IMBaseKit Example
//
//  启动顺序与 docs/USAGE.md §2 一致。
//

import UIKit
import IMBaseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IMCrasher.registerCrashHandler()
        IMLogger.shared.logTrack(.app, event: "didFinishLaunching")
        IMNetworkListener.shared.start()
        IMUtils.set(uid: "example-user", token: "example-token")
        IMNetworkErrorCenter.shared.errorHandler = IMExampleErrorHandler.shared

        IMLaunchManager.shared.setLogger(IMExampleLaunchLog.shared)
        IMLaunchItem.register(key: IMLaunchKey.sdk, name: "ExampleAnalytics") {
            IMExampleLaunchLog.shared.markClosureRegistered()
        }
        IMLaunchManager.shared.launch(forKey: IMLaunchKey.sdk)

        if let root = window?.rootViewController, !(root is UINavigationController) {
            window?.rootViewController = UINavigationController(rootViewController: root)
        }
        return true
    }
}
