//
//  PuzzleCollectionViewLayoutInvalidationContext.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 29/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

final public class PuzzleCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext {
    private var _invalidationInfo: [Int:Any] = [:]
    public var invalidateForWidthChange: Bool
    public let invalidateSectionsLayout: Bool
    public var invalidateSectionLayoutData: PuzzlePieceSectionLayout? = nil
    
    override init() {
        self.invalidateSectionsLayout = false
        self.invalidateForWidthChange = false
        super.init()
    }
    
    public init(invalidateSectionsLayout: Bool) {
        self.invalidateSectionsLayout = invalidateSectionsLayout
        self.invalidateForWidthChange = false
        super.init()
    }
    
    func setInvalidationInfo(_ info: Any?, forSectionAtIndex sectionIndex: Int) {
        _invalidationInfo[sectionIndex] = info
    }
    
    func invalidationInfo(forSectionAtIndex sectionIndex: Int) -> Any? {
        return _invalidationInfo[sectionIndex]
    }
    
    var invalidationInfo: [Int:Any] { return _invalidationInfo }
}
