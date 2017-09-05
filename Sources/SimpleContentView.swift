//
//  SimpleContentView.swift
//  PullToRefresh
//
//  Created by Sam Soffes on 5/17/12.
//  Copyright © 2012-2016 Sam Soffes. All rights reserved.
//

import UIKit

open class SimpleContentView: UIView, ContentView {

	// MARK: - Properties

	open var state: RefreshView.State = .closed {
		didSet {
			updateState()
		}
	}

	open var progress: CGFloat = 0
	open var lastUpdatedAt: Date?

	open let statusLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 14)
		label.textColor = .black
		label.backgroundColor = .clear
		label.textAlignment = .center
		return label
	}()

	open let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)


	// MARK: - Initializers

	public override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(statusLabel)
		addSubview(activityIndicatorView)

		updateState()
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	// MARK: - UIView

	open override func layoutSubviews() {
		let size = bounds.size

		statusLabel.frame = CGRect(x: 20, y: round((size.height - 30) / 2.0), width: size.width - 40, height: 30)
		activityIndicatorView.frame = CGRect(x: round((size.width - 20) / 2), y: round((size.height - 20) / 2), width: 20, height: 20)
	}


	// MARK: - Private

	fileprivate func updateState() {
		switch state {
		case .closed, .opening:
			statusLabel.text = NSLocalizedString("Pull down to refresh", comment: "")
			statusLabel.alpha = 1
			activityIndicatorView.stopAnimating()
			activityIndicatorView.alpha = 0
		case.ready:
			statusLabel.text = NSLocalizedString("Release to refresh", comment: "")
			statusLabel.alpha = 1
			activityIndicatorView.stopAnimating()
			activityIndicatorView.alpha = 0
		case .refreshing:
			statusLabel.alpha = 0
			activityIndicatorView.startAnimating()
			activityIndicatorView.alpha = 1
		case .closing:
			statusLabel.text = nil
			activityIndicatorView.alpha = 0
		}
	}
}

