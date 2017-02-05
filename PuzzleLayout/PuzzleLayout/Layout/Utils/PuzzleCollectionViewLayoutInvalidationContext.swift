//
//  PuzzleCollectionViewLayoutInvalidationContext.swift
//  PuzzleLayout
//
//  Created by Yossi Avramov on 29/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

/// A collection view invalidation context allowing keeping invalidation info for each section layout
final public class PuzzleCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext {
    
    /// Dictionary for saving invalidation info for each section layout
    private var _invalidationInfo: [Int:Any] = [:]
    
    /**
     A Boolean indicating if need to invalidate all sections layout.
     
     When 'invalidateSectionsLayout == true', collection view data source will be asked again for PuzzlePieceSectionLayout for each section.
     */
    public let invalidateSectionsLayout: Bool
    
    /**
     The 'PuzzlePieceSectionLayout' for which the invalidation context was created.
     
     When 'PuzzlePieceSectionLayout' is not nil, only this layout will be informed on invalidation with the info related it (if there's related info)
     */
    public var invalidateSectionLayoutData: PuzzlePieceSectionLayout? = nil
    
    override init() {
        self.invalidateSectionsLayout = false
        super.init()
    }
    
    /**
     Create an invalidation context to reset all sections layout
     
     - parameter invalidateSectionsLayout: A flag indicating if all sections layout should be reset
     */
    public init(invalidateSectionsLayout: Bool) {
        self.invalidateSectionsLayout = invalidateSectionsLayout
        super.init()
    }
    
    /**
     Setting an invalidation info for specific 'PuzzlePieceSectionLayout'
     
     This function should be used only by 'PuzzleCollectionViewLayout' instance or by 'PuzzlePieceSectionLayout' instance (subclasses of 'PuzzlePieceSectionLayout' should not access it directly). To create an invalidation context with invalidation info for specific section layout, use 'PuzzlePieceSectionLayout' api call 'invalidationContext(with:)'.
     
     - parameter info: The info to set for the section layout
     
     - parameter sectionIndex: The section index
     */
    public func setInvalidationInfo(_ info: Any?, forSectionAtIndex sectionIndex: Int) {
        _invalidationInfo[sectionIndex] = info
    }
    
    /**
     Getting an invalidation info for specific 'PuzzlePieceSectionLayout' (if there any)
     
     This function should be used only by 'PuzzleCollectionViewLayout'. This info will be sent to the specific 'PuzzlePieceSectionLayout' instance on 'invalidate(for:with:)' api call.
     
     - parameter sectionIndex: The section index
     
     - returns: The info related to the section at the given index (if there's any)
     */
    public func invalidationInfo(forSectionAtIndex sectionIndex: Int) -> Any? {
        return _invalidationInfo[sectionIndex]
    }
    
    /**
     The dictionary of invalidation info-s for each section
     */
    internal var invalidationInfo: [Int:Any] { return _invalidationInfo }
    
    /// The invalidation reason this context was created for.
    var invalidationReason: InvalidationReason {
        if invalidateEverything && invalidateDataSourceCounts { return .reloadData }
        else if invalidateEverything { return .changeCollectionViewLayoutOrDataSource }
        else if invalidateDataSourceCounts { return .reloadDataForUpdateDataSourceCounts }
        else if invalidateSectionsLayout { return .resetLayout }
        else { return .otherReason }
    }
}
