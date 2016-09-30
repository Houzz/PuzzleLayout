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

public enum InvalidationElementCategory {
    case cell(indexPath: IndexPath)
    
    case supplementaryView(indexPath: IndexPath, elementKind: String)
    
    case decorationView(indexPath: IndexPath, elementKind: String)
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
    func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool
    func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any?
    // --------
    
    //Seprator line
    var separatorLineStyle: PuzzlePieceSeparatorLineStyle { get }
    var separatorLineInsets: UIEdgeInsets { get } ///If not implemented & separatorLineType != .none, left=15.
    var separatorLineColor: UIColor? { get } ///If not implemented & separatorLineType != .none, color=0xD6D6D6
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
    public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool { return false }
    public func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? { return nil }
    // --------
    
    //Seprator line
    public var separatorLineStyle: PuzzlePieceSeparatorLineStyle { return .none }
    public var separatorLineInsets: UIEdgeInsets { return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) }
    public var separatorLineColor: UIColor? { return nil }
    // --------
}
