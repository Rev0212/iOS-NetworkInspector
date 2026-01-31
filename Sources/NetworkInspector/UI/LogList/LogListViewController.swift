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
    private var filteredLogs: [NetworkLog] = []
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Network Logs"
        view.backgroundColor = .systemBackground

        setupNavigationItems()
        setupSearch()
        setupTableView()
        loadLogs()
        observeLogs()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension LogListViewController {

    func setupNavigationItems() {
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearAllLogs)
        )
    }

    var isSearching: Bool {
        searchController.isActive && !(searchController.searchBar.text ?? "").isEmpty
    }

    var visibleLogs: [NetworkLog] {
        isSearching ? filteredLogs : logs
    }

    func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search URL, method, status"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

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
        applySearchFilter()
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
        visibleLogs.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: LogCell.reuseIdentifier,
            for: indexPath
        ) as! LogCell

        cell.configure(with: visibleLogs[indexPath.row])
        return cell
    }
}

extension LogListViewController: UITableViewDelegate {

//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           tableView.deselectRow(at: indexPath, animated: true)

           let log = visibleLogs[indexPath.row]
           let detailVC = LogDetailViewController(log: log)
           navigationController?.pushViewController(detailVC, animated: true)
       }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let log = visibleLogs[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteLog(withId: log.id)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension LogListViewController {

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
}

extension LogListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        applySearchFilter()
        tableView.reloadData()
    }
}

private extension LogListViewController {

    func applySearchFilter() {
        guard isSearching else {
            filteredLogs = []
            return
        }

        let query = (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !query.isEmpty else {
            filteredLogs = []
            return
        }

        filteredLogs = logs.filter { log in
            let urlText = log.request.url?.absoluteString.lowercased() ?? ""
            let methodText = log.request.method.rawValue.lowercased()
            let statusText = log.response.statusCode.map(String.init) ?? ""
            return urlText.contains(query)
                || methodText.contains(query)
                || statusText.contains(query)
        }
    }

    func deleteLog(withId id: UUID) {
        NetworkLogStore.shared.remove(id: id)
        logs.removeAll { $0.id == id }
        filteredLogs.removeAll { $0.id == id }
        tableView.reloadData()
    }

    @objc
    func clearAllLogs() {
        let alert = UIAlertController(
            title: "Clear All Logs?",
            message: "This will remove all captured network logs.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            NetworkLogStore.shared.clear()
            self?.logs = []
            self?.filteredLogs = []
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }
}

