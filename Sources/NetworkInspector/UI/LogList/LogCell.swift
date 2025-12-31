//
//  LogCell.swift
//  NetworkInspector
//
//  Created by Revanth A on 01/01/26.
//


import UIKit

final class LogCell: UITableViewCell {

    static let reuseIdentifier = "LogCell"

    private let methodLabel = UILabel()
    private let urlLabel = UILabel()
    private let statusLabel = UILabel()
    private let durationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


private extension LogCell {

    func setupUI() {
        methodLabel.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        methodLabel.setContentHuggingPriority(.required, for: .horizontal)

        urlLabel.font = .systemFont(ofSize: 14)
        urlLabel.numberOfLines = 2

        statusLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.textColor = .secondaryLabel

        let topRow = UIStackView(arrangedSubviews: [
            methodLabel,
            urlLabel
        ])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .top

        let bottomRow = UIStackView(arrangedSubviews: [
            statusLabel,
            UIView(),
            durationLabel
        ])
        bottomRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [
            topRow,
            bottomRow
        ])
        stack.axis = .vertical
        stack.spacing = 6

        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
}


extension LogCell {

    func configure(with log: NetworkLog) {
        methodLabel.text = log.request.method.rawValue
        urlLabel.text = log.request.url?.path ?? "/"

        if let status = log.response.statusCode {
            statusLabel.text = "Status \(status)"
            statusLabel.textColor = status < 400 ? .systemGreen : .systemRed
        } else {
            statusLabel.text = "Failed"
            statusLabel.textColor = .systemRed
        }

        let ms = Int(log.timing.duration * 1000)
        durationLabel.text = "\(ms) ms"
    }
}
