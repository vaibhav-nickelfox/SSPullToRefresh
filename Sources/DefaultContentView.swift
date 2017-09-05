//
//  DefaultContentView.swift
//  PullToRefresh
//
//  Created by Sam Soffes on 4/9/12.
//  Copyright © 2012-2016 Sam Soffes. All rights reserved.
//

import UIKit

open class DefaultContentView: UIView, ContentView {
	
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
	
	open let lastUpdatedAtLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 12)
		label.textColor = .lightGray
		label.backgroundColor = .clear
		label.textAlignment = .center
		return label
	}()
	
	open let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
	
	
	// MARK: - Initializers
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		addSubview(statusLabel)
		addSubview(lastUpdatedAtLabel)
		addSubview(activityIndicatorView)
		
		updateState()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: - UIView
	
	open override func layoutSubviews() {
		let width = bounds.width
		
		statusLabel.frame = CGRect(x: 0, y: 14, width: width, height: 20)
		lastUpdatedAtLabel.frame = CGRect(x: 0, y: 34, width: width, height: 20)
		activityIndicatorView.frame = CGRect(x: 30, y: 25, width: 20, height: 20)
	}
	
	
	// MARK: - Private
	
	fileprivate func updateState() {
		switch state {
		case .closed, .opening:
			statusLabel.text = NSLocalizedString("Pull down to refresh…", comment: "")
			activityIndicatorView.stopAnimating()
		case.ready:
			statusLabel.text = NSLocalizedString("Release to refresh…", comment: "")
			activityIndicatorView.stopAnimating()
		case .refreshing, .closing:
			statusLabel.text = NSLocalizedString("Loading…", comment: "")
			activityIndicatorView.startAnimating()
		}
	}
}
