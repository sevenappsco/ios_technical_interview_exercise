import Foundation
import UIKit


/// UITableViewCell Helpers
///
extension UITableViewCell {
    
    /// Returns a reuseIdentifier that matches the receiver's classname (non namespaced).
    ///
    class var reuseIdentifier: String {
        return classNameWithoutNamespaces
    }
    
    /// Configures the default background configuration
    func configureDefaultBackgroundConfiguration() {
        var backgroundConfiguration = defaultBackgroundConfiguration()
        backgroundConfiguration.backgroundColor = .listForeground(modal: false)
        self.backgroundConfiguration = backgroundConfiguration
    }
    
    /// Updates the default background configuration
    func updateDefaultBackgroundConfiguration(using state: UICellConfigurationState, style: UITableView.Style = .grouped) {
        var backgroundConfiguration = defaultBackgroundConfiguration().updated(for: state)
        if style == .grouped {
            backgroundConfiguration.backgroundColor = .listForeground(modal: false)
        }
        
        if state.isSelected || state.isHighlighted {
            backgroundConfiguration.backgroundColor = .listSelectedBackground
            backgroundConfiguration.strokeColor = Layout.borderStrokeColor
            backgroundConfiguration.strokeWidth = Layout.borderorderStrokeWidth
        }
        self.backgroundConfiguration = backgroundConfiguration
    }
    
    /// Hides the separator for a cell.
    /// Be careful applying this to a reusable cell where the separator is expected to be shown in some cases.
    ///
    func hideSeparator() {
        // Using `CGFloat.greatestFiniteMagnitude` for the right separator inset would not work if the cell is initially configured with `hideSeparator()` then
        // updated with `showSeparator()` later after the table view is rendered - the separator would not be shown again.
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 999999)
    }
    
    /// Shows the separator for a cell.
    /// The separator inset is only set manually when a custom inset is preferred, or the cell is reusable with a different inset in other use cases.
    ///
    func showSeparator(inset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 0)) {
        separatorInset = inset
    }
}

private extension UITableViewCell {
    enum Layout {
        static let borderStrokeColor: UIColor = .divider
        static let borderorderStrokeWidth: CGFloat = 0.5
    }
}


/// NSObject: Helper Methods
///
extension NSObject {
    
    /// Returns the receiver's classname as a string, not including the namespace.
    ///
    class var classNameWithoutNamespaces: String {
        return String(describing: self)
    }
}


extension UITableView {
    /// Called in view controller's `viewDidLayoutSubviews`. If table view has a footer view, calculates the new height.
    /// If new height is different from current height, updates the footer view with the new height and reassigns the table footer view.
    /// Note: make sure the top-level footer view (`tableView.tableFooterView`) is frame based as a container of the Auto Layout based subview.
    func updateFooterHeight() {
        if let footerView = tableFooterView {
            let targetSize = CGSize(width: footerView.frame.width, height: 0)
            let newSize = footerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            let newHeight = newSize.height
            var currentFrame = footerView.frame
            if newHeight != currentFrame.size.height {
                currentFrame.size.height = newHeight
                footerView.frame = currentFrame
                tableFooterView = footerView
            }
        }
    }
    
    /// Called in view controller's `viewDidLayoutSubviews`. If table view has a header view, calculates the new height.
    /// If new height is different from current height, updates the header view with the new height and reassigns the table header view.
    /// Note: make sure the top-level header view (`tableView.tableHeaderView`) is frame based as a container of the Auto Layout based subview.
    func updateHeaderHeight() {
        if let headerView = tableHeaderView {
            let targetSize = CGSize(width: headerView.frame.width, height: 0)
            let newSize = headerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            let newHeight = newSize.height
            var currentFrame = headerView.frame
            if newHeight != currentFrame.size.height {
                currentFrame.size.height = newHeight
                headerView.frame = currentFrame
                tableHeaderView = headerView
            }
        }
    }
    
    /// Removes the separator of the last cell.
    ///
    func removeLastCellSeparator() {
        tableFooterView = UIView(frame: CGRect(origin: .zero,
                                               size: CGSize(width: frame.width, height: 1)))
    }
    
