//
//  PuzzleCollectionViewLayout.swift
//  CollectionTest
//
//  Created by Yossi Avramov on 23/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

//MARK: - CollectionViewDataSourcePuzzleLayout

/// Extension of UICollectionViewDataSource
public protocol CollectionViewDataSourcePuzzleLayout : UICollectionViewDataSource {
    
    /**
     Asking for section layout.
     
     *A good practice for using 'PuzzleCollectionViewLayout' is to set for each 'PuzzlePieceSectionLayout' an identifier. When this function get called, try to dequeue a section layout with the identifier from 'collectionViewLayout' by calling 'sectionLayout(for:)'. Only if the nil returned, create a new 'PuzzlePieceSectionLayout' and return it. In addition, each section must(!!!) have different 'PuzzlePieceSectionLayout' object.*
     **
     
     **Don't use same 'PuzzlePieceSectionLayout' object for multiple section, even if their should have same layout, since each 'PuzzlePieceSectionLayout' keeps data related to its section location in the collection view and its elements.**
     
     - parameter collectionView: The collection view.
     
     - parameter collectionViewLayout: The puzzle collection view layout asking for this section layout.
     
     - parameter index: The section index.
     
     - returns: The section layout responsible for layouting the elements in the given section index.
    */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout
}

//MARK: - PuzzleCollectionViewLayout

/**
 This is the main class of puzzle layout. Puzzle layout let you define a different layout for each section. You can use one of ready-to-use layouts: 'RowsPuzzlePieceSectionLayout', 'ColumnBasedPuzzlePieceSectionLayout', or write one by your own. A section piece layout can be grid based layout, or any complex layouy you can think of. Puzzle layout make it easy to dynamiclly change sections order, adding new sections & removing old ones. No need to re-write the entire collection view layout. Writing new section puzzle piece layout is much more easy, since you can focus only on the section needs, without think about other sections layout.
 ** Puzzle layout is a vertical layout **
 
 When setting collection view layout as 'PuzzleCollectionViewLayout', collection view data source must conform to 'CollectionViewDataSourcePuzzleLayout'
 
 'PuzzleCollectionViewLayout' is final and can't be subclassed. 'PuzzleCollectionViewLayout' is supported for Swift only.
 */
final public class PuzzleCollectionViewLayout: UICollectionViewLayout {
    
    /// The list of current sections layout
    fileprivate var sectionsLayoutInfo: [PuzzlePieceSectionLayout] = []
    
    //MARK: - Init
    override public init() {
        super.init()
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        register(ColoredDecorationView.self, forDecorationViewOfKind: PuzzleCollectionElementKindSeparatorLine)
        register(ColoredDecorationView.self, forDecorationViewOfKind: PuzzleCollectionElementKindSectionTopGutter)
        register(ColoredDecorationView.self, forDecorationViewOfKind: PuzzleCollectionElementKindSectionBottomGutter)
    }
    
    //MARK: - Public
    
    /// Reload all sections layout. When this function get called, collection view data source will get 'collectionView(_:layout:layoutForSectionAtIndex:)' called for each section.
    public func reloadSectionsLayout() {
        let context = PuzzleCollectionViewLayoutInvalidationContext(invalidateSectionsLayout: true)
        invalidateLayout(with: context)
    }
    
    /**
     Get a section layout for a given identifier.
     
     - parameter identifier: The section layout identifier.
     
     - returns: The section layout with same identifier, if such exist.
    */
    public func sectionLayout(for identifier: String) -> PuzzlePieceSectionLayout? {
        return sectionsLayoutInfo.filter ({ (layout: PuzzlePieceSectionLayout) -> Bool in
            if let layoutIdentifier = layout.identifier {
                return layoutIdentifier == identifier
            }
            else {
                return false
            }
        }).first
    }
    
