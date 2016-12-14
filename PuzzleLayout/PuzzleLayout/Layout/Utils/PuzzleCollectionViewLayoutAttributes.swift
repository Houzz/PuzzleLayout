//
//  PuzzleCollectionViewLayoutAttributes.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 29/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit


@objc final public class PuzzleCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes {
    public var cachedSize: CGSize? = nil
    public var info: Any? = nil
    internal(set) var isPinned: Bool = false
    internal(set) var layoutMargins: UIEdgeInsets = .zero
    
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
