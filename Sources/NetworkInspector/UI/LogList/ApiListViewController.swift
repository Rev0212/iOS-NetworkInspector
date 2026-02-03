//
//  ApiListViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//

import UIKit

final class ApiListViewController: UIViewController {

    private let tableView = UITableView()
    private var items: [APIItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "APIs"
        view.backgroundColor = .systemBackground

        setupTableView()
        loadItems()
        observeLogs()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension ApiListViewController {

    func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
    }

    func observeLogs() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLogsUpdated),
            name: .networkLogStoreDidUpdate,
            object: nil
        )
    }

    @objc
    func onLogsUpdated() {
        loadItems()
    }

    func loadItems() {
        let logs = NetworkLogStore.shared.getAllLogs()
        items = buildItems(from: logs)
        tableView.reloadData()
    }

    func buildItems(from logs: [NetworkLog]) -> [APIItem] {
        var counts: [String: APIItem] = [:]

        for log in logs {
            let host = log.request.url?.host ?? "-"
            let path = endpointPath(from: log.request.url)
            let key = "\(host)|\(path)"

            if let existing = counts[key] {
                counts[key] = APIItem(host: host, path: path, count: existing.count + 1)
            } else {
                counts[key] = APIItem(host: host, path: path, count: 1)
            }
        }

        return counts.values.sorted { lhs, rhs in
            if lhs.host == rhs.host {
                return lhs.path < rhs.path
            }
            return lhs.host < rhs.host
        }
    }

    func endpointPath(from url: URL?) -> String {
        let path = url?.path ?? "/"
        if path == "/" || path.isEmpty {
            return "/"
        }
        return path.hasPrefix("/") ? String(path.dropFirst()) : path
    }
}

extension ApiListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ApiCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ApiCell")

        let item = items[indexPath.row]
        cell.textLabel?.text = item.path
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        cell.detailTextLabel?.text = "\(item.host) • \(item.count) calls"
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.selectionStyle = .none

        return cell
    }
}

extension ApiListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        let title = item.path == "/" ? item.host : item.path

        let filter: (NetworkLog) -> Bool = { log in
            let host = log.request.url?.host ?? "-"
            let path = self.endpointPath(from: log.request.url)
            return host == item.host && path == item.path
        }

        let detailVC = LogListViewController(filter: filter, title: title)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

private struct APIItem {
    let host: String
    let path: String
    let count: Int
}
