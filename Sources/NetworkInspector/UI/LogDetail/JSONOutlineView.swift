//
//  JSONOutlineView.swift
//  NetworkInspector
//

import UIKit

// MARK: - Model

indirect enum JSONNode {
    case object([(String, JSONNode)])
    case array([JSONNode])
    case primitive(NSAttributedString)
    case error(String)

    static func parse(from data: Data) -> JSONNode {
        guard let obj = try? JSONSerialization.jsonObject(
            with: data,
            options: [.fragmentsAllowed]
        ) else {
            let raw = String(decoding: data, as: UTF8.self)
            return .error(raw.isEmpty ? "Empty response" : raw)
        }
        return JSONNode.from(any: obj)
    }

    private static func from(any value: Any) -> JSONNode {
        if let dict = value as? [String: Any] {
            let sorted = dict.sorted { $0.key < $1.key }
            return .object(sorted.map { ($0.key, JSONNode.from(any: $0.value)) })
        }
        if let arr = value as? [Any] {
            return .array(arr.map { JSONNode.from(any: $0) })
        }
        if let str = value as? String {
            return .primitive(JSONStyle.stringValue(str))
        }
        if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return .primitive(JSONStyle.boolValue(num.boolValue))
            }
            return .primitive(JSONStyle.numberValue(num))
        }
        if value is NSNull {
            return .primitive(JSONStyle.nullValue())
        }
        return .primitive(JSONStyle.plain("\(value)"))
    }
}

// MARK: - Path / Row

private struct NodePath: Hashable {
    var components: [Int] = []

    func appending(_ index: Int) -> NodePath {
        var copy = self
        copy.components.append(index)
        return copy
    }
}

private enum RowKind {
    case openContainer(isObject: Bool, isExpanded: Bool, childCount: Int)
    case closeContainer(isObject: Bool)
    case primitive(NSAttributedString)
}

private struct OutlineRow {
    let path: NodePath
    let depth: Int
    let key: String?
    let kind: RowKind
    let trailingComma: Bool
    var matchesQuery: Bool = false
}

// MARK: - View

final class JSONOutlineView: UIView {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()
    private let matchCountLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let chevronStack = UIStackView()
    private let searchAccessory = SearchAccessoryView()
    private var root: JSONNode = .primitive(NSAttributedString(string: "—"))
    private var rows: [OutlineRow] = []
    private var collapsed: Set<NodePath> = []
    private var query: String = ""
    private var matchRowIndices: [Int] = []
    private var currentMatchOrdinal: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func load(data: Data?) {
        guard let data, !data.isEmpty else {
            root = .error("No response body")
            rebuildRows()
            return
        }
        root = JSONNode.parse(from: data)
        collapsed.removeAll()
        rebuildRows()
    }
}

// MARK: - Setup

private extension JSONOutlineView {

    func setupViews() {
        backgroundColor = .systemBackground

        searchBar.placeholder = "Search in response"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.returnKeyType = .next
        // Disable the built-in clear button; we provide our own inside the accessory
        // so it can sit alongside the chevron stack.
        searchBar.searchTextField.clearButtonMode = .never

        matchCountLabel.font = .systemFont(ofSize: 12)
        matchCountLabel.textColor = .secondaryLabel
        matchCountLabel.textAlignment = .right
        matchCountLabel.isHidden = true

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        prevButton.setImage(UIImage(systemName: "chevron.up", withConfiguration: chevronConfig), for: .normal)
        prevButton.addTarget(self, action: #selector(onPrev), for: .touchUpInside)
        prevButton.accessibilityLabel = "Previous match"
        nextButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: chevronConfig), for: .normal)
        nextButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        nextButton.accessibilityLabel = "Next match"
        for button in [prevButton, nextButton] {
            button.tintColor = .label
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        }