    /// A UIColor value indicating the default color to be used for separator lines & section gutters.
    public var separatorLineColor: UIColor? {
        didSet {
            let ctx = PuzzleCollectionViewLayoutInvalidationContext()
            for (sectionIndex, sectionInfo) in sectionsLayoutInfo.enumerated() {
                switch sectionInfo.separatorLineStyle {
                case .allButLastItem:
                    if sectionInfo.numberOfItemsInSection > 0 {
                        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<(sectionInfo.numberOfItemsInSection-1)))
                    }
                case .all:
                    if sectionInfo.numberOfItemsInSection != 0 {
                        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<sectionInfo.numberOfItemsInSection))
                    }
                default: break
                }
            }
            invalidateLayout(with: ctx)
        }
    }
    
    //MARK: - Override
    override public class var layoutAttributesClass : AnyClass {
        return PuzzleCollectionViewLayoutAttributes.self
    }
    
    override public class var invalidationContextClass : AnyClass {
        return PuzzleCollectionViewLayoutInvalidationContext.self
    }
    
    override public var collectionViewContentSize: CGSize {
        var height: CGFloat = 0
        for layoutInfo in sectionsLayoutInfo {
            height += layoutInfo.heightOfSection
        }
        
        return CGSize(width: collectionView!.bounds.width, height: height)
    }
    
    override public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        guard let ctx = (context as? PuzzleCollectionViewLayoutInvalidationContext) else {
            assert(false, "Invalidation context should be of type 'PuzzleCollectionViewLayoutInvalidationContext'")
            return
        }
        
        let invalidationReason = ctx.invalidationReason
        if !reloadingDataForInvalidationBug {
            if invalidationReasons == nil { invalidationReasons = [] }
            invalidationReasons!.append((reason: invalidationReason, updates: dataSourceUpdates))
            dataSourceUpdates = nil
        }
        
        if ((ctx.invalidateEverything || ctx.invalidateDataSourceCounts) && !reloadingDataForInvalidationBug) || ctx.invalidateSectionsLayout {
            for sectionLayout in sectionsLayoutInfo {
                //TODO: if reason is .reloadDataForUpdateDataSourceCounts, prepare now all the updates (instead of in 'prepare')
                sectionLayout.invalidate(for: invalidationReason, with: nil)
            }
        }
        else {
            let invalidationInfo = ctx.invalidationInfo
            if let layout = ctx.invalidateSectionLayoutData {
                layout.invalidate(for: .otherReason, with: invalidationInfo[layout.sectionIndex!])
            }
            else {
                
                let updatedSpecificView = !(
                    (ctx.invalidatedItemIndexPaths?.isEmpty ?? true)
                        || (ctx.invalidatedSupplementaryIndexPaths?.isEmpty ?? true)
                        || (ctx.invalidatedDecorationIndexPaths?.isEmpty ?? true)
                )
                
                if let invalidatedItemIndexPaths = ctx.invalidatedItemIndexPaths {
                    for indexPath in invalidatedItemIndexPaths {
                        sectionsLayoutInfo[indexPath.section].invalidateItem(at: indexPath.item)
                    }
                }
                
                if let invalidatedSupplementaryIndexPaths = ctx.invalidatedSupplementaryIndexPaths {
                    for (elementKind, indexPaths) in invalidatedSupplementaryIndexPaths {
                        for indexPath in indexPaths {
                            sectionsLayoutInfo[indexPath.section].invalidateSupplementaryView(ofKind: elementKind, at: indexPath.item)
                        }
                    }
                }
                
                if let invalidatedDecorationIndexPaths = ctx.invalidatedDecorationIndexPaths {
                    for (elementKind, indexPaths) in invalidatedDecorationIndexPaths {
                        for indexPath in indexPaths {
                            sectionsLayoutInfo[indexPath.section].invalidateDecorationView(ofKind: elementKind, at: indexPath.item)
                        }
                    }
                }
                
                if !updatedSpecificView {
                    for (index,info) in invalidationInfo {
                        sectionsLayoutInfo[index].invalidate(for: .otherReason, with: info)
                    }
                }
            }
        }
        
        super.invalidateLayout(with: context)
    }
    
    fileprivate var reloadingDataForInvalidationBug: Bool = false
    fileprivate var dataSourceUpdates: [CollectionViewUpdate]?
    fileprivate var invalidationReasons: [(reason: InvalidationReason, updates: [CollectionViewUpdate]?)]?
    
    override public func prepare() {
        if let invalidationReasons {
            reasonsLoop: for invalidation in invalidationReasons {
                switch invalidation.reason {
                case .reloadData, .changeCollectionViewLayoutOrDataSource, .resetLayout:
                    prepareSectionsLayout()
                    for sectionLayout in sectionsLayoutInfo {
                        sectionLayout.prepare(for: invalidation.reason, updates: nil)
                    }
                    break reasonsLoop //No need to continue processing all other reasons
                case .reloadDataForUpdateDataSourceCounts:
                    if let dataSource = collectionView!.dataSource as? CollectionViewDataSourcePuzzleLayout {
                        var sectionUpdates: [Int:[SectionUpdate]] = [:]
                        for update in invalidation.updates ?? [] {
                            switch update {
                            case .insertSections(let sections):
                                for index in sections.sorted(by: { $0 < $1 }) {
                                    let numberOfItems = collectionView!.numberOfItems(inSection: index)
                                    let layout = dataSource.collectionView(collectionView!, layout: self, layoutForSectionAtIndex: index)
                                    layout.parentLayout = self
                                    layout.numberOfItemsInSection = numberOfItems
                                    layout.sectionIndex = index
                                    sectionsLayoutInfo.insert(layout, at: index)
                                    layout.prepare(for: .reloadData, updates: nil)
                                }
                            case .deleteSections(let sections):
                                for index in sections.sorted(by: { $1 < $0 }) {
                                    let layout = sectionsLayoutInfo.remove(at: index)
                                    layout.tearDown()
                                }
                            case .reloadSections(let sections):
                                for index in sections {
                                    let numberOfItems = collectionView!.numberOfItems(inSection: index)
                                    let layout = dataSource.collectionView(collectionView!, layout: self, layoutForSectionAtIndex: index)
                                    layout.parentLayout = self
                                    layout.numberOfItemsInSection = numberOfItems
                                    layout.sectionIndex = index
                                    sectionsLayoutInfo[index] = layout
                                    layout.prepare(for: .reloadData, updates: nil)
                                }
                            case .moveSection(let fromIndex, let toIndex):
                                sectionsLayoutInfo.swapAt(fromIndex, toIndex)
                            case .insertItems(let indexPaths):
                                var updates: [Int:[Int]] = [:]
                                for indexPath in indexPaths {
                                    updates[indexPath.section] = (updates[indexPath.section] ?? []) + [indexPath.item]
                                }
                                
                                for (section, indexes) in updates {
                                    sectionUpdates[section] = (sectionUpdates[section] ?? []) + [SectionUpdate.insertItems(at: indexes)]
                                }
                            case .deleteItems(let indexPaths):
                                var updates: [Int:[Int]] = [:]
                                for indexPath in indexPaths {
                                    updates[indexPath.section] = (updates[indexPath.section] ?? []) + [indexPath.item]
                                }
                                
                                for (section, indexes) in updates {
                                    sectionUpdates[section] = (sectionUpdates[section] ?? []) + [SectionUpdate.deleteItems(at: indexes)]
                                }
                            case .reloadItems(let indexPaths):
                                var updates: [Int:[Int]] = [:]
                                for indexPath in indexPaths {
                                    updates[indexPath.section] = (updates[indexPath.section] ?? []) + [indexPath.item]
                                }
                                
                                for (section, indexes) in updates {
                                    sectionUpdates[section] = (sectionUpdates[section] ?? []) + [SectionUpdate.reloadItems(at: indexes)]
                                }
                            case .moveItem(let fromIndexPath, let toIndexPath):
                                if fromIndexPath.section == toIndexPath.section {
                                    sectionUpdates[fromIndexPath.section] = (sectionUpdates[fromIndexPath.section] ?? []) + [SectionUpdate.moveItem(at: fromIndexPath.item, to: toIndexPath.item)]
                                }
                                else {
                                    sectionUpdates[fromIndexPath.section] = (sectionUpdates[fromIndexPath.section] ?? []) + [SectionUpdate.deleteItems(at: [fromIndexPath.item])]
                                    sectionUpdates[toIndexPath.section] = (sectionUpdates[toIndexPath.section] ?? []) + [SectionUpdate.insertItems(at: [toIndexPath.item])]
                                }
                            }
                        }
                        
                        let numberOfSections = collectionView!.numberOfSections
                        assert(sectionsLayoutInfo.count == numberOfSections, "Updates aren't contains all updates")
                        if sectionsLayoutInfo.count != numberOfSections {
                            prepareSectionsLayout()
                            for sectionLayout in sectionsLayoutInfo {
                                sectionLayout.prepare(for: .reloadData, updates: nil)
                            }
                        }
                        else {
                            for (index, _) in sectionsLayoutInfo.enumerated() {
                                sectionsLayoutInfo[index].sectionIndex = index
                                sectionsLayoutInfo[index].numberOfItemsInSection = collectionView!.numberOfItems(inSection: index)
                                if let updates = sectionUpdates[index] , updates.isEmpty == false {
                                    sectionsLayoutInfo[index].prepare(for: .reloadDataForUpdateDataSourceCounts, updates: updates)
                                }
                            }
                        }
                    }
                case .otherReason, .changePreferredLayoutAttributes:
                    for sectionLayout in sectionsLayoutInfo {
                        sectionLayout.prepare(for: invalidation.reason, updates: nil)
                    }
                }
            }
        }
        
        invalidationReasons = nil
        super.prepare()
    }

    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var lastY: CGFloat = 0
        let width = collectionView!.bounds.width

        for sectionIndex in 0 ..< sectionsLayoutInfo.count {
            let layout = sectionsLayoutInfo[sectionIndex]
            assert(sectionIndex == layout.sectionIndex!, "Something went wrong. This shouldn't happen")
            let sectionHeight = layout.heightOfSection
            let sectionFrame = CGRect(x: 0, y: lastY, width: width, height: sectionHeight)
            if sectionFrame.contains(proposedContentOffset) {
                let pointInSection = CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y - lastY)
                let proposedPointInSection = layout.targetContentOffset(forProposedContentOffset: pointInSection, withScrollingVelocity: velocity)
                return CGPoint(x: proposedPointInSection.x, y: proposedPointInSection.y + lastY)
            }
            lastY += sectionHeight
        }

        return proposedContentOffset
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var allAttributes: [PuzzleCollectionViewLayoutAttributes] = []
        var lastY: CGFloat = 0
        
        let width = collectionView!.bounds.width
        
        //Iterate over each section layout
        for sectionIndex in 0 ..< sectionsLayoutInfo.count {
            let layout = sectionsLayoutInfo[sectionIndex]
            assert(sectionIndex == layout.sectionIndex!, "Something went wrong. This shouldn't happen")
            
            let sectionHeight = layout.heightOfSection
            let sectionFrame = CGRect(x: 0, y: lastY, width: width, height: sectionHeight)
            
            //Check if section intersects & get its elements layout attributes
            let intersection = rect.intersection(sectionFrame)
            
            if intersection.height > 0 { //Section intersects with rect
                let rectInSectionBounds = CGRect(origin: CGPoint(x: intersection.minX, y: intersection.minY - lastY), size: intersection.size)
                
                //Ask for layout attributes depend the required data info required
                
                //Get items without specifying any information about section origin. Then update for each layout attributes its origin Y
                var items: [PuzzleCollectionViewLayoutAttributes]
                
                //"layoutAttributesForElements(atSection:in:) is required when 'dataRequiredForLayoutAttributes' == .none"
                items = layout.layoutAttributesForElements(in: rectInSectionBounds, sectionIndex: sectionIndex)
                if items.isEmpty == false {
                    //Update for each layout attributes its origin Y
                    var sectionHeader: PuzzleCollectionViewLayoutAttributes?
                    var sectionFooter: PuzzleCollectionViewLayoutAttributes?
                    
                    for item in items {
                        item.layoutMargins = collectionView!.layoutMargins
                        item.center.y += lastY
                        allAttributes.append(item)
                        
                        if item.representedElementCategory == .supplementaryView {
                            //Pin header/footer if needed
                            switch item.representedElementKind! {
                            case PuzzleCollectionElementKindSectionHeader:
                                if layout.shouldPinHeaderSupplementaryView() {
                                    item.zIndex = PuzzleCollectionHeaderFooterZIndex
                                    sectionHeader = item
                                }
                                else {
                                    item.zIndex = 0
                                }
                            case PuzzleCollectionElementKindSectionFooter:
                                if layout.shouldPinFooterSupplementaryView() {
                                    item.zIndex = PuzzleCollectionHeaderFooterZIndex
                                    sectionFooter = item
                                }
                                else {
                                    item.zIndex = 0
                                }
                            default: break
                            }
                        }
                        
                        //Add separator lines if needed
                        if (
                            item.representedElementCategory != .cell
                            || layout.separatorLineStyle == .none
                            || (layout.separatorLineStyle == .allButLastItem
                                && item.indexPath.item + 1 == layout.numberOfItemsInSection)
                            ) {
                            //No separator line
                        }
                        else {
                            let separatorFrame = CGRect(x: item.frame.minX + layout.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layout.separatorLineInsets.left + layout.separatorLineInsets.right), height: 0.5)
                            if rect.intersects(separatorFrame) {
                                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: PuzzleCollectionElementKindSeparatorLine, with: item.indexPath)
                                separatorLine.layoutMargins = collectionView!.layoutMargins
                                separatorLine.frame = separatorFrame
                                separatorLine.zIndex = PuzzleCollectionSeparatorsViewZIndex
                                if let color = layout.separatorLineColor ?? separatorLineColor {
                                    separatorLine.info = [PuzzleCollectionColoredViewColorKey : color]
                                }
                                allAttributes.append(separatorLine)
                            }
                        }
                    }
                    
                    if sectionHeader != nil || sectionFooter != nil {
                        let shouldPinHeader = layout.shouldPinHeaderSupplementaryView()
                        let shouldPinFooter = layout.shouldPinFooterSupplementaryView()
                        
                        let contentOffsetY = collectionView!.bounds.minY + collectionView!.contentInset.top
                        
                        if shouldPinHeader && sectionHeader == nil {
                            if let header = layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex)) {
                                header.layoutMargins = collectionView!.layoutMargins
                                header.center.y += lastY
                                header.zIndex = PuzzleCollectionHeaderFooterZIndex
                                allAttributes.append(header)
                                sectionHeader = header
                            }
                        }
                        
                        if shouldPinFooter && sectionFooter == nil {
                            if let footer = layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex)) {
                                footer.layoutMargins = collectionView!.layoutMargins
                                footer.center.y += lastY
                                footer.zIndex = PuzzleCollectionHeaderFooterZIndex
                                allAttributes.append(footer)
                                sectionFooter = footer
                            }
                        }
                        
                        if let header = sectionHeader {
                            let y = header.frame.minY
                            if sectionFrame.minY < contentOffsetY {
                                let maxY = (sectionFooter?.frame.minY ?? sectionFrame.maxY) - header.frame.height
                                header.frame.origin.y = min(contentOffsetY, maxY)
                            }
                            
                            header.isPinned = (y != header.frame.minY)
                        }
                        
                        if let footer = sectionFooter {
                            let contentY = (sectionHeader?.frame.maxY ?? contentOffsetY)
                            let y = footer.frame.minY
                            if sectionFrame.maxY > contentY {
                                let minY = max(collectionView!.bounds.maxY - footer.frame.height, sectionFrame.minY)
                                footer.frame.origin.y = min(sectionFrame.maxY - footer.frame.height, minY)
                            }
                            footer.isPinned = (y != footer.frame.minY)
                        }
                    }
                }
            }
            else if sectionFrame.minY >= rect.maxY { //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                break
            }
