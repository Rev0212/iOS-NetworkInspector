//
//  RequestTabViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class RequestTabViewController: UIViewController {

    private let log: NetworkLog

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

private extension RequestTabViewController {

    func setupUI() {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)

        let headersText = log.request.headers.isEmpty
            ? "-"
            : PrettyFormatter.prettyHeaders(log.request.headers)
        let bodyText = log.request.body.map(PrettyFormatter.prettyJSON(from:)) ?? "-"

        textView.text = """
        URL:
        \(log.request.url?.absoluteString ?? "-")

        Method:
        \(log.request.method.rawValue)

        Headers:
        \(headersText)

        Body:
        \(bodyText)
        """

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