        let clearConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        clearButton.setImage(
            UIImage(systemName: "xmark.circle.fill", withConfiguration: clearConfig),
            for: .normal
        )
        clearButton.tintColor = .tertiaryLabel
        clearButton.addTarget(self, action: #selector(onClearText), for: .touchUpInside)
        clearButton.accessibilityLabel = "Clear search"
        clearButton.isHidden = true

        chevronStack.axis = .vertical
        chevronStack.alignment = .center
        chevronStack.distribution = .fillEqually
        chevronStack.spacing = 0
        chevronStack.addArrangedSubview(prevButton)
        chevronStack.addArrangedSubview(nextButton)
        chevronStack.isHidden = true

        clearButton.translatesAutoresizingMaskIntoConstraints = false
        chevronStack.translatesAutoresizingMaskIntoConstraints = false
        searchAccessory.addSubview(chevronStack)
        searchAccessory.addSubview(clearButton)
        NSLayoutConstraint.activate([
            clearButton.centerXAnchor.constraint(equalTo: searchAccessory.centerXAnchor),
            clearButton.centerYAnchor.constraint(equalTo: searchAccessory.centerYAnchor),
            chevronStack.centerXAnchor.constraint(equalTo: searchAccessory.centerXAnchor),
            chevronStack.centerYAnchor.constraint(equalTo: searchAccessory.centerYAnchor),
            chevronStack.topAnchor.constraint(equalTo: searchAccessory.topAnchor),
            chevronStack.bottomAnchor.constraint(equalTo: searchAccessory.bottomAnchor)
        ])

        // Reserve space on the right side of the text input so typed text doesn't
        // run under the overlay buttons. UISearchBar's internal rightView is
        // unreliable across iOS versions, so the visible accessory lives as an
        // overlay (added below) instead.
        let textPaddingSpacer = UIView()
        textPaddingSpacer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textPaddingSpacer.widthAnchor.constraint(equalToConstant: SearchAccessoryView.preferredSize.width),
            textPaddingSpacer.heightAnchor.constraint(equalToConstant: SearchAccessoryView.preferredSize.height)
        ])
        searchBar.searchTextField.rightView = textPaddingSpacer
        searchBar.searchTextField.rightViewMode = .always

        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(JSONOutlineCell.self, forCellReuseIdentifier: JSONOutlineCell.reuseId)
        tableView.estimatedRowHeight = 24
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        matchCountLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        searchAccessory.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchBar)
        addSubview(matchCountLabel)
        addSubview(tableView)
        addSubview(searchAccessory)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Overlay the accessory on top of the search bar's text input, on the right.
            searchAccessory.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchAccessory.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -18),

            matchCountLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 2),
            matchCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            matchCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: matchCountLabel.bottomAnchor, constant: 2),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc func onPrev() { advanceMatch(by: -1) }
    @objc func onNext() { advanceMatch(by: 1) }

    @objc func onClearText() {
        searchBar.text = ""
        self.searchBar(searchBar, textDidChange: "")
    }
}

// MARK: - Search

extension JSONOutlineView: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query = searchText
        // Expand everything while searching so all matches are visible.
        collapsed.removeAll()
        currentMatchOrdinal = 0
        rebuildRows()
        scrollToCurrentMatch()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        updateAccessoryVisibility()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        updateAccessoryVisibility()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        advanceMatch(by: 1)
    }
}

private extension JSONOutlineView {

    func nodeMatches(node: JSONNode, key: String?) -> Bool {
        guard !query.isEmpty else { return false }
        let q = query.lowercased()
        if let key, key.lowercased().contains(q) { return true }
        switch node {
        case .primitive(let attr):
            return attr.string.lowercased().contains(q)
        case .error(let message):
            return message.lowercased().contains(q)
        case .object, .array:
            return false
        }
    }

    func updateMatchIndices() {
        matchRowIndices = rows.enumerated()
            .filter { $0.element.matchesQuery }
            .map { $0.offset }

        updateAccessoryVisibility()

        if matchRowIndices.isEmpty {
            if query.isEmpty {
                matchCountLabel.isHidden = true
                matchCountLabel.text = nil
            } else {
                matchCountLabel.isHidden = false
                matchCountLabel.text = "No matches"
            }
        } else {
            if currentMatchOrdinal >= matchRowIndices.count { currentMatchOrdinal = 0 }
            matchCountLabel.isHidden = false
            matchCountLabel.text = "\(currentMatchOrdinal + 1) of \(matchRowIndices.count)"
        }
    }

