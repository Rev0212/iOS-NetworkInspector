//
//  ResponseBodyTabViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class ResponseBodyTabViewController: UIViewController {

    private let log: NetworkLog
    private let textView = UITextView()
    private let searchBar = UISearchBar()
    private var baseText: String = ""

    init(log: NetworkLog) {
        self.log = log
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
}

private extension ResponseBodyTabViewController {

    func setupUI() {
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)

        if let data = log.response.body {
            baseText = PrettyFormatter.prettyJSON(from: data)
            textView.text = baseText
        } else {
            baseText = "No response body"
            textView.text = baseText
        }

        searchBar.placeholder = "Search in response"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension ResponseBodyTabViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        highlightOccurrences(of: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

private extension ResponseBodyTabViewController {

    func highlightOccurrences(of searchText: String) {
        guard !searchText.isEmpty else {
            textView.attributedText = NSAttributedString(string: baseText)
            return
        }

        let attributed = NSMutableAttributedString(string: baseText)
        let lowercasedText = baseText.lowercased()
        let lowercasedSearch = searchText.lowercased()
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex

        while let range = lowercasedText.range(of: lowercasedSearch, options: [], range: searchRange) {
            let nsRange = NSRange(range, in: baseText)
            attributed.addAttribute(.backgroundColor, value: UIColor.systemYellow, range: nsRange)
            attributed.addAttribute(.foregroundColor, value: UIColor.label, range: nsRange)
            searchRange = range.upperBound..<lowercasedText.endIndex
        }

        textView.attributedText = attributed
    }
}
