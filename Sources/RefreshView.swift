//
//  RefreshView.swift
//  PullToRefresh
//
//  Created by Sam Soffes on 4/9/12.
//  Copyright © 2012-2016 Sam Soffes. All rights reserved.
//

import UIKit

/// Example usage:
///
/// let refreshView = RefreshView()
///
/// override func viewDidLoad() {
///     super.viewDidLoad()
///
///     refreshView.scrollView = tableView
///     refreshView.delegate = self
/// }
///
/// func refresh() {
///     refreshView?.startRefreshing()
///     // Load data…
///     refreshView?.finishRefreshing()
/// }
///
/// func refreshViewDidStartRefreshing(refreshView: RefreshView) {
///     refresh()
/// }
open class RefreshView: UIView {
	
	// MARK: - Types
	
	public enum State {
		/// Offscreen.
		case closed
		
		/// The user started pulling. Most will say "Pull to refresh" in this state.
		case opening
		
		/// The user pulled far enough to cause a refresh. Most will say "Release to refresh" in this state.
		case ready
		
		/// The view is refreshing.
		case refreshing
		
		/// The refresh is completed. The view is now animating out.
		case closing
	}

	
	// MARK: - Properties
	
	/// The delegate is sent messages when the refresh view starts refreshing. This is automatically set with
	/// `init(scrollView:delegate:)`.
	open weak var delegate: RefreshViewDelegate?
	
	/// The scroll view containing the refresh view. This is automatically set with `init(scrollView:delegate:)`.
	open weak var scrollView: UIScrollView? {
		willSet {
			guard let scrollView = scrollView else { return }
			scrollView.removeObserver(self, forKeyPath: "contentOffset")
		}

		didSet {
			scrollViewDidChange()
		}
	}
	
	/// The content view displayed when the `scrollView` is pulled down.
	open var contentView: ContentView {
		willSet {
			contentViewMinimumHeightConstraint = nil
			contentView.view.removeFromSuperview()
		}

		didSet {
			contentViewDidChange()
		}
	}

	/// The state of the receiver.
	open fileprivate(set) var state: State = .closed {
		didSet {
			let wasRefreshing = oldValue == .refreshing

			// Forward to content view
			contentView.state = state

			// Notify delegate
			if wasRefreshing && state != .refreshing {
				delegate?.refreshViewDidFinishRefreshing(self)
			} else if !wasRefreshing && state == .refreshing {
				delegate?.refreshViewDidStartRefreshing(self)
			}
		}
	}

