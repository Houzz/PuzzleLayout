//
//  PuzzlePieceSectionLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 23/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

public enum PuzzlePieceSeparatorLineStyle : Int {
    case none
    case allButLastItem
    case all
}

public protocol PuzzlePieceSectionLayout : NSObjectProtocol {
    ///Can used to reuse layouts
    var identifier: String? { get }
    
    weak var parentLayout: PuzzleCollectionViewLayout? { get set }
    
    var heightOfSection: CGFloat { get }
    
    func prepare(for numberOfItemsInSection: Int, withInvalidation context: PuzzleCollectionViewLayoutInvalidationContext, and info: Any?)
    
    func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes]
    func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes?
    func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes?
    func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes?
    
    //Bounds invalidation
    func mayRequireInvalidationOnOriginChange() -> Bool //Default: false
    func shouldInvalidate(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Bool //This will be called only if mayRequireInvalidationOnOriginChange is true
    func invalidationInfo(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Any? //This will be called if shouldInvalidate(forNewBounds:currentBounds:) returns true of bounds width has changed
    // --------
    
    //Item attributes invalidation
    func shouldInvalidate(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool
    func invalidationInfo(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Any?
    // --------
    
    //Seprator line
    var separatorLineStyle: PuzzlePieceSeparatorLineStyle { get }
    var separatorLineInsets: UIEdgeInsets { get } ///If not implemented & separatorLineType != .none, left=15.
    var separatorLineColor: UIColor { get } ///If not implemented & separatorLineType != .none, color=0xD6D6D6
    // --------
    
    //Section top & bottom gutters
    var topGutterHeight: CGFloat { get }
    var topGutterColor: UIColor { get } ///If not implemented & separatorLineType != .none, color=0xD6D6D6
    
    var bottomGutterHeight: CGFloat { get }
    var bottomGutterColor: UIColor { get } ///If not implemented & separatorLineType != .none, color=0xD6D6D6
    // --------
}

//MARK: - Default implementation
extension PuzzlePieceSectionLayout {
    public var identifier: String? { return nil }
    
    public func prepare(for numberOfItemsInSection: Int, withInvalidation context: PuzzleCollectionViewLayoutInvalidationContext, and info: Any?) {}
    
    public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? { return nil }
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? { return nil }
    public func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? { return nil }
    
    //Bounds invalidation
    public func mayRequireInvalidationOnOriginChange() -> Bool { return false }
    public func shouldInvalidate(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Bool { return false }
    public func invalidationInfo(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Any? { return nil }
    // --------
    
    //Item attributes invalidation
    public func shouldInvalidate(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool { return false }
    public func invalidationInfo(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Any? { return nil }
    // --------
    
    //Seprator line
    public var separatorLineStyle: PuzzlePieceSeparatorLineStyle { return .none }
    public var separatorLineInsets: UIEdgeInsets { return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) }
    public var separatorLineColor: UIColor { return UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1) }
    // --------
    
    //Section top & bottom gutters
    public var topGutterHeight: CGFloat { return 0 }
    public var topGutterColor: UIColor { return UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1) }
    
    public var bottomGutterHeight: CGFloat { return 0 }
    public var bottomGutterColor: UIColor { return UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1) }
    // --------
}
