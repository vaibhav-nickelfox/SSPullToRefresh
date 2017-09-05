//
//  RefreshViewDelegate.swift
//  PullToRefresh
//
//  Created by Sam Soffes on 6/29/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import UIKit

public protocol RefreshViewDelegate: class {
	/// Return `false` if the refresh view should not start refreshing.
	func refreshViewShouldStartRefreshing(_ refreshView: RefreshView) -> Bool
	
	/// The refresh view started refreshing. You should kick off whatever you need to load when this is called.
	func refreshViewDidStartRefreshing(_ refreshView: RefreshView)
	
	/// The refresh view finished refreshing. This will get called when it receives `finishRefreshing`.
	func refreshViewDidFinishRefreshing(_ refreshView: RefreshView)
	
	/// The date when data was last updated. This will get called when it finishes refreshing or if it receives
	/// `invalidateLastUpdatedAt`. Some content views may display this date.
	func lastUpdatedAtForRefreshView(_ refreshView: RefreshView) -> Date?
	
	/// The refresh view updated its scroll view's content inset.
	func refreshView(_ refreshView: RefreshView, didUpdateContentInset contentInset: UIEdgeInsets)
	
	/// The refresh view will change state.
	func refreshView(_ refreshView: RefreshView, willTransitionTo to: RefreshView.State, from: RefreshView.State, animated: Bool)
	
	/// The refresh view did change state.
	func refreshView(_ refreshView: RefreshView, didTransitionTo to: RefreshView.State, from: RefreshView.State, animated: Bool)
}
