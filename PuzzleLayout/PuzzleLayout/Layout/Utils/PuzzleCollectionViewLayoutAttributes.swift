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
    internal(set) public var layoutMargins: UIEdgeInsets = .zero
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let c = super.copy(with: zone)
        if let c = c as? PuzzleCollectionViewLayoutAttributes {
            c.cachedSize = self.cachedSize
            c.info = self.info
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
}
