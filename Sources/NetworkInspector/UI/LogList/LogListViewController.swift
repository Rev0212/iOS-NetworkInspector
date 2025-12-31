//
//  LogListViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class LogListViewController: UIViewController {

    private let tableView = UITableView()

    private var logs: [NetworkLog] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Network Logs"
        view.backgroundColor = .systemBackground

        setupTableView()
        loadLogs()
        observeLogs()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension LogListViewController {

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

        tableView.register(
            LogCell.self,
            forCellReuseIdentifier: LogCell.reuseIdentifier
        )
    }
}

private extension LogListViewController {

    func loadLogs() {
        logs = NetworkLogStore.shared.getAllLogs()
        tableView.reloadData()
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
        loadLogs()
    }
}

extension LogListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logs.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: LogCell.reuseIdentifier,
            for: indexPath
        ) as! LogCell

        cell.configure(with: logs[indexPath.row])
        return cell
    }
}

extension LogListViewController: UITableViewDelegate {

//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           tableView.deselectRow(at: indexPath, animated: true)

           let log = logs[indexPath.row]
           let detailVC = LogDetailViewController(log: log)
           navigationController?.pushViewController(detailVC, animated: true)
       }
}