    /// Focus state decides which accessory is shown inside the search field:
    /// - Editing/highlighted → just the X clear button (when there's text)
    /// - Not editing → vertical chevrons (when matches exist)
    func updateAccessoryVisibility() {
        let isFocused = searchBar.searchTextField.isFirstResponder
        clearButton.isHidden = !(isFocused && !query.isEmpty)
        chevronStack.isHidden = isFocused || matchRowIndices.isEmpty

        // Force the text field to re-layout its right view after visibility changes.
        searchBar.searchTextField.setNeedsLayout()
        searchBar.searchTextField.layoutIfNeeded()
    }

    func advanceMatch(by step: Int) {
        guard !matchRowIndices.isEmpty else { return }
        let count = matchRowIndices.count
        currentMatchOrdinal = ((currentMatchOrdinal + step) % count + count) % count
        matchCountLabel.isHidden = false
        matchCountLabel.text = "\(currentMatchOrdinal + 1) of \(matchRowIndices.count)"
        tableView.reloadData()
        scrollToCurrentMatch()
    }

    func scrollToCurrentMatch() {
        guard !matchRowIndices.isEmpty, currentMatchOrdinal < matchRowIndices.count else { return }
        let rowIndex = matchRowIndices[currentMatchOrdinal]
        guard rowIndex < rows.count else { return }
        let indexPath = IndexPath(row: rowIndex, section: 0)
        // Defer to next runloop so the table has finished laying out after reloadData.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard indexPath.row < self.tableView.numberOfRows(inSection: 0) else { return }
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
}

// MARK: - Flattening

private extension JSONOutlineView {

    func rebuildRows() {
        rows.removeAll()
        flatten(node: root, key: nil, path: NodePath(), depth: 0, trailingComma: false)
        updateMatchIndices()
        tableView.reloadData()
    }

    func flatten(node: JSONNode, key: String?, path: NodePath, depth: Int, trailingComma: Bool) {
        let matches = nodeMatches(node: node, key: key)
        switch node {
        case .object(let entries):
            if entries.isEmpty {
                rows.append(OutlineRow(
                    path: path,
                    depth: depth,
                    key: key,
                    kind: .primitive(JSONStyle.emptyContainer(isObject: true)),
                    trailingComma: trailingComma,
                    matchesQuery: matches
                ))
                return
            }
            let isExpanded = !collapsed.contains(path)
            rows.append(OutlineRow(
                path: path,
                depth: depth,
                key: key,
                kind: .openContainer(isObject: true, isExpanded: isExpanded, childCount: entries.count),
                trailingComma: !isExpanded && trailingComma,
                matchesQuery: matches
            ))
            if isExpanded {
                for (idx, entry) in entries.enumerated() {
                    let last = idx == entries.count - 1
                    flatten(
                        node: entry.1,
                        key: entry.0,
                        path: path.appending(idx),
                        depth: depth + 1,
                        trailingComma: !last
                    )
                }
                rows.append(OutlineRow(
                    path: path,
                    depth: depth,
                    key: nil,
                    kind: .closeContainer(isObject: true),
                    trailingComma: trailingComma
                ))
            }
        case .array(let items):
            if items.isEmpty {
                rows.append(OutlineRow(
                    path: path,
                    depth: depth,
                    key: key,
                    kind: .primitive(JSONStyle.emptyContainer(isObject: false)),
                    trailingComma: trailingComma,
                    matchesQuery: matches
                ))
                return
            }
            let isExpanded = !collapsed.contains(path)
            rows.append(OutlineRow(
                path: path,
                depth: depth,
                key: key,
                kind: .openContainer(isObject: false, isExpanded: isExpanded, childCount: items.count),
                trailingComma: !isExpanded && trailingComma,
                matchesQuery: matches
            ))
            if isExpanded {
                for (idx, item) in items.enumerated() {
                    let last = idx == items.count - 1
                    flatten(
                        node: item,
                        key: nil,
                        path: path.appending(idx),
                        depth: depth + 1,
                        trailingComma: !last
                    )
                }
                rows.append(OutlineRow(
                    path: path,
                    depth: depth,
                    key: nil,
                    kind: .closeContainer(isObject: false),
                    trailingComma: trailingComma
                ))
            }
        case .primitive(let value):
            rows.append(OutlineRow(
                path: path,
                depth: depth,
                key: key,
                kind: .primitive(value),
                trailingComma: trailingComma,
                matchesQuery: matches
            ))
        case .error(let message):
            rows.append(OutlineRow(
                path: path,
                depth: depth,
                key: key,
                kind: .primitive(NSAttributedString(string: message, attributes: [
                    .foregroundColor: UIColor.secondaryLabel,
                    .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
                ])),
                trailingComma: false,
                matchesQuery: matches
            ))
        }
    }
}

// MARK: - Table

extension JSONOutlineView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: JSONOutlineCell.reuseId,
            for: indexPath
        ) as! JSONOutlineCell
        let isCurrentMatch = !matchRowIndices.isEmpty
            && currentMatchOrdinal < matchRowIndices.count
            && matchRowIndices[currentMatchOrdinal] == indexPath.row
        cell.configure(
            with: rows[indexPath.row],
            query: query,
            isCurrentMatch: isCurrentMatch
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rows[indexPath.row]
        if case .openContainer = row.kind {
            toggleCollapse(at: row.path)
        }
    }

    private func toggleCollapse(at path: NodePath) {
        if collapsed.contains(path) {
            collapsed.remove(path)
        } else {
            collapsed.insert(path)
        }
        rebuildRows()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign focus so the chevron accessory takes over from the X clear button
        // once the user starts browsing the JSON.
        if searchBar.searchTextField.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}