//            else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//            }
            
            // ----- End check if section intersects & get its elements layout attributes
            
            
            //Update before next iteration
            lastY += sectionHeight
            // ----- Update before next iteration
        }
        
        return allAttributes
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[indexPath.section]
        
        if let item = layout.layoutAttributesForItem(at: indexPath) {
            item.layoutMargins = collectionView!.layoutMargins
            let originY = self.originY(forSectionAt: indexPath.section)
            item.center.y += originY
            return item
        }
        else { return nil }
    }
    
    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[indexPath.section]
        
        if let item = layout.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) {
            item.layoutMargins = collectionView!.layoutMargins
            let originY = self.originY(forSectionAt: indexPath.section)
            item.center.y += originY
            item.zIndex = 0
            
            switch item.representedElementKind! {
            case PuzzleCollectionElementKindSectionHeader where layout.shouldPinHeaderSupplementaryView():
                let y = item.frame.minY
                
                item.zIndex = PuzzleCollectionHeaderFooterZIndex
                let contentOffsetY = collectionView!.bounds.minY + collectionView!.contentInset.top
                let sectionMaxY = originY + layout.heightOfSection
                if originY < contentOffsetY {
                    let maxY: CGFloat
                    if let footerToPin = (layout.shouldPinFooterSupplementaryView() ? layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: indexPath) : nil) {
                        maxY = (footerToPin.frame.minY + originY) - item.frame.height
                    }
                    else {
                        maxY = sectionMaxY - item.frame.height
                    }
                    
                    item.frame.origin.y = min(contentOffsetY, maxY)
                }
                
                item.isPinned = (y != item.frame.minY)
            case PuzzleCollectionElementKindSectionFooter where layout.shouldPinFooterSupplementaryView():
                let y = item.frame.minY
                
                item.zIndex = PuzzleCollectionHeaderFooterZIndex
                let headerToPin = (layout.shouldPinHeaderSupplementaryView() ? layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: indexPath) : nil)
                let contentOffsetY = collectionView!.bounds.minY + collectionView!.contentInset.top
                let contentY = (headerToPin?.frame.maxY ?? contentOffsetY)
                let sectionMaxY = originY + layout.heightOfSection
                if sectionMaxY > contentY {
                    let minY = max(collectionView!.bounds.maxY - item.frame.height, originY)
                    item.frame.origin.y = min(sectionMaxY - item.frame.height, minY)
                }
                
                item.isPinned = (y != item.frame.minY)
            default: break
            }
            
            return item
        }
        else { return nil }
    }
    
    override public func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == PuzzleCollectionElementKindSeparatorLine {
            let layout = sectionsLayoutInfo[indexPath.section]
            if layout.separatorLineStyle == .none || (layout.separatorLineStyle == .allButLastItem && indexPath.item + 1 == layout.numberOfItemsInSection) {
                //There's no need in line view, but returning nil cause a crash.
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.layoutMargins = collectionView!.layoutMargins
                separatorLine.isHidden = true
                separatorLine.frame.size = .zero
                return separatorLine
            }
            else if let item = layoutAttributesForItem(at: indexPath) {
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.layoutMargins = collectionView!.layoutMargins
                separatorLine.frame = CGRect(x: item.frame.minX + layout.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layout.separatorLineInsets.left + layout.separatorLineInsets.right), height: 0.5)
                separatorLine.zIndex = PuzzleCollectionSeparatorsViewZIndex
                if let color = layout.separatorLineColor ?? separatorLineColor {
                    separatorLine.info = [PuzzleCollectionColoredViewColorKey : color]
                }
                return separatorLine
            }
            else {
                //There's no need in line view, but returning nil cause a crash.
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.layoutMargins = collectionView!.layoutMargins
                separatorLine.isHidden = true
                separatorLine.frame.size = .zero
                return separatorLine
            }
        }
        else {
            let layout = sectionsLayoutInfo[indexPath.section]
            
            if let decoration = layout.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath) {
                decoration.layoutMargins = collectionView!.layoutMargins
                let originY = self.originY(forSectionAt: indexPath.section)
                decoration.center.y += originY
                return decoration
            }
            else { return nil }
        }
    }
    
    override public func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[itemIndexPath.section]
        
        if let item = layout.initialLayoutAttributesForAppearingItem(at: itemIndexPath) {
            let originY = self.originY(forSectionAt: itemIndexPath.section)
            item.center.y += originY
            return item
        }
        else { return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) }
    }
    
    override public func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[itemIndexPath.section]
        
        if let item = layout.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) {
            let originY = self.originY(forSectionAt: itemIndexPath.section)
            item.center.y += originY
            return item
        }
        else { return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) }
    }
    
    override public func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let layout = sectionsLayoutInfo[elementIndexPath.section]
        
        if let item = layout.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) {
            let originY = self.originY(forSectionAt: elementIndexPath.section)
            item.center.y += originY
            return item
        }
        else { return super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) }
    }
    
    override public func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[elementIndexPath.section]
        
        if let item = layout.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) {
            let originY = self.originY(forSectionAt: elementIndexPath.section)
            item.center.y += originY
            return item
        }
        else { return super.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) }
    }
    
    override public func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == PuzzleCollectionElementKindSeparatorLine {
            return super.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: decorationIndexPath)
        }
        else {
            let layout = sectionsLayoutInfo[decorationIndexPath.section]
            
            if let item = layout.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: decorationIndexPath) {
                let originY = self.originY(forSectionAt: decorationIndexPath.section)
                item.center.y += originY
                return item
            }
            else { return super.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: decorationIndexPath) }
        }
    }
    
    override public func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == PuzzleCollectionElementKindSeparatorLine {
            return super.finalLayoutAttributesForDisappearingDecorationElement(ofKind: elementKind, at: decorationIndexPath)
        }
        else {
            let layout = sectionsLayoutInfo[decorationIndexPath.section]
            
            if let item = layout.finalLayoutAttributesForDisappearingDecorationElement(ofKind: elementKind, at: decorationIndexPath) {
                let originY = self.originY(forSectionAt: decorationIndexPath.section)
                item.center.y += originY
                return item
            }
            else { return super.finalLayoutAttributesForDisappearingDecorationElement(ofKind: elementKind, at: decorationIndexPath) }
        }
    }
    
    private var invalidationInfoForBoundsChange: InvalidationInfoForBoundsChange?
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        //Since this is a vertical layout, changes in origin y or size width should be relavant for us. Origin x should never get changes, since collectionView.contentSize.widht == collectionView.widht. In addition. Changing size height, should insert or remove cells, depend the height change.
        
        let oldBounds = collectionView!.bounds
        let oldWidth = oldBounds.width
        let newWidth = newBounds.width
        if newWidth != oldWidth {
            return true
        }
        
        if newBounds.minY != oldBounds.minY {
            //Check if there's a section layout which require invalidation for bounds change
            
            var lastY: CGFloat = 0
            var invalidationInfo = InvalidationInfoForBoundsChange()
            for sectionLayout in sectionsLayoutInfo {
                let sectionHeight = sectionLayout.heightOfSection
                let maxSectionY = lastY + sectionHeight
                if maxSectionY < newBounds.minY && maxSectionY < oldBounds.minY {
                    lastY = maxSectionY
                    continue
                }
                else if lastY >= newBounds.maxY && lastY >= oldBounds.maxY {
                    //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                    break
                }
                
                let sectionIndex = sectionLayout.sectionIndex!
                let headerToPin: PuzzleCollectionViewLayoutAttributes?
                if sectionLayout.shouldPinHeaderSupplementaryView() {
                    headerToPin = sectionLayout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex))
                }
                else { headerToPin = nil }
                
                let footerToPin: PuzzleCollectionViewLayoutAttributes?
                if sectionLayout.shouldPinFooterSupplementaryView() {
                    footerToPin = sectionLayout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex))
                }
                else { footerToPin = nil }
                
                guard headerToPin != nil || footerToPin != nil else {
                    lastY += sectionHeight
                    continue
                }
                
                let sectionFrame = CGRect(x: 0, y: lastY, width: newWidth, height: sectionHeight)
                
                //Check if section intersects & get its elements layout attributes
                let oldFrameIntersection = sectionFrame.intersection(oldBounds)
                let newFrameIntersection = sectionFrame.intersection(newBounds)
                
                if oldFrameIntersection.height > 0 || newFrameIntersection.height > 0 {
                    
                    if let headerToPin {
                        invalidationInfo.headersIndexPathToPin.append(headerToPin.indexPath)
                    }
                    
                    if let footerToPin {
                        invalidationInfo.footersIndexPathToPin.append(footerToPin.indexPath)
                    }
                }
