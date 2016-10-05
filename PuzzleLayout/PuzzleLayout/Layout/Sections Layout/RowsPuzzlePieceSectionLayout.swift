//
//  RowsPuzzlePieceSectionLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 25/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

public class RowsSectionPuzzleLayout: NSObject, PuzzlePieceSectionLayout {

    public var identifier: String?
    
    public var sectionInsets = UIEdgeInsets.zero {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForSectionInsets) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateAllRowsForSectionInsetsChange()
            }
        }
    }
    
    public var interitemSpacing: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForInteritemSpacing) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateAllRowsOriginY()
            }
        }
    }
    
    public var estimatedItemHeight: CGFloat = 44 {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateRowsUsingEstimatedHeight()
            }
        }
    }

    public var estimatedHeaderHeight: CGFloat = kEstimatedHeaderFooterHeightNone {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateRowsUsingEstimatedHeight()
            }
        }
    }
    
    public var estimatedFooterHeight: CGFloat = kEstimatedHeaderFooterHeightNone {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateRowsUsingEstimatedHeight()
            }
        }
    }
    
    public var separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem {
        didSet {
            if let ctx = self.invalidationContextForSeparatorLines(for: separatorLineStyle, oldStyle: oldValue) {
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }

    public var separatorLineInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) {
        didSet {
            if separatorLineInsets != .none, let ctx = self.invalidationContextForSeparatorLines(for: separatorLineStyle) {
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    public var showTopGutter: Bool = false {
        didSet {
            if sectionInsets.top != 0, let ctx = self.invalidationContext {
                ctx.invalidateSectionLayoutData = self
                ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSectionTopGutter, at: [indexPath(forIndex: 0)!])
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    public var showBottomGutter: Bool = false {
        didSet {
            if sectionInsets.bottom != 0, let ctx = self.invalidationContext {
                ctx.invalidateSectionLayoutData = self
                ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSectionBottomGutter, at: [indexPath(forIndex: 0)!])
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    //MARK: - Private properties
    private var rowsInfo: [RowInfo]!
    private var headerInfo: RowInfo?
    private var footerInfo: RowInfo?
    
    private var collectionViewWidth: CGFloat = 0
    private var numberOfItemsInSection: Int = 0
    
    override init() {
        super.init()
    }
    
    init(estimatedItemHeight: CGFloat, sectionInsets: UIEdgeInsets = .zero, estimatedHeaderHeight: CGFloat = kEstimatedHeaderFooterHeightNone, estimatedFooterHeight: CGFloat = kEstimatedHeaderFooterHeightNone) {
        self.estimatedItemHeight = estimatedItemHeight
        self.sectionInsets = sectionInsets
        self.estimatedHeaderHeight = estimatedHeaderHeight
        self.estimatedFooterHeight = estimatedFooterHeight
        super.init()
    }
    
    //MARK: - PuzzlePieceSectionLayout
    public weak var parentLayout: PuzzleCollectionViewLayout?
    
    public var heightOfSection: CGFloat {
        var maxY: CGFloat = 0
        if let footer = footerInfo {
            maxY = footer.maxOriginY
        } else if let lastItem = rowsInfo.last {
            maxY = lastItem.maxOriginY + sectionInsets.bottom
        } else if let header = headerInfo {
            maxY = header.maxOriginY + sectionInsets.bottom
        }
        
        return maxY
    }
    
    public func prepare(for numberOfItemsInSection: Int, withInvalidation context: PuzzleCollectionViewLayoutInvalidationContext, and info: Any?) {
        
        self.numberOfItemsInSection = numberOfItemsInSection
        if (info as? String) == kInvalidateForResetLayout {
            rowsInfo = nil
            headerInfo = nil
            footerInfo = nil
        }
        
        if rowsInfo == nil {
            collectionViewWidth = sectionWidth
            prepareRowsFromScratch()
        }
        else if context.invalidateEverything || context.invalidateDataSourceCounts {
            fixRowsList()
        }
        else if let invalidationStr = info as? String {
            switch invalidationStr {
            case kInvalidateForEstimatedHeightChange:
                updateRowsUsingEstimatedHeight()
            case kInvalidateHeaderForPreferredHeight:
                updateRows(forHeader: true)
            case kInvalidateForSectionInsets:
                updateAllRowsForSectionInsetsChange()
            case kInvalidateForInteritemSpacing:
                updateAllRowsOriginY()
            default: break
            }
        }
        else if let itemIndexPath = info as? IndexPath {
            updateRows(forIndexPath: itemIndexPath)
        }
        
        if context.invalidateForWidthChange || collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            updateAllRowsWidth()
        }
    }
    
    public func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes] {
        var attributesInRect = [PuzzleCollectionViewLayoutAttributes]()
        guard numberOfItemsInSection != 0 else {
            return []
        }
        
        if let headerInfo = headerInfo, headerInfo.intersects(with: rect) {
            attributesInRect.append(layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex))!)
        }
        
        if showTopGutter && sectionInsets.top != 0 {
            let originY: CGFloat = headerInfo?.maxOriginY ?? 0
            let topGutterFrame = CGRect(x: 0, y: originY, width: collectionViewWidth, height: sectionInsets.top)
            if rect.intersects(topGutterFrame) {
                let gutterAttributes = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: PuzzleCollectionElementKindSectionTopGutter, with: IndexPath(item: 0, section: sectionIndex))
                gutterAttributes.frame = topGutterFrame
                if let gutterColor = separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                else if let gutterColor = parentLayout?.separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                
                gutterAttributes.zIndex = PuzzleCollectionColoredViewZIndex
                attributesInRect.append(gutterAttributes)
            }
        }
        
        for row in 0 ..< numberOfItemsInSection {
            let rowInfo = rowsInfo[row]
            if rowInfo.intersects(with: rect) {
                attributesInRect.append(layoutAttributesForItem(at: IndexPath(item: row, section: sectionIndex))!)
            } else if rect.maxY < rowInfo.originY {
                break
            }
        }
        
        if showBottomGutter && sectionInsets.bottom != 0 {
            let maxY: CGFloat
            if let footer = footerInfo {
                maxY = footer.originY
            } else if let lastItem = rowsInfo.last {
                maxY = lastItem.maxOriginY
            } else if let header = headerInfo {
                maxY = header.maxOriginY
            }
            else {
                maxY = 0
            }
            
            let bottonGutterFrame = CGRect(x: 0, y: maxY - sectionInsets.bottom, width: collectionViewWidth, height: sectionInsets.bottom)
            if rect.intersects(bottonGutterFrame) {
                let gutterAttributes = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: PuzzleCollectionElementKindSectionBottomGutter, with: IndexPath(item: 0, section: sectionIndex))
                gutterAttributes.frame = bottonGutterFrame
                if let gutterColor = separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                else if let gutterColor = parentLayout?.separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                
                gutterAttributes.zIndex = PuzzleCollectionColoredViewZIndex
                attributesInRect.append(gutterAttributes)
            }
        }
        
        if let footerInfo = footerInfo, footerInfo.intersects(with: rect) {
            attributesInRect.append(layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex))!)
        }
        
        return attributesInRect
    }
    
    public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        let rowInfo = rowsInfo[indexPath.item]
        let itemAttributes = PuzzleCollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame = CGRect(x: sectionInsets.left, y: rowInfo.originY, width: collectionViewWidth - (sectionInsets.left + sectionInsets.right), height: rowInfo.height)
        itemAttributes.frame = frame
        if rowInfo.estimatedHeight == false {
            itemAttributes.cachedSize = frame.size
        }
        return itemAttributes
    }
    
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        switch elementKind {
        case PuzzleCollectionElementKindSectionHeader:
            if let headerInfo = headerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
                let frame = CGRect(x: 0, y: headerInfo.originY, width: collectionViewWidth, height: headerInfo.height)
                itemAttributes.frame = frame
                if headerInfo.estimatedHeight == false {
                    itemAttributes.cachedSize = frame.size
                }
                return itemAttributes
            } else { return nil }
        case PuzzleCollectionElementKindSectionFooter:
            if let footerInfo = footerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
                let frame = CGRect(x: 0, y: footerInfo.originY, width: collectionViewWidth, height: footerInfo.height)
                itemAttributes.frame = frame
                if footerInfo.estimatedHeight == false {
                    itemAttributes.cachedSize = frame.size
                }
                return itemAttributes
            } else { return nil }
        default:
            return nil
        }
    }
    
    public func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        if elementKind == PuzzleCollectionElementKindSectionTopGutter {
            if showTopGutter && sectionInsets.top != 0 {
                let originY: CGFloat = headerInfo?.maxOriginY ?? 0
                let gutterAttributes = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                gutterAttributes.frame = CGRect(x: 0, y: originY, width: collectionViewWidth, height: sectionInsets.top)
                if let gutterColor = separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                else if let gutterColor = parentLayout?.separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                
                gutterAttributes.zIndex = PuzzleCollectionColoredViewZIndex
                return gutterAttributes
            }
        }
        else if elementKind == PuzzleCollectionElementKindSectionBottomGutter {
            if showBottomGutter && sectionInsets.bottom != 0 {
                let maxY: CGFloat
                if let footer = footerInfo {
                    maxY = footer.originY
                } else if let lastItem = rowsInfo.last {
                    maxY = lastItem.maxOriginY
                } else if let header = headerInfo {
                    maxY = header.maxOriginY
                }
                else {
                    maxY = 0
                }
                
                let gutterAttributes = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                gutterAttributes.frame = CGRect(x: 0, y: maxY - sectionInsets.bottom, width: collectionViewWidth, height: sectionInsets.bottom)
                if let gutterColor = separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                else if let gutterColor = parentLayout?.separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                
                gutterAttributes.zIndex = PuzzleCollectionColoredViewZIndex
                return gutterAttributes
            }
        }
        
        return nil
    }
    
    //Bounds Invalidation
    public func shouldInvalidate(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Bool {
        return false
    }
    
    public func invalidationInfo(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Any? {
        return nil
    }
    
    //PreferredAttributes Invalidation
    public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        var shouldInvalidate = false
        switch elementCategory {
        case .cell(let indexPath):
            shouldInvalidate = (indexPath.item < numberOfItemsInSection)
        case .supplementaryView(_, let elementKind):
            shouldInvalidate = (
                (elementKind == PuzzleCollectionElementKindSectionHeader && headerInfo != nil)
                || (elementKind == PuzzleCollectionElementKindSectionFooter && footerInfo != nil)
                )
        default: break
        }
        
        if shouldInvalidate {
            if originalSize.height != preferredSize.height {
                preferredSize.width = originalSize.width
                return true
            }
            else {
                return false
            }
        }
        else { return false }
    }

    public func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? {
        
        var info: Any? = nil
        switch elementCategory {
        case .cell(let indexPath):
            rowsInfo[indexPath.item].height = preferredSize.height
            rowsInfo[indexPath.item].estimatedHeight = false
            info = indexPath
        case .supplementaryView(_, let elementKind):
            if elementKind == UICollectionElementKindSectionHeader {
                headerInfo!.height = preferredSize.height
                headerInfo!.estimatedHeight = false
                info = kInvalidateHeaderForPreferredHeight
            }
            else if elementKind == UICollectionElementKindSectionFooter {
                footerInfo!.height = preferredSize.height
                footerInfo!.estimatedHeight = false
            }
            
        default: break
        }
        
        return info
    }
    
    //MARK: - 
    public func resetLayout() {
        if let ctx = self.invalidationContext(with: kInvalidateForResetLayout) {
            ctx.invalidateSectionLayoutData = self
            parentLayout!.invalidateLayout(with: ctx)
        }
    }
    
    // MARK: - Private
    private func prepareRowsFromScratch() {
        var lastOriginY: CGFloat = 0
        
        rowsInfo = [RowInfo](repeating: RowInfo(estimatedHeight: true, originY: 0, height: 0), count: numberOfItemsInSection)
        
        if estimatedHeaderHeight != kEstimatedHeaderFooterHeightNone {
            headerInfo = RowInfo(estimatedHeight: true, originY: lastOriginY, height: estimatedHeaderHeight)
            lastOriginY += estimatedHeaderHeight
        }
        
        if numberOfItemsInSection != 0 {
            
            lastOriginY += sectionInsets.top
            
            for row in 0 ..< numberOfItemsInSection {
                rowsInfo[row] = RowInfo(estimatedHeight: true, originY: lastOriginY, height: estimatedItemHeight)
                lastOriginY += estimatedItemHeight + interitemSpacing
            }
            
            lastOriginY -= interitemSpacing
            lastOriginY += sectionInsets.bottom
        }
        
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            footerInfo = RowInfo(estimatedHeight: true, originY: lastOriginY, height: estimatedFooterHeight)
            lastOriginY += estimatedFooterHeight
        }
    }
    
    private func fixRowsList() {
        
        guard rowsInfo != nil else {
            prepareRowsFromScratch()
            return
        }
        
        var lastOriginY: CGFloat = 0
        
        let updatedRows = numberOfItemsInSection
        let oldRows = rowsInfo.count
        
        // Update section header if needed
        if estimatedHeaderHeight != kEstimatedHeaderFooterHeightNone {
            if headerInfo == nil {
                headerInfo = RowInfo(estimatedHeight: true, originY: lastOriginY, height: estimatedHeaderHeight)
            }
            else if headerInfo!.estimatedHeight {
                headerInfo!.height = estimatedHeaderHeight
            }
            
            lastOriginY += headerInfo!.height
        }
        else if headerInfo != nil {
            headerInfo = nil
        }
        
        let rowsToUpdate = min(oldRows, updatedRows)
        
        lastOriginY += sectionInsets.top
        for row in 0 ..< rowsToUpdate {
            var rowInfo = rowsInfo[row]
            rowInfo.originY = lastOriginY
            rowsInfo[row] = rowInfo
            lastOriginY += rowInfo.height + interitemSpacing
        }
        
        if oldRows > updatedRows {
            // Remove rows
            rowsInfo.removeSubrange(updatedRows ..< oldRows)
            
        }
        else if oldRows < updatedRows {
            
            rowsInfo! += [RowInfo](repeating: RowInfo(estimatedHeight: true, originY: 0, height: 0), count: (updatedRows - oldRows))
            
            for row in oldRows ..< updatedRows {
                rowsInfo[row] = RowInfo(estimatedHeight: true, originY: lastOriginY, height: estimatedItemHeight)
                lastOriginY += estimatedItemHeight + interitemSpacing
            }
        }
        
        if rowsInfo.isEmpty == false {
            lastOriginY -= interitemSpacing
            lastOriginY += sectionInsets.bottom
        }

        // Update section footer if needed
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            if footerInfo == nil {
                footerInfo = RowInfo(estimatedHeight: true, originY: lastOriginY, height: estimatedFooterHeight)
            }
            else if footerInfo!.estimatedHeight {
                footerInfo!.height = estimatedFooterHeight
            }
            
            footerInfo!.originY = lastOriginY
            lastOriginY += footerInfo!.height
        }
        else if footerInfo != nil {
            footerInfo = nil
        }
    }
    
    private func updateRowsUsingEstimatedHeight() {
        if headerInfo?.estimatedHeight ?? false {
            headerInfo!.height = estimatedHeaderHeight
        }
        
        var lastOriginY: CGFloat = (headerInfo?.height ?? 0) + sectionInsets.top
        
        for row in 0 ..< rowsInfo.count {
            var rowInfo = rowsInfo[row]
            if rowInfo.estimatedHeight {
                rowInfo.height = estimatedItemHeight
                rowsInfo[row] = rowInfo
            }
            lastOriginY += rowInfo.height + interitemSpacing
        }
        
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            if rowsInfo.isEmpty == false {
                lastOriginY -= interitemSpacing
                lastOriginY += sectionInsets.bottom
            }
            
            footerInfo!.originY = lastOriginY
            if footerInfo!.estimatedHeight {
                footerInfo!.height = estimatedFooterHeight
            }
        }
    }
    
    private func updateAllRowsWidth() {
        if headerInfo != nil {
            headerInfo!.estimatedHeight = true
        }
        
        for row in 0 ..< rowsInfo.count {
            rowsInfo[row].estimatedHeight = true
        }
        
        if footerInfo != nil {
            footerInfo?.estimatedHeight = true
        }
    }
    
    private func updateAllRowsOriginY() {
        var lastOriginY = headerInfo?.maxOriginY ?? 0
        lastOriginY += sectionInsets.top
        
        for row in 0 ..< rowsInfo.count {
            rowsInfo[row].originY = lastOriginY
            lastOriginY += rowsInfo[row].height + interitemSpacing
        }
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            if rowsInfo.isEmpty == false {
                lastOriginY -= interitemSpacing
                lastOriginY += sectionInsets.bottom
            }
            
            footerInfo!.originY = lastOriginY
        }
    }
    
    private func updateAllRowsForSectionInsetsChange() {
        
        var lastOriginY = headerInfo?.maxOriginY ?? 0
        lastOriginY += sectionInsets.top
        
        for row in 0 ..< rowsInfo.count {
            rowsInfo[row].originY = lastOriginY
            lastOriginY += rowsInfo[row].height + interitemSpacing
        }
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            if rowsInfo.isEmpty == false {
                lastOriginY -= interitemSpacing
                lastOriginY += sectionInsets.bottom
            }
            
            footerInfo!.originY = lastOriginY
        }
    }
    
    private func updateRows(forIndexPath indexPath: IndexPath? = nil, forHeader invalidateHeader: Bool = false) {
        
        guard indexPath != nil || invalidateHeader else {
            //Nothing to invalidate
            return
        }
        
        var lastOriginY: CGFloat = 0
        let firstItemForInvalidation: Int
        if let indexPath = indexPath {
            lastOriginY = rowsInfo[indexPath.item].maxOriginY
            firstItemForInvalidation = indexPath.item + 1
        }
        else if invalidateHeader {
            firstItemForInvalidation = 0
            if let headerInfo = headerInfo {
                lastOriginY = headerInfo.maxOriginY + sectionInsets.top
            }
            else {
                lastOriginY = rowsInfo.first?.maxOriginY ?? sectionInsets.top
            }
        }
        else {
            assert(false, "That can't happen")
            firstItemForInvalidation = 0
        }
        
        if firstItemForInvalidation < numberOfItemsInSection {
            if firstItemForInvalidation != 0 {
                lastOriginY += interitemSpacing
            }
            
            for index in firstItemForInvalidation..<numberOfItemsInSection {
                rowsInfo[index].originY = lastOriginY
                lastOriginY = rowsInfo[index].maxOriginY + interitemSpacing
            }
            
            lastOriginY -= interitemSpacing
        }
        
        if footerInfo != nil {
            lastOriginY += sectionInsets.bottom
            footerInfo!.originY = lastOriginY
        }
    }
}


//MARK: - Utils
fileprivate struct RowInfo: CustomStringConvertible {
    var estimatedHeight: Bool
    var originY: CGFloat
    var height: CGFloat
    var maxOriginY: CGFloat {
        return originY + height
    }
    
    func intersects(with rect: CGRect) -> Bool {
        return !(originY >= rect.maxY || maxOriginY <= rect.minY)
    }
    
    var description: String {
        return "Row Info: estimated:\(estimatedHeight) ; origin Y: \(originY) ; Height: \(height)"
    }
}

private let kInvalidateForResetLayout = "reset"
private let kInvalidateForEstimatedHeightChange = "estimatedHeight"
private let kInvalidateHeaderForPreferredHeight = "Invalidate_Header"
private let kInvalidateForSectionInsets = "Invalidate_SectionInsets"
private let kInvalidateForInteritemSpacing = "Invalidate_InteritemSpacing"
