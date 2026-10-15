//
//  IMExampleRouter.swift
//  IMBaseKit Example
//
//  docs/USAGE.md §8。openRouter 只分发 hostApp / uiKit。
//

import UIKit
import IMBaseKit

@objc final class IMExampleHostRouter: NSObject, IMHostAppRouterServiceProtocol {
    required override init() {}

    static var seriverName: String { String(describing: IMExampleHostRouter.self) }

    func toAccountSecurity(_ params: [String: Any]?, completion: ComplateHandler) {
        push(title: "账号与安全", params: params, completion: completion)
    }

    func toSearchDevice(_ params: [String: Any]?, completion: ComplateHandler) {
        let deviceType = params?[IMRouterParamKey.deviceType] as? String ?? ""
        push(title: "搜索设备 \(deviceType)", params: params, completion: completion)
    }

    private func push(title: String, params: [String: Any]?, completion: ComplateHandler) {
        DispatchQueue.main.async {
            let page = IMExampleRoutedViewController(pageTitle: title, params: params)
            currentNavigationController()?.pushViewController(page, animated: true)
            completion?(params, page)
        }
    }
}

final class IMExampleRoutedViewController: UIViewController {
    private let pageTitle: String
    private let params: [String: Any]?

    init(pageTitle: String, params: [String: Any]?) {
        self.pageTitle = pageTitle
        self.params = params
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .body)
        let pairs = (params ?? [:]).map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "\n")
        label.text = pairs.isEmpty ? "宿主路由已打开，没有附加参数。" : pairs
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }
}