	/// If you need to update the scroll view's content inset while it contains a refresh view, you should set the
	/// `defaultContentInset` on the refresh view and it will forward it to the scroll view taking into account the
	/// refresh view's position.
	open var defaultContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
		didSet {
			updateTopContentInset(topInset)
		}
	}
	
	/// The height of the fully expanded content view. The default is `64.0`.
	///
	/// The `contentView`'s `sizeThatFits:` will be respected when displayed but does not effect the expanded height.
	/// You can use this to draw outside of the expanded area. If you don't implement `sizeThatFits:` it will
	/// automatically display at the default size.
	open var expandedHeight: CGFloat = 64 {
		didSet {
			contentViewMinimumHeightConstraint?.constant = expandedHeight
		}
	}
	
	/// A boolean indicating if the pull to refresh view is expanded.
	open fileprivate(set) var isExpanded = false {
		didSet {
			updateTopContentInset(isExpanded ? expandedHeight : 0)
		}
	}

	fileprivate var progress: CGFloat = 0 {
		didSet {
			contentView.progress = progress
		}
	}

	// Semaphore is used to ensure only one animation plays at a time
	fileprivate var animationSemaphore: DispatchSemaphore = {
		let semaphore = DispatchSemaphore(value: 0)
		semaphore.signal()
		return semaphore
	}()

	fileprivate var topInset: CGFloat = 0
	fileprivate var contentViewMinimumHeightConstraint: NSLayoutConstraint?


	// MARK: - Initializers
	
	/// All you need to do to add this view to your scroll view is call this method (passing in the scroll view).
	/// That's it.
	///
	/// You don't have to add it as subview or anything else. You should only initalize with this method and never move
	/// it to another scroll view during its lifetime.
	public init(scrollView: UIScrollView? = nil, delegate: RefreshViewDelegate? = nil, contentView: ContentView = DefaultContentView()) {
		self.scrollView = scrollView
		self.delegate = delegate
		self.contentView = contentView

		super.init(frame: .zero)

		translatesAutoresizingMaskIntoConstraints = false

		scrollViewDidChange()
		contentViewDidChange()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		scrollView = nil
	}


	// MARK: - UIView

	open override func removeFromSuperview() {
		scrollView = nil
		super.removeFromSuperview()
	}


	// MARK: - Refreshing
	
	/// Call this method when you start refresing. If you trigger refresing another way besides pulling, call this
	/// method so the receiver will be in sync with the refreshing status. By default, it will not expand the view so it
	/// loads quietly out of view.
	open func startRefreshing(_ expand: Bool = false, animated: Bool = true, completion: (() -> Void)? = nil) {
		// If we're already refreshing, don't do anything.
		if state == .refreshing {
			return
		}

		// Animate back to the refreshing state
		set(state: .refreshing, animated: animated, expand: expand, completion: completion)
	}

	/// Call this when you finish refresing.
	open func finishRefreshing(_ animated: Bool = true, completion: (() -> Void)? = nil) {
		// If we're not refreshing, don't do anything.
		if state != .refreshing {
			return
		}

		// Animate back to the normal state
		set(state: .closing, animated: animated, expand: false) { [weak self] in
			self?.state = .closed
			completion?()
		}

		invalidateLastUpdatedAt()
	}

	/// Manually update the last updated at time. This will automatically get called when the refresh view finishes
	/// refreshing.
	open func invalidateLastUpdatedAt() {
		let date = delegate?.lastUpdatedAtForRefreshView(self) ?? Date()
		contentView.lastUpdatedAt = date
	}


	// MARK: - Private

	fileprivate func scrollViewDidChange() {
		guard let scrollView = scrollView else { return }
		defaultContentInsets = scrollView.contentInset
		scrollView.addSubview(self)

		NSLayoutConstraint.activate([
			leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			widthAnchor.constraint(equalTo: scrollView.widthAnchor),
			bottomAnchor.constraint(equalTo: scrollView.topAnchor),
			heightAnchor.constraint(equalToConstant: 400)
		])

		scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
	}

	fileprivate func contentViewDidChange() {
		contentView.state = state
		contentView.progress = progress
		invalidateLastUpdatedAt()
		addSubview(contentView.view)

		contentView.view.translatesAutoresizingMaskIntoConstraints = false

		let minumumHeightConstraint = contentView.view.heightAnchor.constraint(greaterThanOrEqualToConstant: expandedHeight)
		contentViewMinimumHeightConstraint = minumumHeightConstraint

		NSLayoutConstraint.activate([
			contentView.view.bottomAnchor.constraint(equalTo: bottomAnchor),
			contentView.view.leadingAnchor.constraint(equalTo: leadingAnchor),
			contentView.view.trailingAnchor.constraint(equalTo: trailingAnchor),
			minumumHeightConstraint
		])
	}

	fileprivate func updateTopContentInset(_ topInset: CGFloat) {
		self.topInset = topInset

		// Default to the scroll view's initial content inset
		var insets = defaultContentInsets

		// Add the top inset
		insets.top += topInset

		// Don't set it if that is already the current inset
		guard let scrollView = scrollView else { return }
		if scrollView.contentInset == insets {
			return
		}

		// Update the content inset
		scrollView.contentInset = insets

		// If scroll view is on top, scroll again to the top (needed for scroll views with content > scroll view).
		if scrollView.contentOffset.y <= 0 {
			scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
		}

		// Tell the delegate
		delegate?.refreshView(self, didUpdateContentInset: scrollView.contentInset)
	}

	fileprivate func set(state to: State, animated: Bool, expand: Bool, completion: (() -> Void)? = nil) {
		let from = state

		delegate?.refreshView(self, willTransitionTo: to, from: from, animated: animated)

		if !animated {
			state = to
			isExpanded = expand
			completion?()
			delegate?.refreshView(self, didTransitionTo: to, from: from, animated: animated)
			return
		}

		// Go to a background queue to wait for previous animations to finish
		DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async { [weak self] in
			// Wait for previous animations to finish
			guard let semaphore = self?.animationSemaphore else { return }
			semaphore.wait(timeout: DispatchTime.distantFuture)

			// Previous animations are finished. Go back to the main queue.
			DispatchQueue.main.async {
				// Animate the change
				UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .allowUserInteraction, animations: {
					self?.state = to
					self?.isExpanded = expand
				}, completion: { _ in
					semaphore.signal()
					completion?()

					if let this = self {
						this.delegate?.refreshView(this, didTransitionTo: to, from: from, animated: animated)
					}
				})
			}
		}
	}


	// MARK: - NSKeyValueObserving

	open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		// Call super if we didn't register for this notification
		if keyPath != "contentOffset" {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}

		// Get the offset out of the change notification
		guard let offsetY = (change?[NSKeyValueChangeKey.newKey] as? NSValue)?.cgPointValue.y,
			let scrollView = scrollView
		else { return }

		let y = offsetY + defaultContentInsets.top

		// Scroll view is dragging
		if scrollView.isDragging {
			// Scroll view is ready
			if state == .ready {
				// Update the content view's pulling progressing
				progress = -y / expandedHeight

				// Dragged enough to refresh
				if y > -expandedHeight && y < 0 {
					state = .closed
				}
			}

			// Scroll view is normal
			else if state == .closed {
				// Update the content view's pulling progressing
				progress = -y / expandedHeight

				// Dragged enough to be ready
				if y < -expandedHeight {
					state = .ready
				}
			}

			// Scroll view is refreshing
			else if state == .refreshing {
				let insetAdjustment = y < 0 ? max(0, expandedHeight + y) : expandedHeight
				updateTopContentInset(expandedHeight - insetAdjustment)
			}
			return
		} else if scrollView.isDecelerating {
			progress = -y / self.expandedHeight
		}

		// If the scroll view isn't ready, we're not interested
		if state != .ready {
			return
		}

		// We're ready, prepare to switch to refreshing. By default, we should refresh.
		var newState = State.refreshing

		// Ask the delegate if it's cool to start refreshing
		var expand = true
		if let delegate = delegate, !delegate.refreshViewShouldStartRefreshing(self) {
			// Animate back to normal since the delegate said no
			newState = .closed
			expand = false
		}

		// Animate to the new state
		set(state: newState, animated: true, expand: expand)
	}
}
