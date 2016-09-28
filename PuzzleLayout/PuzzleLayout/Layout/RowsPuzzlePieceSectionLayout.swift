//
//  RowsPuzzlePieceSectionLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 25/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

public let kEstimatedHeaderFooterHeightNone: CGFloat = 0

public class RowsSectionPuzzleLayout: NSObject, PuzzlePieceSectionLayout {

    public var identifier: String?
    
    public var sectionInsets = UIEdgeInsets.zero //TODO: invalidate
    public var interitemSpacing: CGFloat = 0 //TODO: invalidate
    public var estimatedItemHeight: CGFloat = 44 {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForEstimatedHeightChange, for: self) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateRowsUsingEstimatedHeight()
            }
        }
    }

    public var estimatedHeaderHeight: CGFloat = kEstimatedHeaderFooterHeightNone {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForEstimatedHeightChange, for: self) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateRowsUsingEstimatedHeight()
            }
        }
    }
    
    public var estimatedFooterHeight: CGFloat = kEstimatedHeaderFooterHeightNone {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForEstimatedHeightChange, for: self) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateRowsUsingEstimatedHeight()
            }
        }
    }
    
    public var separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem //TODO: invalidate
    public var separatorLineInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) //TODO: invalidate
    public var showTopGutter: Bool = false //TODO: invalidate
    public var showBottomGutter: Bool = false //TODO: invalidate
    
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
            maxY = footer.frame.maxY
        } else if let lastRowFrame = rowsInfo.last?.frame {
            maxY = lastRowFrame.maxY + sectionInsets.bottom
        } else if let header = headerInfo {
            maxY = header.frame.maxY + sectionInsets.bottom
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
        else if (info as? String) == kInvalidateHeaderForPreferredHeight {
            updateRows(forHeader: true)
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
        
        if let headerInfo = headerInfo, headerInfo.frame.intersects(rect) {
            attributesInRect.append(layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex))!)
        }
        
        for row in 0 ..< numberOfItemsInSection {
            let rowInfo = rowsInfo[row]
            if rect.intersects(rowInfo.frame) {
                attributesInRect.append(layoutAttributesForItem(at: IndexPath(item: row, section: sectionIndex))!)
            } else if rect.maxY < rowInfo.frame.minY {
                break
            }
        }
        
        if let footerInfo = footerInfo, footerInfo.frame.intersects(rect) {
            attributesInRect.append(layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex))!)
        }
        
        return attributesInRect
    }
    
    public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        let rowInfo = rowsInfo[indexPath.item]
        let itemAttributes = PuzzleCollectionViewLayoutAttributes(forCellWith: indexPath)
        itemAttributes.frame = rowInfo.frame
        if rowInfo.estimatedHeight == false {
            itemAttributes.cachedSize = rowInfo.frame.size
        }
        return itemAttributes
    }
    
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        switch elementKind {
        case PuzzleCollectionElementKindSectionHeader:
            if let headerInfo = headerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath as IndexPath)
                itemAttributes.frame = headerInfo.frame
                if headerInfo.estimatedHeight == false {
                    itemAttributes.cachedSize = headerInfo.frame.size
                }
                return itemAttributes
            } else { return nil }
        case PuzzleCollectionElementKindSectionFooter:
            if let footerInfo = footerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath as IndexPath)
                itemAttributes.frame = footerInfo.frame
                if footerInfo.estimatedHeight == false {
                    itemAttributes.cachedSize = footerInfo.frame.size
                }
                return itemAttributes
            } else { return nil }
        default:
            return nil
        }
    }
    
    //Bounds Invalidation
    public func shouldInvalidate(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Bool {
        return false
    }
    
    public func invalidationInfo(forNewBounds newBounds: CGRect, currentBounds: CGRect) -> Any? {
        return nil
    }
    
    //PreferredAttributes Invalidation
    public func shouldInvalidate(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        let indexPath = preferredAttributes.indexPath
        let rowInfo: RowInfo?
        switch preferredAttributes.representedElementCategory {
        case .cell:
            rowInfo = (indexPath.item < numberOfItemsInSection) ? rowsInfo[indexPath.item] : nil
        case .supplementaryView:
            if preferredAttributes.representedElementKind == PuzzleCollectionElementKindSectionHeader {
                rowInfo = headerInfo
            }
            else if preferredAttributes.representedElementKind == PuzzleCollectionElementKindSectionFooter {
                rowInfo = footerInfo
            }
            else { rowInfo = nil }
        default:
            rowInfo = nil
        }
        
        if let rowInfo = rowInfo {
            if preferredAttributes.frame.minX < 0 {
                return false
            }
            
            preferredAttributes.frame.origin.x = sectionInsets.left
            if originalAttributes.frame.height != preferredAttributes.frame.height {
                preferredAttributes.frame.size.width = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
                preferredAttributes.frame.origin = CGPoint(x: sectionInsets.left, y: rowInfo.frame.minY)
                return true
            }
            else {
                return false
            }
        }
        else { return false }
    }

    public func invalidationInfo(forPreferredAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Any? {
        
        let indexPath = preferredAttributes.indexPath
        var info: Any? = nil
        switch preferredAttributes.representedElementCategory {
        case .cell:
            rowsInfo[indexPath.item] = RowInfo(estimatedHeight: false, frame: preferredAttributes.frame)
            info = indexPath
            (preferredAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize = preferredAttributes.size
        case .supplementaryView:
            if preferredAttributes.representedElementKind == UICollectionElementKindSectionHeader {
                headerInfo = RowInfo(estimatedHeight: false, frame: preferredAttributes.frame)
                info = kInvalidateHeaderForPreferredHeight
                (preferredAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize = preferredAttributes.size
            } else if preferredAttributes.representedElementKind == UICollectionElementKindSectionFooter {
                footerInfo = RowInfo(estimatedHeight: false, frame: preferredAttributes.frame)
                (preferredAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize = preferredAttributes.size
            }
            
        default: break
        }
        
        return info
    }
    
    //Section top & bottom gutters
    public var topGutterHeight: CGFloat { return showTopGutter ? sectionInsets.top : 0 }
    public var bottomGutterHeight: CGFloat { return showTopGutter ? sectionInsets.bottom : 0 }
    // --------
    
    //MARK: - 
    public func resetLayout() {
        if let ctx = self.invalidationContext(with: kInvalidateForResetLayout, for: self) {
            parentLayout!.invalidateLayout(with: ctx)
        }
    }
    
    // MARK: - Private
    private func prepareRowsFromScratch() {
        var lastOriginY: CGFloat = 0
        
        rowsInfo = [RowInfo](repeating: RowInfo(estimatedHeight: true, frame: CGRect.zero), count: numberOfItemsInSection)
        
        if estimatedHeaderHeight != kEstimatedHeaderFooterHeightNone {
            headerInfo = RowInfo(estimatedHeight: true, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedHeaderHeight))
            lastOriginY += estimatedHeaderHeight
        }
        
        if numberOfItemsInSection != 0 {
            
            lastOriginY += sectionInsets.top
            
            for row in 0 ..< numberOfItemsInSection {
                rowsInfo[row] = RowInfo(estimatedHeight: true, frame: CGRect(x: sectionInsets.left, y: lastOriginY, width: collectionViewWidth - (sectionInsets.left + sectionInsets.right), height: estimatedItemHeight))
                lastOriginY += estimatedItemHeight + interitemSpacing
            }
            
            lastOriginY -= interitemSpacing
            lastOriginY += sectionInsets.bottom
        }
        
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            footerInfo = RowInfo(estimatedHeight: true, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedFooterHeight))
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
                headerInfo = RowInfo(estimatedHeight: true, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedHeaderHeight))
            }
            else if headerInfo!.estimatedHeight {
                headerInfo!.frame.size.height = estimatedHeaderHeight
            }
            
            lastOriginY += headerInfo!.frame.height
        }
        else if headerInfo != nil {
            headerInfo = nil
        }
        
        let rowsToUpdate = min(oldRows, updatedRows)
        
        lastOriginY += sectionInsets.top
        for row in 0 ..< rowsToUpdate {
            var rowInfo = rowsInfo[row]
            rowInfo.frame.size.width = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
            rowInfo.frame.origin = CGPoint(x: sectionInsets.left, y: lastOriginY)
            rowsInfo[row] = rowInfo
            lastOriginY += rowInfo.frame.height + interitemSpacing
        }
        
        if oldRows > updatedRows {
            // Remove rows
            rowsInfo.removeSubrange(updatedRows ..< oldRows)
            
        }
        else if oldRows < updatedRows {
            
            rowsInfo! += [RowInfo](repeating: RowInfo(estimatedHeight: true, frame: CGRect.zero), count: (updatedRows - oldRows))
            
            for row in oldRows ..< updatedRows {
                rowsInfo[row] = RowInfo(estimatedHeight: true, frame: CGRect(x: sectionInsets.left, y: lastOriginY, width: collectionViewWidth - (sectionInsets.left + sectionInsets.right), height: estimatedItemHeight))
                lastOriginY += estimatedItemHeight + interitemSpacing
            }
        }
        
        lastOriginY -= interitemSpacing
        lastOriginY += sectionInsets.bottom

        // Update section footer if needed
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            if footerInfo == nil {
                footerInfo = RowInfo(estimatedHeight: true, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedFooterHeight))
            }
            else if footerInfo!.estimatedHeight {
                footerInfo!.frame.size.height = estimatedFooterHeight
            }
            
            footerInfo!.frame.origin.y = lastOriginY
            lastOriginY += footerInfo!.frame.height
        }
        else if footerInfo != nil {
            footerInfo = nil
        }
    }
    
    private func updateRowsUsingEstimatedHeight() {
        if headerInfo?.estimatedHeight ?? false {
            headerInfo!.frame.size.height = estimatedHeaderHeight
        }
        
        var lastOriginY: CGFloat = (headerInfo?.frame.height ?? 0) + sectionInsets.top
        
        for row in 0 ..< rowsInfo.count {
            var rowInfo = rowsInfo[row]
            if rowInfo.estimatedHeight {
                rowInfo.frame.size.height = estimatedItemHeight
                rowsInfo[row] = rowInfo
            }
            lastOriginY += rowInfo.frame.height + interitemSpacing
        }
        
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            lastOriginY -= interitemSpacing
            lastOriginY += sectionInsets.bottom
            
            footerInfo!.frame.origin.y = lastOriginY
            if footerInfo!.estimatedHeight {
                footerInfo!.frame.size.height = estimatedFooterHeight
            }
        }
    }
    
    private func updateAllRowsWidth() {
        headerInfo?.frame.size.width = collectionViewWidth
        let rowWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        
        for row in 0 ..< rowsInfo.count {
            rowsInfo[row].frame.size.width = rowWidth
        }
        
        footerInfo?.frame.size.width = collectionViewWidth
    }
    
    private func updateRows(forIndexPath indexPath: IndexPath? = nil, forHeader invalidateHeader: Bool = false) {
        
        guard indexPath != nil || invalidateHeader else {
            //Nothing to invalidate
            return
        }
        
        var lastOriginY: CGFloat = 0
        let firstItemForInvalidation: Int
        if let indexPath = indexPath {
            lastOriginY = rowsInfo[indexPath.item].frame.maxY
            firstItemForInvalidation = indexPath.item + 1
        }
        else if invalidateHeader {
            firstItemForInvalidation = 0
            if let headerInfo = headerInfo {
                lastOriginY = headerInfo.frame.maxY + sectionInsets.top
            }
            else {
                lastOriginY = rowsInfo.first?.frame.maxY ?? sectionInsets.top
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
                rowsInfo[index].frame.origin.y = lastOriginY
                lastOriginY = rowsInfo[index].frame.maxY + interitemSpacing
            }
            
            lastOriginY -= interitemSpacing
        }
        
        if footerInfo != nil {
            lastOriginY += sectionInsets.bottom
            footerInfo!.frame.origin.y = lastOriginY
        }
    }
}


//MARK: - Utils
fileprivate struct RowInfo: CustomStringConvertible {
    let estimatedHeight: Bool
    var frame: CGRect
    
    var description: String {
        return "Row Info: estimated:\(estimatedHeight) ; frame: \(frame)"
    }
}

private let kInvalidateForResetLayout = "reset"
private let kInvalidateForEstimatedHeightChange = "estimatedHeight"
private let kInvalidateHeaderForPreferredHeight = "Invalidate_Header"
