//
//  UIView+Helpers.swift
//  Pollexa
//
//  Created by Adem Özsayın on 6.06.2024.
//

import Foundation
import UIKit

// MARK: - UIView Helpers
//
extension UIView {
    
    @objc public func pinSubviewAtCenter(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: subview, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: subview, attribute: .centerY, multiplier: 1, constant: 0)
        ]
        
        addConstraints(newConstraints)
    }
    
    /// Adds constraints that pin a subview to self with zero insets.
    ///
    /// - Parameter subview: a subview to be pinned to self.
    @objc public func pinSubviewToAllEdges(_ subview: UIView) {
        pinSubviewToAllEdges(subview, insets: .zero)
    }
    
    /// Adds constraints that pin a subview to self with padding insets.
    ///
    /// - Parameters:
    ///   - subview: a subview to be pinned to self.
    ///   - insets: spacing between each subview edge to self. A positive value for an edge indicates that the subview is inside self on that edge.
    @objc public func pinSubviewToAllEdges(_ subview: UIView, insets: UIEdgeInsets) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: -insets.left),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
            topAnchor.constraint(equalTo: subview.topAnchor, constant: -insets.top),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom),
        ])
    }
    
    @objc public func pinSubviewToAllEdgeMargins(_ subview: UIView) {
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: subview.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: subview.trailingAnchor),
            layoutMarginsGuide.topAnchor.constraint(equalTo: subview.topAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: subview.bottomAnchor),
        ])
    }
    
    /// Adds constraints that pin a subview to self's safe area with padding insets.
    ///
    /// - Parameters:
    ///   - subview: a subview to be pinned to self's safe area.
    @objc public func pinSubviewToSafeArea(_ subview: UIView) {
        pinSubviewToSafeArea(subview, insets: .zero)
    }
    
    /// Adds constraints that pin a subview to self's safe area with padding insets.
    ///
    /// - Parameters:
    ///   - subview: a subview to be pinned to self's safe area.
    ///   - insets: spacing between each subview edge to self's safe area. A positive value for an edge indicates that the subview is inside safe area on that edge.
    @objc public func pinSubviewToSafeArea(_ subview: UIView, insets: UIEdgeInsets) {
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: -insets.left),
                safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
                safeAreaLayoutGuide.topAnchor.constraint(equalTo: subview.topAnchor, constant: -insets.top),
                safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom),
            ])
        }
    }
    
    @objc public func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        
        for subview in subviews {
            guard let responder = subview.findFirstResponder() else {
                continue
            }
            
            return responder
        }
        
        return nil
    }
    
    @objc public func userInterfaceLayoutDirection() -> UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }
    
    public func changeLayoutMargins(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) {
        let top = top ?? layoutMargins.top
        let left = left ?? layoutMargins.left
        let bottom = bottom ?? layoutMargins.bottom
        let right = right ?? layoutMargins.right
        
        layoutMargins = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}


/// UIView Class Methods
///
extension UIView {
    
    /// Returns the Nib associated with the received: It's filename is expected to match the Class Name
    ///
    class func loadNib() -> UINib {
        return UINib(nibName: classNameWithoutNamespaces, bundle: nil)
    }
    
    /// Returns the first Object contained within the nib with a name whose name matches with the receiver's type.
    /// Note: On error this method is expected to break, by design!
    ///
    class func instantiateFromNib<T>() -> T {
        return loadNib().instantiate(withOwner: nil, options: nil).first as! T
    }
    
    /// Returns whether there is a Nib associated with the receiver, being the filename its Class Name.
    /// Use it to avoid *Could not load NIB in bundle* crash before calling `registerNib` if you are not sure that it exists.
    ///
    class func nibExistsInMainBundle() -> Bool {
        Bundle.main.path(forResource: classNameWithoutNamespaces, ofType: "nib") != nil
    }
}


/// UIView Extension Methods
///
extension UIView {
    
    /// Returns the first Subview of the specified Type (if any).
    ///
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            guard let target = (subview as? T) ?? subview.firstSubview(ofType: type) else {
                continue
            }
            
            return target
        }
        
        return nil
    }
}


/// UIView: Skeletonizer Public API
///
extension UIView {
    
    /// Applies a GhostLayer on each one of the receiver's Leaf Views (if needed).
    ///
    func insertGhostLayers(callback: (GhostLayer) -> Void) {
        layoutIfNeeded()
        
        enumerateGhostableLeafViews { leafView in
            guard leafView.containsGhostLayer == false else {
                return
            }
            
            let layer = GhostLayer()
            layer.insert(into: leafView)
            callback(layer)
        }
    }
    
    /// Removes all of the GhostLayer(s) from the Leaf Views.
    ///
    func removeGhostLayers() {
        enumerateGhostLayers { skeletonLayer in
            skeletonLayer.removeFromSuperlayer()
        }
    }
    
    /// Enumerates all of the receiver's GhostLayer(s).
    ///
    func enumerateGhostLayers(callback: (GhostLayer) -> Void) {
        enumerateGhostableLeafViews { leafView in
            let targetLayer = leafView.layer.sublayers?.first(where: { $0 is GhostLayer })
            guard let skeletonLayer = targetLayer as? GhostLayer else {
                return
            }
            
            callback(skeletonLayer)
        }
    }
}


/// Private Methods
///
private extension UIView {
    
    /// Indicates if the receiver contains a GhostLayer.
    ///
    var containsGhostLayer: Bool {
        let output = layer.sublayers?.contains { $0 is GhostLayer }
        return output ?? false
    }
    
    /// Indicates if the receiver's classname starts with an underscore (UIKit's internals).
    ///
    var isPrivateUIKitInstance: Bool {
        let classnameWithoutNamespaces = NSStringFromClass(type(of: self)).components(separatedBy: ".").last
        return classnameWithoutNamespaces?.starts(with: "_") ?? false
    }
    
    /// Enumerates all of the receiver's Leaf Views.
    ///
    func enumerateGhostableLeafViews(callback: (UIView) -> ()) {
        guard !isGhostableDisabled && !isPrivateUIKitInstance else {
            return
        }
        
        if subviews.isEmpty {
            callback(self)
        } else {
            for subview in subviews {
                subview.enumerateGhostableLeafViews(callback: callback)
            }
        }
    }
}


// MARK: - Ghost Animations API
//
extension UIView {
    
    /// Property that defines if a view is ghostable. Defaults set to true.
    ///
    public var isGhostableDisabled: Bool {
        get {
            return objc_getAssociatedObject(self, &Keys.isGhostable) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &Keys.isGhostable, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// Applies Ghost Layers and starts the Beating Animation.
    ///
    public func startGhostAnimation(style: GhostStyle = .default) {
        insertGhostLayers { layer in
            layer.startAnimating(fromColor: style.beatStartColor, toColor: style.beatEndColor, duration: style.beatDuration)
        }
    }
    
    /// Loops thru all of the Ghost Layers (that are already there) and restarts the Beating Animation.
    /// If there were no previous Ghost Layers inserted, this method won't do anything.
    ///
    public func restartGhostAnimation(style: GhostStyle = .default) {
        enumerateGhostLayers { layer in
            layer.startAnimating(fromColor: style.beatStartColor, toColor: style.beatEndColor, duration: style.beatDuration)
        }
    }
    
    /// Removes the Ghost Layers.
    ///
    public func stopGhostAnimation() {
        enumerateGhostLayers { layer in
            layer.removeFromSuperlayer()
        }
    }
}

// MARK: - Nested Types
//
private extension UIView {
    
    enum Keys {
        static var isGhostable = 0x1000
    }
}
