//
//  ResponseStatusTabViewController.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class ResponseStatusTabViewController: UIViewController {

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

private extension ResponseStatusTabViewController {

    func setupUI() {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)

        let headersText = log.response.headers.map(PrettyFormatter.prettyHeaders) ?? "-"

        label.text = """
        Status Code:
        \(log.response.statusCode.map(String.init) ?? "—")

        Duration:
        \(Int(log.timing.duration * 1000)) ms

        Error:
        \(log.response.error?.localizedDescription ?? "None")

        Headers:
        \(headersText)
        """

        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
}

