//
//  PuzzlePieceSectionLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 23/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

@objc public enum PuzzlePieceSeparatorLineStyle : Int {
    case none
    case allButLastItem
    case all
}

@objc public protocol PuzzlePieceSectionLayout {
    ///Can used to reuse layouts
    @objc optional var identifier: String? { get }
    
    weak var parentLayout: PuzzleCollectionViewLayout? { get set }
    
    @objc var heightOfSection: CGFloat { get }
    
    @objc optional func prepare(for numberOfItemsInSection: Int, withInvalidation context: PuzzleCollectionViewLayoutInvalidationContext, and info: Any?)
    
    
    @objc optional func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes]
    @objc optional func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes?
    @objc optional func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes?
    @objc optional func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes?
    
    //Bounds invalidation
    @objc optional func mayRequireInvalidationOnOriginChange() -> Bool //Default: false
    @objc func shouldInvalidate(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Bool //This will be called only if mayRequireInvalidationOnOriginChange is true
    @objc func invalidationInfo(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Any? //This will be called if shouldInvalidate(forNewBounds:currentBounds:) returns true of bounds width has changed
    
    //Note: Bounds invalidation functions better should be optional functions. But, on Swift 3 Xcode 8, making it optional cause a compile error: Segmentation Fault 11
    // --------
    
    //Item attributes invalidation
    @objc optional func shouldInvalidate(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool
    @objc optional func invalidationInfo(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Any?
    // --------
    
    //Seprator line
    @objc optional var separatorLineStyle: PuzzlePieceSeparatorLineStyle { get }
    @objc optional var separatorLineInsets: UIEdgeInsets { get } ///If not implemented & separatorLineType != .none, left=15.
    @objc optional var separatorLineColor: UIColor { get } ///If not implemented & separatorLineType != .none, color=0xD6D6D6
    // --------
    
    //Section top & bottom gutters
    @objc optional var topGutterColor: UIColor { get }
    @objc optional var bottomGutterColor: UIColor { get }
    // --------
}
