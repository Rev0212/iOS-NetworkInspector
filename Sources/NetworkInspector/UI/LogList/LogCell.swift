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
    private let endpointLabel = UILabel()
    private let statusRightLabel = UILabel()
    private let baseLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

    // MARK: - UI Setup
private extension LogCell {
    
    func setupUI() {
            // Method
        methodLabel.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        methodLabel.setContentHuggingPriority(.required, for: .horizontal)
        methodLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
            // Endpoint
        endpointLabel.font = .systemFont(ofSize: 14, weight: .medium)
        endpointLabel.numberOfLines = 0
        endpointLabel.lineBreakMode = .byWordWrapping
        
            // Status (right)
        statusRightLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        statusRightLabel.textAlignment = .right
        
            // Host (right bottom)
        baseLabel.font = .systemFont(ofSize: 12)
        baseLabel.textColor = .secondaryLabel
        baseLabel.textAlignment = .right
        baseLabel.numberOfLines = 2
        
            // Left row: METHOD + ENDPOINT (center aligned)
        let leftRow = UIStackView(arrangedSubviews: [
            methodLabel,
            endpointLabel
        ])
        leftRow.axis = .horizontal
        leftRow.spacing = 8
        leftRow.alignment = .center
        
            // Right stack: STATUS + HOST
        let rightStack = UIStackView(arrangedSubviews: [
            statusRightLabel,
            baseLabel
        ])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .trailing
        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        
            // Main row
        let row = UIStackView(arrangedSubviews: [
            leftRow,
            rightStack
        ])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
}

    // MARK: - Configuration
extension LogCell {
    
    func configure(with log: NetworkLog) {
        methodLabel.text = log.request.method.rawValue
        
        let host = log.request.url?.host ?? "-"
        let path = log.request.url?.path ?? "/"
        endpointLabel.text = path
        
        if let status = log.response.statusCode {
            let text = "Status \(status)"
            let color: UIColor = status < 400 ? .systemGreen : .systemRed
            statusRightLabel.text = text
            statusRightLabel.textColor = color
        } else {
            statusRightLabel.text = "Failed"
            statusRightLabel.textColor = .systemRed
        }
        
        baseLabel.text = host
    }
}