//                else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//                }
                
                lastY += sectionHeight
            }
            
            if invalidationInfo.headersIndexPathToPin.isEmpty && invalidationInfo.footersIndexPathToPin.isEmpty {
                invalidationInfoForBoundsChange = nil
                return super.shouldInvalidateLayout(forBoundsChange: newBounds)
            }
            else {
                invalidationInfoForBoundsChange = invalidationInfo
                return true
            }
        }
        else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }
    
    override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        
        let oldBounds = collectionView!.bounds
        let context = super.invalidationContext(forBoundsChange: newBounds) as! PuzzleCollectionViewLayoutInvalidationContext
        
        if newBounds.width != oldBounds.width {
            invalidateForWidthChange(byBoundsChange: newBounds, oldBounds: oldBounds, with: context)
        }
        else if let invalidationInfo = invalidationInfoForBoundsChange {
            if invalidationInfo.headersIndexPathToPin.isEmpty == false {
                context.invalidateSupplementaryElements(ofKind: PuzzleCollectionElementKindSectionHeader, at: invalidationInfo.headersIndexPathToPin)
            }
            
            if invalidationInfo.footersIndexPathToPin.isEmpty == false {
                context.invalidateSupplementaryElements(ofKind: PuzzleCollectionElementKindSectionFooter, at: invalidationInfo.footersIndexPathToPin)
            }
        }
        
        invalidationInfoForBoundsChange = nil
        return context
    }
    
    override public func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        
        if preferredAttributes.representedElementCategory == .decorationView {
            if preferredAttributes.representedElementKind == PuzzleCollectionElementKindSeparatorLine || preferredAttributes.representedElementKind == PuzzleCollectionElementKindSectionTopGutter || preferredAttributes.representedElementKind == PuzzleCollectionElementKindSectionBottomGutter {
                return false
            }
        }
        
        //Check if the section layout which generate 'originalAttributes' want to invalidate it for 'preferredAttributes'
        if originalAttributes.indexPath.count == 0 {
            return false
        }
        let layout = sectionsLayoutInfo[originalAttributes.indexPath.section]
        let invalidationType: InvalidationElementCategory
        switch preferredAttributes.representedElementCategory {
        case .cell:
            invalidationType = .cell(index: originalAttributes.indexPath.item)
        case .supplementaryView:
            invalidationType = .supplementaryView(index: originalAttributes.indexPath.item, elementKind: originalAttributes.representedElementKind!)
        case .decorationView:
            invalidationType = .decorationView(index: originalAttributes.indexPath.item, elementKind: originalAttributes.representedElementKind!)
        @unknown default:
            preconditionFailure()
        }
        
        if layout.shouldInvalidate(for: invalidationType, forPreferredSize: &preferredAttributes.size, withOriginalSize: originalAttributes.size) {
            preferredAttributes.frame.origin.y = originalAttributes.frame.origin.y
            return true
        }
        else { return false }
    }
    
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let ctx = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes) as! PuzzleCollectionViewLayoutInvalidationContext
        let sectionIndex = originalAttributes.indexPath.section
        let layout = sectionsLayoutInfo[sectionIndex]
        
        let invalidationType: InvalidationElementCategory
        switch preferredAttributes.representedElementCategory {
        case .cell:
            invalidationType = .cell(index: originalAttributes.indexPath.item)
        case .supplementaryView:
            invalidationType = .supplementaryView(index: originalAttributes.indexPath.item, elementKind: originalAttributes.representedElementKind!)
        case .decorationView:
            invalidationType = .decorationView(index: originalAttributes.indexPath.item, elementKind: originalAttributes.representedElementKind!)
        @unknown default:
            preconditionFailure()
        }
        
        (preferredAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize = preferredAttributes.size
        ctx.invalidateSectionLayoutData = layout
        if let info = layout.invalidationInfo(for: invalidationType, forPreferredSize: preferredAttributes.size, withOriginalSize: originalAttributes.size) {
            ctx.setInvalidationInfo(info, forSectionAtIndex: sectionIndex)
        }
        return ctx
    }

    //MARK: - Prepare sections layout
    private func prepareSectionsLayout() {
        guard let dataSource = collectionView!.dataSource as? CollectionViewDataSourcePuzzleLayout else {
            assert(false, "To use this layout, collection view data source must conform to 'CollectionViewDataSourcePuzzleLayout'")
            return
        }
        
        let numberOfSections = collectionView!.numberOfSections
        if numberOfSections > 0 {
            let oldLayouts = sectionsLayoutInfo
            var newLayouts: [PuzzlePieceSectionLayout] = [PuzzlePieceSectionLayout](repeating: PuzzlePieceSectionLayout(), count: numberOfSections)
            for layout in oldLayouts {
                layout.parentLayout = nil
                layout.sectionIndex = nil
            }
            
            for sectionIndex in 0 ..< numberOfSections {
                let numberOfItems = collectionView!.numberOfItems(inSection: sectionIndex)
                let layout = dataSource.collectionView(collectionView!, layout: self, layoutForSectionAtIndex: sectionIndex)
                //TODO: preapre with parentLayout=self & numberOfItems
                
                layout.parentLayout = self
                layout.numberOfItemsInSection = numberOfItems
                layout.sectionIndex = sectionIndex
                newLayouts[sectionIndex] = layout
            }
            
            sectionsLayoutInfo = newLayouts
            for layout in oldLayouts {
                //Layout wasn't used again when iterating the number of section just few lines above
                if layout.parentLayout == nil {
                    layout.sectionIndex = nil
                    layout.numberOfItemsInSection = 0
                    layout.tearDown()
                }
            }
        }
        else {
            let sectionsInfo = sectionsLayoutInfo
            sectionsLayoutInfo = []
            
            for layout in sectionsInfo {
                layout.parentLayout = nil
                layout.sectionIndex = nil
                layout.numberOfItemsInSection = 0
                layout.tearDown()
            }
        }
    }
    
    //MARK: - Private
    private func originY(forSectionAt index: Int) -> CGFloat {
        if index == 0 {
            return 0
        }
        else {
            var originY: CGFloat = 0
            for currentIndex in 0...(index-1) {
                let layout = sectionsLayoutInfo[currentIndex]
                originY += layout.heightOfSection
            }
            return originY
        }
    }
    
    private func invalidateForWidthChange(byBoundsChange newBounds: CGRect, oldBounds: CGRect, with context: PuzzleCollectionViewLayoutInvalidationContext) {
        var lastY: CGFloat = 0
        for sectionLayout in sectionsLayoutInfo {
            let sectionHeight = sectionLayout.heightOfSection
            
            let oldSectionFrame = CGRect(x: 0, y: lastY, width: oldBounds.width, height: sectionHeight)
            let newSectionFrame = CGRect(x: 0, y: lastY, width: newBounds.width, height: sectionHeight)
            
            //Check if section intersects & get its elements layout attributes
            let oldFrameIntersection = oldSectionFrame.intersection(oldBounds)
            let newFrameIntersection = newSectionFrame.intersection(newBounds)
            
            
            if oldFrameIntersection.height > 0 || newFrameIntersection.height > 0 {
                let oldSectionBounds = CGRect(origin: CGPoint(x: oldFrameIntersection.minX, y: oldFrameIntersection.minY - lastY), size: oldFrameIntersection.size)
                let newSectionBounds = CGRect(origin: CGPoint(x: newFrameIntersection.minX, y: newFrameIntersection.minY - lastY), size: newFrameIntersection.size)
                if let info = sectionLayout.invalidationInfo(forNewWidth: newSectionBounds.width, currentWidth: oldSectionBounds.width) {
                    let index = sectionLayout.sectionIndex!
                    context.setInvalidationInfo(info, forSectionAtIndex: index)
                }
            }
            else if oldFrameIntersection.minY >= oldBounds.maxY && newFrameIntersection.minY >= newBounds.maxY { //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                break
            }
//            else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//            }
            
            lastY += sectionHeight
        }
    }
}