// MARK: - Cell

private final class JSONOutlineCell: UITableViewCell {

    static let reuseId = "JSONOutlineCell"

    private let disclosureLabel = UILabel()
    private let contentLabel = UILabel()
    private let stack = UIStackView()
    private var leadingConstraint: NSLayoutConstraint!

    private static let indentStep: CGFloat = 16
    private static let baseLeading: CGFloat = 12

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground

        disclosureLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        disclosureLabel.textColor = .secondaryLabel
        disclosureLabel.textAlignment = .center
        disclosureLabel.setContentHuggingPriority(.required, for: .horizontal)
        disclosureLabel.widthAnchor.constraint(equalToConstant: 14).isActive = true

        contentLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        contentLabel.numberOfLines = 0

        stack.axis = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 4
        stack.addArrangedSubview(disclosureLabel)
        stack.addArrangedSubview(contentLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        leadingConstraint = stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.baseLeading)

        NSLayoutConstraint.activate([
            leadingConstraint,
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with row: OutlineRow, query: String, isCurrentMatch: Bool) {
        leadingConstraint.constant = Self.baseLeading + CGFloat(row.depth) * Self.indentStep
        contentView.backgroundColor = .clear

        let attributed: NSAttributedString
        switch row.kind {
        case .openContainer(let isObject, let isExpanded, let childCount):
            disclosureLabel.text = isExpanded ? "▼" : "▶"
            attributed = openContainerText(
                key: row.key,
                isObject: isObject,
                isExpanded: isExpanded,
                childCount: childCount,
                trailingComma: row.trailingComma
            )
        case .closeContainer(let isObject):
            disclosureLabel.text = ""
            let brace = isObject ? "}" : "]"
            let text = row.trailingComma ? "\(brace)," : brace
            attributed = NSAttributedString(
                string: text,
                attributes: JSONStyle.braceAttrs
            )
        case .primitive(let value):
            disclosureLabel.text = ""
            attributed = primitiveText(
                key: row.key,
                value: value,
                trailingComma: row.trailingComma
            )
        }

        contentLabel.attributedText = applyMatchHighlights(
            to: attributed,
            query: query,
            isCurrentMatch: isCurrentMatch
        )
    }

    private func applyMatchHighlights(
        to attributed: NSAttributedString,
        query: String,
        isCurrentMatch: Bool
    ) -> NSAttributedString {
        guard !query.isEmpty else { return attributed }

        let result = NSMutableAttributedString(attributedString: attributed)
        let haystack = result.string.lowercased()
        let needle = query.lowercased()
        guard !needle.isEmpty else { return result }

        let baseHighlight = UIColor.systemYellow
        let currentHighlight = UIColor.systemOrange
        let highlight = isCurrentMatch ? currentHighlight : baseHighlight

        var searchRange = haystack.startIndex..<haystack.endIndex
        while let range = haystack.range(of: needle, options: [], range: searchRange) {
            let nsRange = NSRange(range, in: haystack)
            result.addAttribute(.backgroundColor, value: highlight, range: nsRange)
            result.addAttribute(.foregroundColor, value: UIColor.label, range: nsRange)
            searchRange = range.upperBound..<haystack.endIndex
        }
        return result
    }

    private func openContainerText(
        key: String?,
        isObject: Bool,
        isExpanded: Bool,
        childCount: Int,
        trailingComma: Bool
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let key {
            result.append(JSONStyle.keyText(key))
            result.append(NSAttributedString(string: ": ", attributes: JSONStyle.braceAttrs))
        }
        if isExpanded {
            let brace = isObject ? "{" : "["
            result.append(NSAttributedString(string: brace, attributes: JSONStyle.braceAttrs))
        } else {
            let openBrace = isObject ? "{" : "["
            let closeBrace = isObject ? "}" : "]"
            let unit = isObject
                ? (childCount == 1 ? "key" : "keys")
                : (childCount == 1 ? "item" : "items")
            let suffix = trailingComma ? "," : ""
            result.append(NSAttributedString(
                string: "\(openBrace) \(childCount) \(unit) \(closeBrace)\(suffix)",
                attributes: JSONStyle.collapsedAttrs
            ))
        }
        return result
    }

    private func primitiveText(
        key: String?,
        value: NSAttributedString,
        trailingComma: Bool
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let key {
            result.append(JSONStyle.keyText(key))
            result.append(NSAttributedString(string: ": ", attributes: JSONStyle.braceAttrs))
        }
        result.append(value)
        if trailingComma {
            result.append(NSAttributedString(string: ",", attributes: JSONStyle.braceAttrs))
        }
        return result
    }
}

// MARK: - Styling

private enum JSONStyle {

