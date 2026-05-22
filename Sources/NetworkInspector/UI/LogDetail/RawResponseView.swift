//
//  RawResponseView.swift
//  NetworkInspector
//

import UIKit

final class RawResponseView: UIView {

    private let searchBar = UISearchBar()
    private let matchCountLabel = UILabel()
    private let textView = UITextView()

    private var baseText: String = ""
    private var matchRanges: [NSRange] = []
    private var currentMatchIndex: Int = 0

    init(data: Data?) {
        super.init(frame: .zero)
        if let data {
            baseText = PrettyFormatter.prettyJSON(from: data)
        } else {
            baseText = "No response body"
        }
        textView.text = baseText
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension RawResponseView {

    func setupUI() {
        backgroundColor = .systemBackground

        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)

        searchBar.placeholder = "Search in response"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.returnKeyType = .next
        searchBar.showsBookmarkButton = true
        searchBar.setImage(UIImage(systemName: "chevron.up"), for: .bookmark, state: .normal)

        matchCountLabel.font = .systemFont(ofSize: 12)
        matchCountLabel.textColor = .secondaryLabel
        matchCountLabel.textAlignment = .right
        matchCountLabel.isHidden = true

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        matchCountLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchBar)
        addSubview(matchCountLabel)
        addSubview(textView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            matchCountLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 2),
            matchCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            matchCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: matchCountLabel.bottomAnchor, constant: 2),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

extension RawResponseView: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        recomputeMatches(for: searchText)
        currentMatchIndex = 0
        applyHighlights()
        scrollToCurrentMatch()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        advanceMatch(by: 1)
    }

    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        advanceMatch(by: -1)
    }
}

private extension RawResponseView {

    func recomputeMatches(for searchText: String) {
        matchRanges = []
        guard !searchText.isEmpty else { return }

        let lowercasedText = baseText.lowercased()
        let lowercasedSearch = searchText.lowercased()
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex

        while let range = lowercasedText.range(of: lowercasedSearch, options: [], range: searchRange) {
            matchRanges.append(NSRange(range, in: baseText))
            searchRange = range.upperBound..<lowercasedText.endIndex
        }
    }

    func applyHighlights() {
        let attributed = NSMutableAttributedString(
            string: baseText,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )

        for (index, range) in matchRanges.enumerated() {
            let isCurrent = index == currentMatchIndex
            attributed.addAttribute(
                .backgroundColor,
                value: isCurrent ? UIColor.systemOrange : UIColor.systemYellow,
                range: range
            )
            attributed.addAttribute(.foregroundColor, value: UIColor.label, range: range)
        }

        textView.attributedText = attributed

        if matchRanges.isEmpty {
            matchCountLabel.isHidden = (searchBar.text ?? "").isEmpty
            matchCountLabel.text = (searchBar.text ?? "").isEmpty ? nil : "No matches"
        } else {
            matchCountLabel.isHidden = false
            matchCountLabel.text = "\(currentMatchIndex + 1) of \(matchRanges.count)"
        }
    }

    func advanceMatch(by step: Int) {
        guard !matchRanges.isEmpty else {
            searchBar.resignFirstResponder()
            return
        }
        let count = matchRanges.count
        currentMatchIndex = ((currentMatchIndex + step) % count + count) % count
        applyHighlights()
        scrollToCurrentMatch()
    }

    func scrollToCurrentMatch() {
        guard !matchRanges.isEmpty else { return }
        let range = matchRanges[currentMatchIndex]
        textView.scrollRangeToVisible(range)
        if let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
           let end = textView.position(from: start, offset: range.length),
           let textRange = textView.textRange(from: start, to: end) {
            let rect = textView.firstRect(for: textRange)
            if rect.origin.y.isFinite {
                let target = max(0, rect.origin.y - textView.bounds.height / 3)
                textView.setContentOffset(CGPoint(x: 0, y: target), animated: true)
            }
        }
    }
}
