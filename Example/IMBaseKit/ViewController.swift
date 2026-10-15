//
//  ViewController.swift
//  IMBaseKit Example
//

import UIKit

final class ViewController: UIViewController {
    private let viewModel = IMExampleMenuViewModel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "IMBaseKit"
        view.backgroundColor = .systemGroupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func run(_ action: IMExampleAction) {
        let work = { [weak self] in
            action.perform { message in
                DispatchQueue.main.async {
                    self?.presentResult(title: action.title, message: message, presents: action.presentsResult)
                }
            }
        }
        guard action.confirms else {
            work()
            return
        }
        let alert = UIAlertController(title: action.title,
                                      message: "会清掉 MMKV 和 UserDefaults.standard 的全部 key。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "继续", style: .destructive) { _ in work() })
        present(alert, animated: true)
    }

    private func presentResult(title: String, message: String, presents: Bool) {
        guard presents else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].actions.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = viewModel.sections[indexPath.section].actions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "action")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "action")
        var content = cell.defaultContentConfiguration()
        content.text = action.title
        content.secondaryText = action.detail
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        run(viewModel.sections[indexPath.section].actions[indexPath.row])
    }
}
