//
//  SceneDelegate.swift
//  IMBaseKit Example
//
//  当前 SDK 要求 UIScene 生命周期。窗口在这里创建，进程级初始化仍在 AppDelegate。
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let root = storyboard.instantiateInitialViewController() ?? ViewController()
        if root is UINavigationController {
            window.rootViewController = root
        } else {
            window.rootViewController = UINavigationController(rootViewController: root)
        }
        window.makeKeyAndVisible()
        self.window = window
    }
}
