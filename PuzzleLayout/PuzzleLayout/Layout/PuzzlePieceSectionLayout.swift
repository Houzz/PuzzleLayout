//
//  PuzzlePieceSectionLayout.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 30/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

public enum PuzzlePieceSeparatorLineStyle : Int {
    case none
    case allButLastItem
    case all
}

public protocol PuzzlePieceSectionLayoutSeperatable {
    var sectionInsets: UIEdgeInsets { get set }
    var showTopGutter: Bool { get set }
    var showBottomGutter: Bool { get set }
}

public enum InvalidationElementCategory {
    case cell(indexPath: IndexPath)
    
    case supplementaryView(indexPath: IndexPath, elementKind: String)
    
    case decorationView(indexPath: IndexPath, elementKind: String)
}

//MARK: - PuzzlePieceSectionLayout
public class PuzzlePieceSectionLayout {
    
    ///Can used to reuse layouts
    public var identifier: String?
    
    public internal(set) weak var parentLayout: PuzzleCollectionViewLayout?
    
    internal var sectionIndex: Int?
    
    public internal(set) var numberOfItemsInSection: Int = 0
    
    public var separatorLineStyle: PuzzlePieceSeparatorLineStyle = .none {
        didSet {
            if let ctx = self.invalidationContextForSeparatorLines(for: separatorLineStyle, oldStyle: oldValue) {
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    //TODO: make default value .zero and make (top: 0, left: 15, bottom: 0, right: 0) only for rows layout
    public var separatorLineInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) {
        didSet {
            if separatorLineInsets != .none, let ctx = self.invalidationContextForSeparatorLines(for: separatorLineStyle) {
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    public var separatorLineColor: UIColor? = nil
    
    //MARK: - Should be override by subclasses
    public var heightOfSection: CGFloat {
        assert(false, "'heightOfSection' Should be implemented by subclass")
        return 0
    }
    
    public func invalidate(willReloadData: Bool, willUpdateDataSourceCounts: Bool, resetLayout: Bool, info: Any?) {}
    
    public func invalidateItem(at indexPath: IndexPath) {}
    
    public func invalidateSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) {}
    
    public func invalidateDecorationView(ofKind elementKind: String, at indexPath: IndexPath) {}
    
    public func prepare(didReloadData: Bool, didUpdateDataSourceCounts: Bool, didResetLayout: Bool) {}
    
    public func tearDown() {}
    
    public func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes] {
        assert(false, "'layoutAttributesForElements(in:sectionIndex:)' Should be implemented by subclass")
        return []
    }
    
    public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    public func shouldPinHeaderSupplementaryView() -> Bool { return false }
    
    public func shouldPinFooterSupplementaryView() -> Bool { return false }
    
    ///This will be called if bounds width has changed
    public func invalidationInfo(forNewWidth newWidth: CGFloat, currentWidth: CGFloat) -> Any? {
        return nil
    }
    // --------
    
    
    
    // -------- Item attributes invalidation
    
    public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        return false
    }
    
    public func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? {
        return nil
    }
    // --------
    
    // -------- Updates
    public func willGenerateUpdatesCall() {}
    public func didInsertItem(at index: Int) {}
    public func didDeleteItem(at index: Int) {}
    public func didReloadItem(at index: Int) {}
    public func didMoveItem(fromIndex: Int, toIndex: Int) {}
    public func didGenerateUpdatesCall(didHadUpdates: Bool) {}
    // --------
}

extension PuzzlePieceSectionLayout {
    public var sectionWidth: CGFloat {
        if let collectionView = parentLayout?.collectionView {
            return collectionView.bounds.width - (collectionView.contentInset.left + collectionView.contentInset.right)
        }
        else {
            return 0
        }
    }
    
    public var traitCollection: UITraitCollection {
        return parentLayout?.collectionView?.traitCollection ?? UITraitCollection(traitsFrom: [UITraitCollection(horizontalSizeClass: .unspecified),UITraitCollection(verticalSizeClass: .unspecified)])
    }
    
    public func indexPath(forIndex index: Int) -> IndexPath? {
        guard let sectionIndex = sectionIndex else {
            return nil
        }
        
        return IndexPath(item: index, section: sectionIndex)
    }
    
    public var invalidationContext: PuzzleCollectionViewLayoutInvalidationContext? {
        guard let _ = parentLayout else { return nil }
        
        return PuzzleCollectionViewLayoutInvalidationContext()
    }
    
    public func invalidationContext(with info: Any) -> PuzzleCollectionViewLayoutInvalidationContext? {
        guard let sectionIndex = sectionIndex else {
            return nil
        }
        
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.setInvalidationInfo(info, forSectionAtIndex: sectionIndex)
        return ctx
    }
    
    @discardableResult
    public func setInvalidationInfo(_ info: Any?, at context: PuzzleCollectionViewLayoutInvalidationContext) -> Bool {
        guard let sectionIndex = sectionIndex else {
            return false
        }
        context.setInvalidationInfo(info, forSectionAtIndex: sectionIndex)
        return true
    }
}

