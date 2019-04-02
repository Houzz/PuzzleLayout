//
//  PuzzlePieceSectionLayout.swift
//  PuzzleLayout
//
//  Created by Yossi Avramov on 30/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

/// A separator lines style applied to each cell in a section
public enum PuzzlePieceSeparatorLineStyle : Int {
    
    /// No separator line a all
    case none
    
    /// Add separator line for each cell but the last one. Very useful on rows layout for example.
    case allButLastItem
    
    /// Add separator line for each cell in the section.
    case all
}

/// A protocol for section support gutters
public protocol PuzzlePieceSectionLayoutSeperatable {
    var sectionInsets: UIEdgeInsets { get set }
    var showTopGutter: Bool { get set }
    var showBottomGutter: Bool { get set }
}

/// An invalidation category. Used to ask a section layout on attributes invalidation for preferred size.
public enum InvalidationElementCategory {
    
    /// Ask if should invalidate a cell in the given index
    case cell(index: Int)
    
    /// Ask if should invalidate a supplementary with element kind in the given index
    case supplementaryView(index: Int, elementKind: String)
    
    /// Ask if should invalidate a decoration with element kind in the given index
    case decorationView(index: Int, elementKind: String)
}

/// An enum giving the reason for invalidation
public enum SectionUpdate {
    case insertItems(at: [Int])
    
    case deleteItems(at: [Int])
    
    case reloadItems(at: [Int])
    
    case moveItem(at: Int, to: Int)
}

/// An enum giving the reason for invalidation
public enum InvalidationReason : Int {
    
    /// Invalidating for reloadData
    case reloadData
    
    /// Invalidating for changing collection view layout or the collection view data source
    case changeCollectionViewLayoutOrDataSource
    
    /// Invalidating for insert/delete/move items
    case reloadDataForUpdateDataSourceCounts
    
    /// Invalidating for resetting layout
    case resetLayout
    
    /// Invalidating for other reason (For example, self-sizing invalidation, collection view width changed, a specific section layout ask for invalidation)
    case otherReason
    
    case changePreferredLayoutAttributes
}

//MARK: - PuzzlePieceSectionLayout

/// A base class for section layout. Should not be used directly, Only as subclass. This layout is responsible for layouting all elements in one section, and only one. One instance should be used for multiple sections.
public class PuzzlePieceSectionLayout {
    
    /// An section identifier. Can be used for re-use.
    public var identifier: String?
    
    /// The collection view layout which hold this section layout as one if it layouts.
    public internal(set) weak var parentLayout: PuzzleCollectionViewLayout?
    
    /// The section index this layout responsible for.
    public internal(set) var sectionIndex: Int?
    
    /// The number of items in the section.
    public internal(set) var numberOfItemsInSection: Int = 0
    
