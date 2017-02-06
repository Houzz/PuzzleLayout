//
//  PuzzleCollectionViewLayoutAttributes.swift
//  PuzzleLayout
//
//  Created by Yossi Avramov on 29/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

///A collection view attributes used by 'PuzzleCollectionViewLayout'
@objc final public class PuzzleCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes {
    
    ///The cached size on layout. Can be used on 'systemLayoutSizeFitting(_:)' api call for better performance
    public var cachedSize: CGSize? = nil
    
    ///info property can be used by 'PuzzlePieceSectionLayout' to send more data about the cell. This can't be achieved by subclassing 'PuzzleCollectionViewLayoutAttributes' since it's a final.
    public var info: Any? = nil
    
    ///This property is set to true only for headers & footers which are currrently pinned to collection bounds.
    internal(set) var isPinned: Bool = false
    
    ///The layout margins of the collection view
    internal(set) var layoutMargins: UIEdgeInsets = .zero
    
    private weak var layout: PuzzleCollectionViewLayout? {
        willSet {
            if layout != nil && layout !== newValue {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "InvalidateLivingLayoutAttributes"), object: layout)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "SyncWithAppliedLayoutAttributes"), object: layout)
            }
        }
        didSet {
            if layout != nil && layout !== oldValue {
                NotificationCenter.default.addObserver(self, selector: #selector(PuzzleCollectionViewLayoutAttributes.invalidateMe(_:)), name: NSNotification.Name(rawValue: "InvalidateLivingLayoutAttributes"), object: layout)
            }
        }
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let c = super.copy(with: zone)
        if let c = c as? PuzzleCollectionViewLayoutAttributes {
            c.cachedSize = self.cachedSize
            c.info = self.info
            c.layout = self.layout
        }
        return c
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        if super.isEqual(object) == false {
            return false
        }
        else {
            let attr = (object as! PuzzleCollectionViewLayoutAttributes)
            if self.cachedSize != attr.cachedSize {
                return false
            }
            else if self.isPinned != attr.isPinned {
                return false
            }
            else if self.layoutMargins != attr.layoutMargins {
                return false
            }
            else if self.info == nil && attr.info == nil {
                return true
            }
            else if self.info == nil || attr.info == nil {
                return false
            }
            else if type(of: self.info!) != type(of: attr.info!) {
                return false
            }
            else if self.info! is NSObject {
                return (self.info as! NSObject).isEqual(attr.info!)
            }
            else {
                return false
            }
        }
    }
    
    internal func willBeUsed(by layout: PuzzleCollectionViewLayout) {
        self.layout = layout
    }
    
    @objc private func invalidateMe(_ note: Notification) {
        
        let info = note.userInfo as! [String:Any]
        let minY = info["minOriginY"] as! CGFloat
        guard frame.minY >= minY else {
            return
        }
        
        switch representedElementCategory {
        case .cell:
            let items = info["items"] as! [IndexPath]
            if items.contains(indexPath) == false {
                let update = info["invalidation"] as! ((PuzzleCollectionViewLayoutAttributes) -> Void)
                update(self)
            }
        case .supplementaryView:
            let supplementaries = info["supplementaries"] as! [String:[IndexPath]]
            if (supplementaries[representedElementKind!]?.contains(indexPath) ?? false) == false {
                let update = info["invalidation"] as! ((PuzzleCollectionViewLayoutAttributes) -> Void)
                update(self)
            }
        case .decorationView:
            let decorations = info["decorations"] as! [String:[IndexPath]]
            if (decorations[representedElementKind!]?.contains(indexPath) ?? false) == false {
                let update = info["invalidation"] as! ((PuzzleCollectionViewLayoutAttributes) -> Void)
                update(self)
            }
        }
    }
    
    fileprivate func willBeApplied(on view: UICollectionReusableView) {
        guard let layout = self.layout else {
            return
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SyncWithAppliedLayoutAttributes"), object: layout, userInfo: ["layoutAttributes" : self])
        
        NotificationCenter.default.addObserver(self, selector: #selector(PuzzleCollectionViewLayoutAttributes.syncMe(_:)), name: NSNotification.Name(rawValue: "SyncWithAppliedLayoutAttributes"), object: layout)
    }
    
    @objc private func syncMe(_ note: Notification) {
        guard let layoutAttributes = note.userInfo?["layoutAttributes"] as? PuzzleCollectionViewLayoutAttributes else {
            return
        }
        
        guard layoutAttributes !== self else {
            return
        }
        
        guard representedElementCategory == layoutAttributes.representedElementCategory && indexPath == layoutAttributes.indexPath && representedElementKind == layoutAttributes.representedElementKind else {
            return
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "InvalidateLivingLayoutAttributes"), object: layout)
        self.size = layoutAttributes.size
        self.center = layoutAttributes.center
        self.transform3D = layoutAttributes.transform3D
        self.transform = layoutAttributes.transform
        self.alpha = layoutAttributes.alpha
        self.isHidden = layoutAttributes.isHidden
        self.cachedSize = layoutAttributes.cachedSize
        self.info = layoutAttributes.info
        self.isPinned = layoutAttributes.isPinned
        self.layoutMargins = layoutAttributes.layoutMargins
    }
}

//MARK: UICollectionReusableView utility
private let swizzling: (UICollectionReusableView.Type) -> () = { reusableView in
    let originalSelector = #selector(reusableView.apply(_:))
    let swizzledSelector = #selector(reusableView.myApply(_:))
    
    let originalMethod = class_getInstanceMethod(reusableView, originalSelector)
    let swizzledMethod = class_getInstanceMethod(reusableView, swizzledSelector)
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

extension UICollectionReusableView {
    
    open override class func initialize() {
        guard self == UICollectionReusableView.self else {
            return
        }
        
        swizzling(self)
    }
    
    @objc fileprivate func myApply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        if let puzzleAttributes = layoutAttributes as? PuzzleCollectionViewLayoutAttributes {
            puzzleAttributes.willBeApplied(on: self)
        }
        
        self.myApply(layoutAttributes)
    }
}