//MARK: - Private Util
fileprivate struct InvalidationInfoForBoundsChange {
    var headersIndexPathToPin: [IndexPath] = []
    var footersIndexPathToPin: [IndexPath] = []
}

fileprivate class ColoredDecorationView : UICollectionReusableView {
    fileprivate override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        let dict = (layoutAttributes as! PuzzleCollectionViewLayoutAttributes).info as? [AnyHashable:Any]
        backgroundColor = dict?[PuzzleCollectionColoredViewColorKey] as? UIColor ?? UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1)
    }
}

public extension UICollectionView {
    @objc func reloadDataToPreventCachingBug() {
        let puzzleLayout = collectionViewLayout as? PuzzleCollectionViewLayout
        puzzleLayout?.reloadingDataForInvalidationBug = true
        self.reloadData()
        puzzleLayout?.reloadingDataForInvalidationBug = false
    }
}

//MARK: - PuzzlePieceSectionLayout
extension PuzzlePieceSectionLayout {
    
    internal func invalidationContextForSeparatorLines(for newStyle: PuzzlePieceSeparatorLineStyle, oldStyle: PuzzlePieceSeparatorLineStyle? = nil) -> PuzzleCollectionViewLayoutInvalidationContext? {
        let _oldStyle = oldStyle ?? newStyle
        if newStyle == _oldStyle && newStyle == .none {
            return nil
        }
        
        guard let sectionIndex else {
            return nil
        }
        
        let layoutInfo = parentLayout!.sectionsLayoutInfo[sectionIndex]
        if layoutInfo.numberOfItemsInSection == 0 {
            return nil
        }
        else if layoutInfo.numberOfItemsInSection == 1 {
            if (_oldStyle == .none && newStyle == .allButLastItem) || (_oldStyle == .allButLastItem && newStyle == .none) {
                return nil
            }
        }
        
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.invalidateSectionLayoutData = self
        let numberOfItems = (newStyle == .all || _oldStyle == .all) ? layoutInfo.numberOfItemsInSection : (layoutInfo.numberOfItemsInSection - 1)
        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<numberOfItems))
        return ctx
    }
}