    /**
     A PuzzlePieceSeparatorLineStyle value indicating if auto seprator lines should be generated by parentLayout.
     
     Default, no separator lines.
     */
    public var separatorLineStyle: PuzzlePieceSeparatorLineStyle = .none {
        didSet {
            if let ctx = self.invalidationContextForSeparatorLines(for: separatorLineStyle, oldStyle: oldValue) {
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    /**
     A UIEdgeInsets value indicating the left & right insets from the cell bounds for each separator line when 'separatorLineStyle != .none'.
     
     Default, left & right is 0.
     */
    public var separatorLineInsets: UIEdgeInsets = .zero {
        didSet {
            if separatorLineInsets != .zero, let ctx = self.invalidationContextForSeparatorLines(for: separatorLineStyle) {
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }

    /**
     A UIColor value indicating the separator line color when 'separatorLineStyle != .none'. If color is nil, the separator line color will be the parentLayout default color for separator views
     
     Default, nil.
     */
    public var separatorLineColor: UIColor? = nil
    
    //MARK: - Should be override by subclasses
    
    ///The total height of the section. A subclass must override this property and return its actual height. The default implementation returns 0.
    public var heightOfSection: CGFloat {
        assert(false, "'heightOfSection' Should be implemented by subclass")
        return 0
    }
    
    /**
     Indicating when parentLayout got invalidated and this section might be interest about this invalidation.
     
     Default implementation does nothing
     
     - parameter reason: The reason for invalidation.
     
     - parameter info: The info of invalidation related to this section. This info usually generated by the section layout itself.
    */
    public func invalidate(for reason: InvalidationReason, with info: Any?) {}
    
    /**
     Indicating that a specific item has been invalidated.
     
     Default implementation does nothing
     
     - parameter index: The item index.
     */
    public func invalidateItem(at index: Int) {}
    
    /**
     Indicating that a specific supplementary view has been invalidated.
     
     Default implementation does nothing
     
     - parameter elementKind: The supplementary view element kind.
     
     - parameter index: The item index.
     */
    public func invalidateSupplementaryView(ofKind elementKind: String, at index: Int) {}
    
    /**
     Indicating that a specific decoration view has been invalidated.
     
     Default implementation does nothing
     
     - parameter elementKind: The decoration view element kind.
     
     - parameter index: The item index.
     */
    public func invalidateDecorationView(ofKind elementKind: String, at index: Int) {}
    
    /**
     Notify the section layout to prepare for layout. This is the place to make all computation, in which, at the end all elements location in the section in known.
     
     Default implementation does nothing
     
     - parameter reason: The reason caused invalidation & prepare
     
     - parameter updates: If reason is 'reloadDataForUpdateDataSourceCounts' and there're updates related to this section, you'll get prepare call with the changes
     */
    public func prepare(for reason: InvalidationReason, updates: [SectionUpdate]?) {}
    
    /**
     Notifing that this section layout will not be used any longer. Called when this section layout was returned by 'CollectionViewDataSourcePuzzleLayout' last time, but this time wasn't.
     
     Default implementation does nothing
     */
    public func tearDown() {}
    
    /**
     Returns the layout attributes for all of the cells and views in the specified rectangle.
     Subclasses must override this method and use it to return layout information for all items whose view intersects the specified rectangle. Your implementation should return attributes for all visual elements, including cells, supplementary views, and decoration views.
     When creating the layout attributes, always create an attributes object that represents the correct element type (cell, supplementary, or decoration). The collection view differentiates between attributes for each type and uses that information to make decisions about which views to create and how to manage them.
     
     - parameter rect: The rectangle (specified in the section’s coordinate system) containing the target views.
     
     - parameter sectionIndex: The section index to create with PuzzleCollectionViewLayoutAttributes instances.
     
     - returns: An array of PuzzleCollectionViewLayoutAttributes objects representing the layout information for the cells and views. The default implementation returns empty list.
     */
    public func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes] {
        assert(false, "'layoutAttributesForElements(in:sectionIndex:)' Should be implemented by subclass")
        return []
    }
    
    /**
     Returns the layout attributes for the item at the specified index path.
     Subclasses must override this method and use it to return layout information for items in the collection view. You use this method to provide layout information only for items that have a corresponding cell. Do not use it for supplementary views or decoration views.
     The default implementation of this method returns nil.
     
     - parameter indexPath: The index path of the item.
     
     - returns: A layout attributes object containing the information to apply to the item’s cell.
     */
    public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the layout attributes for the specified supplementary view.
     If your layout object defines any supplementary views, you must override this method and use it to return layout information for those views.
     The default implementation of this method returns nil.
     
     - parameter elementKind: A string that identifies the type of the supplementary view.
     
     - parameter indexPath: The index path of the view.
     
     - returns: A layout attributes object containing the information to apply to the supplementary view.
    */
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the layout attributes for the specified decoration view.
     If your layout object defines any decoration views, you must override this method and use it to return layout information for those views.
     The default implementation of this method returns nil.
     
     - parameter elementKind: A string that identifies the type of the decoration view.
     
     - parameter indexPath: The index path of the decoration view.
     
     - returns: A layout attributes object containing the information to apply to the decoration view.
    */
    public func layoutAttributesForDecorationView(ofKind elementKind: String, at : IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
    Returns the starting layout information for an item being inserted into the collection view.
    This method is called after the prepare(forCollectionViewUpdates:) method and before the finalizeCollectionViewUpdates() method for any items that are about to be inserted. Your implementation should return the layout information that describes the initial position and state of the item. The collection view uses this information as the starting point for any animations. (The end point of the animation is the item’s new location in the collection view.) If you return nil, the layout object uses the item’s final attributes for both the start and end points of the animation.
    The default implementation of this method returns nil.
     
     - parameter itemIndexPath: The index path of the item being inserted.
    
     - returns: A layout attributes object that describes the position at which to place the corresponding cell.
     */
    public func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the final layout information for an item that is about to be removed from the collection view.
     This method is called after the prepare(forCollectionViewUpdates:) method and before the finalizeCollectionViewUpdates() method for any items that are about to be deleted. Your implementation should return the layout information that describes the final position and state of the item. The collection view uses this information as the end point for any animations. (The starting point of the animation is the item’s current location.) If you return nil, the layout object uses the same attributes for both the start and end points of the animation.
     The default implementation of this method returns nil.
     
     - parameter itemIndexPath: The index path of the item being deleted.
     
     - returns: A layout attributes object that describes the position of the cell to use as the end point for animating its removal.
    */
    public func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the starting layout information for a supplementary view being inserted into the collection view.
     This method is called after the prepare(forCollectionViewUpdates:) method and before the finalizeCollectionViewUpdates() method for any supplementary views that are about to be inserted. Your implementation should return the layout information that describes the initial position and state of the view. The collection view uses this information as the starting point for any animations. (The end point of the animation is the view’s new location in the collection view.) If you return nil, the layout object uses the item’s final attributes for both the start and end points of the animation.
     The default implementation of this method returns nil.
     
     - parameter elementKind: A string that identifies the type of supplementary view.
     
     - parameter elementIndexPath: The index path of the item being inserted.
     
     - returns: A layout attributes object that describes the position at which to place the corresponding supplementary view.
    */
    public func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the final layout information for a supplementary view that is about to be removed from the collection view.
     This method is called after the prepare(forCollectionViewUpdates:) method and before the finalizeCollectionViewUpdates() method for any supplementary views that are about to be deleted. Your implementation should return the layout information that describes the final position and state of the view. The collection view uses this information as the end point for any animations. (The starting point of the animation is the view’s current location.) If you return nil, the layout object uses the same attributes for both the start and end points of the animation.
     The default implementation of this method returns nil.
     
     - parameter elementKind: A string that identifies the type of supplementary view.
     
     - parameter elementIndexPath: The index path of the view being deleted.
     
     - returns: A layout attributes object that describes the position of the supplementary view to use as the end point for animating its removal.
    */
    public func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the starting layout information for a decoration view being inserted into the collection view.
     This method is called after the prepare(forCollectionViewUpdates:) method and before the finalizeCollectionViewUpdates() method for any decoration views that are about to be inserted. Your implementation should return the layout information that describes the initial position and state of the view. The collection view uses this information as the starting point for any animations. (The end point of the animation is the view’s new location in the collection view.) If you return nil, the layout object uses the item’s final attributes for both the start and end points of the animation.
     The default implementation of this method returns nil.
     
     - parameter elementKind: A string that identifies the type of decoration view.
     
     - parameter elementIndexPath: The index path of the item being inserted.
     
     - returns: A layout attributes object that describes the position at which to place the corresponding decoration view.
    */
    public func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     Returns the final layout information for a decoration view that is about to be removed from the collection view.
     This method is called after the prepare(forCollectionViewUpdates:) method and before the finalizeCollectionViewUpdates() method for any decoration views that are about to be deleted. Your implementation should return the layout information that describes the final position and state of the view. The collection view uses this information as the end point for any animations. (The starting point of the animation is the view’s current location.) If you return nil, the layout object uses the same attributes for both the start and end points of the animation.
     The default implementation of this method returns nil.
     
     - parameter elementKind: A string that identifies the type of decoration view.
     
     - parameter elementIndexPath: The index path of the view being deleted.
     
     - returns: A layout attributes object that describes the position of the decoration view to use as the end point for animating its removal.
    */
    public func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        return nil
    }
    
    /**
     If one of the elements returned by 'layoutAttributesForElements' is supplementary view with element kind equals to 'PuzzleCollectionElementKindSectionHeader', this function is called to check if parent layout should pin it to collection view bounds.
     The default implementation of this method returns false.
     
     - returns: True is header should be pinned to collection view bounds. Otherwise, return false.
    */
    public func shouldPinHeaderSupplementaryView() -> Bool { return false }
    
    /**
     If one of the elements returned by 'layoutAttributesForElements' is supplementary view with element kind equals to 'PuzzleCollectionElementKindSectionFooter', this function is called to check if parent layout should pin it to collection view bounds.
     The default implementation of this method returns false.
     
     - returns: True is footer should be pinned to collection view bounds. Otherwise, return false.
     */
    public func shouldPinFooterSupplementaryView() -> Bool { return false }
    
    /**
     Notifying that parent layout is about to be invalidated for collection view width change.
     This function can be used if section layout want to get a data on 'invalidate(for:, with:)'
     The default implementation of this method returns nil.
     
     - parameter newWidth: The width which will be set to the collection view.
     
     - parameter currentWidth: The current width of the collection view.
     
     - returns: The info the section want to get on 'invalidate(for:, with:)'. Otherwise, nil.
    */
    public func invalidationInfo(forNewWidth newWidth: CGFloat, currentWidth: CGFloat) -> Any? {
        return nil
    }
    // --------
    
    
    
    // -------- Item attributes invalidation
    /**
     Asks the layout object if changes to a self-sizing cell require a layout update.
     When a collection view includes self-sizing cells, the cells are given the opportunity to modify their own layout attributes before those attributes are applied. A self-sizing cell might do this to specify a different cell size than the one the layout object provides. When the cell provides a different set of attributes, the collection view calls this method to determine if the cell’s change requires a larger layout refresh.
     The default implementation of this method returns false.
     
     - parameter elementCategory: The type of element which ask for self-sizing
     
     - parameter preferredSize: The element preferred size. This is inout property, allowing the section layout to change it. For example, to make sure the width isn't changed, just the height.
     
     - parameter originalSize: The element original size (as returned by this section layout)
     
     - returns: The info the section want to get on 'invalidate(for:, with:)'. Otherwise, nil.
     */
    public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        return false
    }
    
    /**
     If 'shouldInvalidate(for:forPreferredSize:withOriginalSize:) returns true, asking the layout object for info related the invalidation of this element. This info will be given to this section layout on 'invalidate(for:, with:)'
     
     - parameter elementCategory: The type of element been invalidated
     
     - parameter preferredSize: The element new size.
     
     - parameter originalSize: The element original size (as returned by this section layout)
     
     - returns: The info the section want to get on 'invalidate(for:, with:)'. Otherwise, nil.
     */
    public func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? {
        return nil
    }
    // --------
    
    /**
     Returns the point at which to stop scrolling.
     If you want the scrolling behavior to snap to specific boundaries, you can override this method and use it to change the point at which to stop. For example, you might use this method to always stop scrolling on a boundary between items, as opposed to stopping in the middle of an item.
     This function called only on the first visible section.
     The default implementation of this method returns the value in the proposedContentOffset parameter.
     
     - parameter proposedContentOffset: point (in the section’s coordinate system) at which to stop scrolling. This is the value at which scrolling would naturally stop if no adjustments were made. The point reflects the upper-left corner of the visible content.
     
     - parameter velocity: The current scrolling velocity along both the horizontal and vertical axes. This value is measured in points per second.
     
     - returns: The content offset that you want to use instead. This value reflects the adjusted upper-left corner of the visible area.
    */
    func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
}

extension PuzzlePieceSectionLayout {
    
    /// Get the section width (section width equals to collection view width minus the section left & right insets
    public var sectionWidth: CGFloat {
        if let collectionView = parentLayout?.collectionView {
            return collectionView.bounds.width - (collectionView.contentInset.left + collectionView.contentInset.right)
        }
        else {
            return 0
        }
    }
    
    /**
     Get an IndexPath for an item in this section.
     
     - parameter index: The item index.
     
     - returns: The index path of the item. If parentLayout is nil, returns nil.
     */
    public func indexPath(forIndex index: Int) -> IndexPath? {
        guard let sectionIndex = sectionIndex else {
            return nil
        }
        
        return IndexPath(item: index, section: sectionIndex)
    }
    
    /**
     Create a layout invalidation context to use to invalidate the collection view layout.
     If parentLayout is nil, returns nil.
     */
    public var invalidationContext: PuzzleCollectionViewLayoutInvalidationContext? {
        guard let _ = parentLayout else { return nil }
        
        return PuzzleCollectionViewLayoutInvalidationContext()
    }
    
    /**
     Create a layout invalidation context to use to invalidate the collection view layout with info related to this section. This info will be given to this section layout on 'invalidate(for:, with:)'
     
     - parameter info: The invalidation info.
     
     - returns: If parentLayout is nil, returns nil. Otherwise, the invalidation context.
     */
    public func invalidationContext(with info: Any) -> PuzzleCollectionViewLayoutInvalidationContext? {
        guard let sectionIndex = sectionIndex else {
            return nil
        }
        
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.setInvalidationInfo(info, forSectionAtIndex: sectionIndex)
        return ctx
    }
    
    /**
     Set invalidation info related to this section on invalidation context. This info will be given to this section layout on 'invalidate(for:, with:)'
     
     - parameter info: The invalidation info.
     
     - parameter context: The invalidation context.
     
     - returns: If parentLayout is nil, returns false. Otherwise, returns true.
     */
    @discardableResult public func setInvalidationInfo(_ info: Any?, at context: PuzzleCollectionViewLayoutInvalidationContext) -> Bool {
        guard let sectionIndex = sectionIndex else {
            return false
        }
        
        context.setInvalidationInfo(info, forSectionAtIndex: sectionIndex)
        return true
    }
}

