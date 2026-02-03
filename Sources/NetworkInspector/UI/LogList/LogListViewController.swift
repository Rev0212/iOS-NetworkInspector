//
//  LogListViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class LogListViewController: UIViewController {

    private let headerContainer = UIView()
    private let tableView = UITableView()
    private let filterToggle = UISegmentedControl(items: ["All", "Selected"])
    private let baseLabel = UILabel()
    private var selectBaseItem: UIBarButtonItem?
    private var filterHeaderView: UIView?
    private var tableViewTopConstraint: NSLayoutConstraint?

    private let baseFilter: ((NetworkLog) -> Bool)?
    private let customTitle: String?
    private let configuredBaseURLs = NetworkInterceptor.getAllowedBaseURLs()
    private var selectedBaseURLs = Set<String>()

    private var logs: [NetworkLog] = []
    private var filteredLogs: [NetworkLog] = []
    private let searchController = UISearchController(searchResultsController: nil)

    init(filter: ((NetworkLog) -> Bool)? = nil, title: String? = nil) {
        self.baseFilter = filter
        self.customTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = customTitle ?? "Network Logs"
        view.backgroundColor = .systemBackground

        setupNavigationItems()
        setupFilterHeader()
        setupSearch()
        setupTableView()
        updateFilterUI()
        loadLogs()
        observeLogs()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension LogListViewController {

    func setupNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearAllLogs)
        )

        guard !configuredBaseURLs.isEmpty, baseFilter == nil else { return }

        selectBaseItem = UIBarButtonItem(
            title: "Select Base",
            style: .plain,
            target: self,
            action: #selector(showBaseSelection)
        )
        navigationItem.leftBarButtonItem = selectBaseItem
    }

    func setupFilterHeader() {
        guard !configuredBaseURLs.isEmpty, baseFilter == nil else {
            return
        }

        selectedBaseURLs = Set(configuredBaseURLs)

        filterToggle.selectedSegmentIndex = 0
        filterToggle.addTarget(self, action: #selector(onFilterToggleChanged), for: .valueChanged)

        baseLabel.font = .systemFont(ofSize: 12)
        baseLabel.textColor = .secondaryLabel
        baseLabel.numberOfLines = 0
        baseLabel.lineBreakMode = .byWordWrapping
        baseLabel.text = "Bases: \(configuredBaseURLs.joined(separator: ", "))"
        baseLabel.translatesAutoresizingMaskIntoConstraints = false
        baseLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true

        let header = UIStackView(arrangedSubviews: [filterToggle, baseLabel])
        header.axis = .vertical
        header.spacing = 8
        header.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        header.isLayoutMarginsRelativeArrangement = true

        headerContainer.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            header.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            header.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor)
        ])

        if headerContainer.superview == nil {
            headerContainer.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(headerContainer)

            NSLayoutConstraint.activate([
                headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }

        filterHeaderView = headerContainer

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

        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
        NSLayoutConstraint.activate([
            tableViewTopConstraint!,
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
        if let baseFilter {
            logs = logs.filter(baseFilter)
        }
        logs = applyBaseFilterIfNeeded(to: logs)
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

extension LogListViewController {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let header = filterHeaderView else { return }
        if header.bounds.width != view.bounds.width {
            header.bounds.size.width = view.bounds.width
        }
    }
}

extension LogListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

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

    func applyBaseFilterIfNeeded(to logs: [NetworkLog]) -> [NetworkLog] {
        guard baseFilter == nil else { return logs }
        guard filterToggle.selectedSegmentIndex == 1 else { return logs }
        guard !selectedBaseURLs.isEmpty else { return [] }

        return logs.filter { log in
            let urlText = log.request.url?.absoluteString.lowercased() ?? ""
            return selectedBaseURLs.contains { urlText.hasPrefix($0) }
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
        let isSelectedMode = filterToggle.selectedSegmentIndex == 1 && baseFilter == nil
        let shouldFilter = isSelectedMode

        let title = shouldFilter ? "Clear Selected Bases?" : "Clear All Logs?"
        let message = shouldFilter
            ? "This will remove logs only for the selected base URLs."
            : "This will remove all captured network logs."

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            guard let self else { return }

            if shouldFilter {
                let selected = self.selectedBaseURLs
                if !selected.isEmpty {
                    NetworkLogStore.shared.remove { log in
                        let urlText = log.request.url?.absoluteString.lowercased() ?? ""
                        return selected.contains { urlText.hasPrefix($0) }
                    }
                }
            } else {
                NetworkLogStore.shared.clear()
            }

            self.logs = []
            self.filteredLogs = []
            self.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    @objc
    func onFilterToggleChanged() {
        updateFilterUI()
        loadLogs()
    }

    @objc
    func showBaseSelection() {
        let alert = UIAlertController(
            title: "Select Base URLs",
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Select All", style: .default) { [weak self] _ in
            guard let self else { return }
            self.selectedBaseURLs = Set(self.configuredBaseURLs)
            self.updateBaseLabel()
            self.loadLogs()
        })

        alert.addAction(UIAlertAction(title: "Clear Selection", style: .destructive) { [weak self] _ in
            self?.selectedBaseURLs.removeAll()
            self?.updateBaseLabel()
            self?.loadLogs()
        })

        for base in configuredBaseURLs {
            let isSelected = selectedBaseURLs.contains(base)
            let title = isSelected ? "✓ \(base)" : base
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                if self.selectedBaseURLs.contains(base) {
                    self.selectedBaseURLs.remove(base)
                } else {
                    self.selectedBaseURLs.insert(base)
                }
                self.updateBaseLabel()
                self.loadLogs()
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = selectBaseItem
        }

        present(alert, animated: true)
    }

    func updateBaseLabel() {
        if selectedBaseURLs.isEmpty {
            baseLabel.text = "Bases: none selected"
        } else {
            let list = configuredBaseURLs.filter { selectedBaseURLs.contains($0) }
            baseLabel.text = "Bases: \(list.joined(separator: ", "))"
        }
    }

    func updateFilterUI() {
        let showSelection = filterToggle.selectedSegmentIndex == 1
        baseLabel.alpha = showSelection ? 1 : 0
        navigationItem.leftBarButtonItem = showSelection ? selectBaseItem : nil
        if showSelection {
            updateBaseLabel()
        } else {
            baseLabel.text = "Bases: "
        }
        if let header = filterHeaderView {
            let shouldShowHeader = !configuredBaseURLs.isEmpty && baseFilter == nil
            if shouldShowHeader, header.superview == view {
                tableViewTopConstraint?.isActive = false
                tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: header.bottomAnchor)
                tableViewTopConstraint?.isActive = true
            } else {
                tableViewTopConstraint?.isActive = false
                tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
                tableViewTopConstraint?.isActive = true
            }
            header.isHidden = !shouldShowHeader
        }

        filterHeaderView?.setNeedsLayout()
        filterHeaderView?.layoutIfNeeded()
    }
}