    /// Change `self.tableFooterView` to an empty view in order to hide the `UITableView`'s
    /// default row placeholders (with separators).
    ///
    /// This intentionally have an absurdingly long method name because we want to be clear that
    /// we are replacing the `tableFooterView` property.
    ///
    func applyFooterViewForHidingExtraRowPlaceholders() {
        tableFooterView = UIView(frame: .zero)
    }
}



extension UITableView {
    
    /// Return the last Index Path (the last row of the last section) if available
    func lastIndexPathOfTheLastSection() -> IndexPath? {
        guard numberOfSections > 0 else {
            return nil
        }
        let section = numberOfSections - 1
        
        guard numberOfRows(inSection: section) > 0 else {
            return nil
        }
        let row = numberOfRows(inSection: section) - 1
        
        return IndexPath(row: row, section: section)
    }
}

// MARK: Typesafe Register & Dequeue
extension UITableView {
    
    /// Registers a `UITableViewCell` using its `reuseIdentifier` property as the reuse identifier.
    ///
    func register(_ type: UITableViewCell.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }
    
    /// Registers a `UITableViewCell` nib  using its `reuseIdentifier` property as the reuse identifier.
    ///
    func registerNib(for type: UITableViewCell.Type) {
        register(type.loadNib(), forCellReuseIdentifier: type.reuseIdentifier)
    }
    
    /// Dequeue a previously registered cell by it's class `reuseIdentifier` property.
    /// Failing to dequeue the cell will throw a `fatalError`
    ///
    func dequeueReusableCell<T: UITableViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            let message = "Could not dequeue cell with identifier \(T.reuseIdentifier) at \(indexPath)"
            print(message)
            fatalError(message)
        }
        return cell
    }
}

// MARK: Swipe Actions
extension UITableView {
    
    /// Represents the values needed to provide a glance an animation to a swipe action.
    /// The `cell` is used to animate the view out in the glance animation.
    /// The `color` is used as a background color to give the swipe action effect.
    ///
    private struct GlanceActionConfiguration {
        let cell: UITableViewCell
        let color: UIColor
    }
    
    /// Slightly reveal swipe actions of the first visible cell that contains at least one swipe action.
    ///
    func glanceTrailingSwipeActions() {
        // If no swipe action configuration is found, do nothing.
        guard let glanceConfiguration = firstTrailingSwipeActionConfiguration() else {
            return
        }
        performGlanceAnimation(on: glanceConfiguration.cell, with: glanceConfiguration.color)
    }
    
    /// Returns the view configuration of the first visible cell that contains a swipe action.
    ///
    private func firstTrailingSwipeActionConfiguration() -> GlanceActionConfiguration? {
        // If there are no visible index paths, then there is no swipe action to glance.
        guard let visibleIndexPath = indexPathsForVisibleRows else {
            return nil
        }
        
        // Traverse through the visible cells and find the first one who has a swipe action.
        for indexPath in visibleIndexPath {
            guard
                let configuration = delegate?.tableView?(self, trailingSwipeActionsConfigurationForRowAt: indexPath),
                let action = configuration.actions.first,
                let cell = cellForRow(at: indexPath) else {
                continue
            }
            
            return GlanceActionConfiguration(cell: cell, color: action.backgroundColor)
        }
        
        // Return `nil` if nothing is found.
        return nil
    }
    