//MARK: UICollectionView utility
private enum CollectionViewUpdate {
    case insertSections(at: IndexSet)
    case deleteSections(at: IndexSet)
    case reloadSections(at: IndexSet)
    case moveSection(at: Int, to: Int)
    case insertItems(at: [IndexPath])
    case deleteItems(at: [IndexPath])
    case reloadItems(at: [IndexPath])
    case moveItem(at: IndexPath, to: IndexPath)
}

private let swizzling: (UICollectionView.Type) -> () = { collectionView in
    let selectorsToSwap: [(from: Selector, to: Selector)] = [
        (from: #selector(collectionView.insertSections(_:)), to: #selector(collectionView.myInsertSections(_:))),
        (from: #selector(collectionView.deleteSections(_:)), to: #selector(collectionView.myDeleteSections(_:))),
        (from: #selector(collectionView.reloadSections(_:)), to: #selector(collectionView.myReloadSections(_:))),
        (from: #selector(collectionView.moveSection(_:toSection:)), to: #selector(collectionView.myMoveSection(_:toSection:))),
        (from: #selector(collectionView.insertItems(at:)), to: #selector(collectionView.myInsertItems(at:))),
        (from: #selector(collectionView.deleteItems(at:)), to: #selector(collectionView.myDeleteItems(at:))),
        (from: #selector(collectionView.reloadItems(at:)), to: #selector(collectionView.myReloadItems(at:))),
        (from: #selector(collectionView.moveItem(at:to:)), to: #selector(collectionView.myMoveItem(at:to:))),
    ]
    
    for swap in selectorsToSwap {
        let originalMethod = class_getInstanceMethod(collectionView, swap.from)
        let swizzledMethod = class_getInstanceMethod(collectionView, swap.to)
        
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
}

extension UICollectionView {
// Implmented in ObjC cause Swift 4 doesn't allow override +initialize
//    open override class func initialize() {
//        guard self == UICollectionView.self else {
//            return
//        }
//
//        swizzling(self)
//    }

    @objc fileprivate func myInsertSections(_ sections: IndexSet) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.insertSections(at: sections))
        }
        
        self.myInsertSections(sections)
    }
    
    @objc fileprivate func myDeleteSections(_ sections: IndexSet) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.deleteSections(at: sections))
        }
        self.myDeleteSections(sections)
    }
    
    @objc fileprivate func myReloadSections(_ sections: IndexSet) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.reloadSections(at: sections))
        }
        self.myReloadSections(sections)
    }
    
    @objc fileprivate func myMoveSection(_ section: Int, toSection newSection: Int) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.moveSection(at: section, to: newSection))
        }
        self.myMoveSection(section, toSection: newSection)
    }
    
    
    @objc(myInsertItemsAtIndexPaths:) fileprivate func myInsertItems(at indexPaths: [IndexPath]) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.insertItems(at: indexPaths))
        }
        self.myInsertItems(at: indexPaths)
    }
    
    @objc(myDeleteItemsAtIndexPaths:) fileprivate func myDeleteItems(at indexPaths: [IndexPath]) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.deleteItems(at: indexPaths))
        }
        self.myDeleteItems(at: indexPaths)
    }
    
    @objc(myReloadItemsAtIndexPaths:) fileprivate func myReloadItems(at indexPaths: [IndexPath]) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.reloadItems(at: indexPaths))
        }
        self.myReloadItems(at: indexPaths)
    }
    
    @objc(myMoveItemAtIndexPath:toIndexPath:) fileprivate func myMoveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        if let puzzle = collectionViewLayout as? PuzzleCollectionViewLayout {
            if puzzle.dataSourceUpdates == nil { puzzle.dataSourceUpdates = [] }
            puzzle.dataSourceUpdates!.append(.moveItem(at: indexPath, to: newIndexPath))
        }
        self.myMoveItem(at: indexPath, to: newIndexPath)
    }
}