    static let font: UIFont = .monospacedSystemFont(ofSize: 13, weight: .regular)

    static var braceAttrs: [NSAttributedString.Key: Any] {
        [.foregroundColor: UIColor.secondaryLabel, .font: font]
    }

    static var collapsedAttrs: [NSAttributedString.Key: Any] {
        [.foregroundColor: UIColor.tertiaryLabel, .font: font]
    }

    static func keyText(_ key: String) -> NSAttributedString {
        NSAttributedString(
            string: "\"\(key)\"",
            attributes: [.foregroundColor: UIColor.systemPurple, .font: font]
        )
    }

    static func stringValue(_ string: String) -> NSAttributedString {
        NSAttributedString(
            string: "\"\(string)\"",
            attributes: [.foregroundColor: UIColor.systemGreen, .font: font]
        )
    }

    static func numberValue(_ number: NSNumber) -> NSAttributedString {
        NSAttributedString(
            string: "\(number)",
            attributes: [.foregroundColor: UIColor.systemOrange, .font: font]
        )
    }

    static func boolValue(_ value: Bool) -> NSAttributedString {
        NSAttributedString(
            string: value ? "true" : "false",
            attributes: [.foregroundColor: UIColor.systemBlue, .font: font]
        )
    }

    static func nullValue() -> NSAttributedString {
        NSAttributedString(
            string: "null",
            attributes: [.foregroundColor: UIColor.systemGray, .font: font]
        )
    }

    static func plain(_ string: String) -> NSAttributedString {
        NSAttributedString(
            string: string,
            attributes: [.foregroundColor: UIColor.label, .font: font]
        )
    }

    static func emptyContainer(isObject: Bool) -> NSAttributedString {
        NSAttributedString(
            string: isObject ? "{}" : "[]",
            attributes: braceAttrs
        )
    }
}

// MARK: - Search accessory container

/// Fixed-size container overlaid on the search bar to host the clear button and
/// the prev/next chevron stack. Overlay placement (rather than UISearchBar's
/// rightView) is more reliable across iOS versions.
private final class SearchAccessoryView: UIView {
    static let preferredSize = CGSize(width: 30, height: 32)

    override var intrinsicContentSize: CGSize { Self.preferredSize }

    override func sizeThatFits(_ size: CGSize) -> CGSize { Self.preferredSize }

    /// Pass taps through to whatever sits underneath when no child is visible,
    /// so the search bar remains tappable in its full width when the accessory
    /// is empty.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews where !subview.isHidden && subview.alpha > 0.01 {
            let converted = subview.convert(point, from: self)
            if let target = subview.hitTest(converted, with: event) {
                return target
            }
        }
        return nil
    }
}