    // Animates the cell out and in while leaving a solid color in place as a background to achieve a swipe action glance animation.
    //
    private func performGlanceAnimation(on cell: UITableViewCell, with color: UIColor) {
        // Defines animation time for glancing in/out
        let glanceAnimationDuration = 0.15
        
        // Amount of points of a swipe action to reveal during the animation
        let amountToReveal = 20.0
        
        // Color to be used as a background while the cell is animating.
        let colorBackground = UIView(frame: .init(x: cell.frame.width - amountToReveal,
                                                  y: cell.frame.origin.y,
                                                  width: amountToReveal,
                                                  height: cell.frame.height))
        colorBackground.backgroundColor = color
        addSubview(colorBackground)
        sendSubviewToBack(colorBackground)
        
        // Animate cell out
        UIView.animate(withDuration: glanceAnimationDuration, delay: 0, options: [.curveEaseOut]) {
            
            cell.transform = CGAffineTransform(translationX: -amountToReveal, y: 0) // Translate to the left.
        } completion: { _ in
            
            // Animate cell in
            UIView.animate(withDuration: glanceAnimationDuration, delay: 0, options: [.curveEaseIn]) {
                cell.transform = .identity // Restore its matrix transformation.
            } completion: { _ in
                
                // Clean state
                colorBackground.removeFromSuperview()
            }
        }
    }
}


// MARK: - Skeleton UITableView Methods
//
extension UITableView {
    
    /// Displays Ghost Content with the specified Settings.
    ///
    public func displayGhostContent(options: GhostOptions, style: GhostStyle = .default) {
        guard isDisplayingGhostContent == false else {
            return
        }
        
        preserveInitialDelegatesAndSettings()
        setupGhostHandler(options: options, style: style)
        allowsSelection = false
        
        reloadData()
    }
    
    /// Nukes the Ghost Style.
    ///
    public func removeGhostContent() {
        guard isDisplayingGhostContent else {
            return
        }
        
        restoreInitialDelegatesAndSettings()
        resetAssociatedReferences()
        removeGhostLayers()
        
        reloadData()
    }
    
    /// Indicates if the receiver is wired up to display Ghost Content.
    ///
    public var isDisplayingGhostContent: Bool {
        return ghostHandler != nil
    }
}


// MARK: - Private Methods
//
private extension UITableView {
    
    /// Sets up an internal (private) instance of GhostTableViewHandler.
    ///
    func setupGhostHandler(options: GhostOptions, style: GhostStyle) {
        let handler = GhostTableViewHandler(options: options, style: style)
        dataSource = handler
        delegate = handler
        ghostHandler = handler
    }
    
    /// Preserves the DataSource + Delegate + allowsSelection state.
    ///
    func preserveInitialDelegatesAndSettings() {
        initialDataSource = dataSource
        initialDelegate = delegate
        initialAllowsSelection = allowsSelection
    }
    
    /// Restores the initial DataSource + Delegate + allowsSelection state.
    ///
    func restoreInitialDelegatesAndSettings() {
        dataSource = initialDataSource
        delegate = initialDelegate
        allowsSelection = initialAllowsSelection ?? true
    }
    
    /// Cleans up all of the (private) internal references.
    ///
    func resetAssociatedReferences() {
        initialDataSource = nil
        initialDelegate = nil
        ghostHandler = nil
        initialAllowsSelection = nil
    }
}


// MARK: - Private "Associated" Properties
//
private extension UITableView {
    
    /// Reference to the GhostHandler.
    ///
    var ghostHandler: GhostTableViewHandler? {
        get {
            return objc_getAssociatedObject(self, &Keys.ghostHandler) as? GhostTableViewHandler
        }
        set {
            objc_setAssociatedObject(self, &Keys.ghostHandler, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// UITableViewDataSource state, previous to mapping the GhostHandler.
    ///
    var initialDataSource: UITableViewDataSource? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalDataSource) as? UITableViewDataSource
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalDataSource, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// UITableViewDelegate state, previous to mapping the GhostHandler.
    ///
    var initialDelegate: UITableViewDelegate? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalDelegate) as? UITableViewDelegate
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalDelegate, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// Previous allowsSelection state.
    ///
    var initialAllowsSelection: Bool? {
        get {
            return objc_getAssociatedObject(self, &Keys.originalAllowsSelection) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &Keys.originalAllowsSelection, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}


// MARK: - Nested Types
//
private extension UITableView {
    
    enum Keys {
        static var ghostHandler = 0x1000
        static var originalDataSource = 0x1001
        static var originalDelegate = 0x1002
        static var originalAllowsSelection = 0x1003
    }
}
