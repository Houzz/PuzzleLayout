//
//  PuzzleCollectionViewLayoutAttributes.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 29/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

final public class PuzzleCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes {
    var cachedSize: CGSize? = nil
    var info: Any? = nil
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let c = super.copy(with: zone)
        if let c = c as? PuzzleCollectionViewLayoutAttributes {
            c.cachedSize = self.cachedSize
            c.info = self.info
        }
        return c
    }
}
