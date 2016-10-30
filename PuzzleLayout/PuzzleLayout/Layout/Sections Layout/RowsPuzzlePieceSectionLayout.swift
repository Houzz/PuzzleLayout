//
//  RowsPuzzlePieceSectionLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 25/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

public final class RowsPuzzlePieceSectionLayout: PuzzlePieceSectionLayout {
    
    //MARK: - Public
    public init(rowHeight: CGFloat = 44, sectionInsets: UIEdgeInsets = .zero, rowSpacing: CGFloat = 0,
                headerHeight: HeadeFooterHeightSize = .none, sectionHeaderPinToVisibleBounds: Bool = false,
                footerHeight: HeadeFooterHeightSize = .none, sectionFooterPinToVisibleBounds: Bool = false,
                separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem, showTopGutter: Bool = false, showBottomGutter: Bool = false) {
        self.rowHeight = rowHeight
        self.sectionInsets = sectionInsets
        self.rowSpacing = rowSpacing
        self.headerHeight = headerHeight
        self.sectionHeaderPinToVisibleBounds = sectionHeaderPinToVisibleBounds
        self.footerHeight = footerHeight
        self.sectionFooterPinToVisibleBounds = sectionFooterPinToVisibleBounds
        self.showTopGutter = showTopGutter
        self.showBottomGutter = showBottomGutter
        super.init()
        self.separatorLineStyle = separatorLineStyle
    }
    
    public init(estimatedRowHeight: CGFloat = 100, sectionInsets: UIEdgeInsets = .zero, rowSpacing: CGFloat = 0,
                headerHeight: HeadeFooterHeightSize = .none, sectionHeaderPinToVisibleBounds: Bool = false,
                footerHeight: HeadeFooterHeightSize = .none, sectionFooterPinToVisibleBounds: Bool = false,
                separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem, showTopGutter: Bool = false, showBottomGutter: Bool = false) {
        self.estimatedRowHeight = estimatedRowHeight
        self.sectionInsets = sectionInsets
        self.rowSpacing = rowSpacing
        self.headerHeight = headerHeight
        self.sectionHeaderPinToVisibleBounds = sectionHeaderPinToVisibleBounds
        self.footerHeight = footerHeight
        self.sectionFooterPinToVisibleBounds = sectionFooterPinToVisibleBounds
        self.showTopGutter = showTopGutter
        self.showBottomGutter = showBottomGutter
        super.init()
        self.separatorLineStyle = separatorLineStyle
    }
    
    public var sectionInsets: UIEdgeInsets = .zero {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForSectionInsetsChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateAllRowsForSectionInsetsChange() }
        }
    }
    
    public var rowSpacing: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForRowSpacingChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateAllRowsOriginY() }
        }
    }
    
    public var rowHeight: CGFloat = 44 {
        didSet {
            if estimatedRowHeight == 0 {
                if let ctx = self.invalidationContext(with: kInvalidateForItemHeightChange) {
                    parentLayout!.invalidateLayout(with: ctx)
                }
                else { updateRowsForHeightChange() }
            }
        }
    }

    public var estimatedRowHeight: CGFloat = 0 {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForItemHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateRowsForHeightChange() }
        }
    }
    
    public var headerHeight: HeadeFooterHeightSize = .none {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForHeaderHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateRowsForHeaderHeightChange() }
        }
    }
    
    public var sectionHeaderPinToVisibleBounds: Bool = false {
        didSet {
            switch headerHeight {
            case .none: break
            default:
                if let ctx = self.invalidationContext(with: kInvalidateForHeaderHeightChange) {
                    parentLayout!.invalidateLayout(with: ctx)
                }
            }
        }
    }
    
    public var footerHeight: HeadeFooterHeightSize = .none {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForFooterHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateRowsForFooterHeightChange() }
        }
    }
    
    public var sectionFooterPinToVisibleBounds: Bool = false {
        didSet {
            switch footerHeight {
            case .none: break
            default:
                if let ctx = self.invalidationContext(with: kInvalidateForHeaderHeightChange) {
                    parentLayout!.invalidateLayout(with: ctx)
                }
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
    
    public func resetLayout() {
        if let ctx = self.invalidationContext(with: kInvalidateForResetLayout) {
            ctx.invalidateSectionLayoutData = self
            parentLayout!.invalidateLayout(with: ctx)
        }
    }
    
    //MARK: - Private properties
    private var rowsInfo: [RowInfo]!
    private var headerInfo: HeaderFooterInfo?
    private var footerInfo: HeaderFooterInfo?
    
    private var collectionViewWidth: CGFloat = 0
    
    //MARK: - PuzzlePieceSectionLayout
    override public var heightOfSection: CGFloat {
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
    
    override public func invalidate(willReloadData: Bool, willUpdateDataSourceCounts: Bool, resetLayout: Bool, info: Any?) {
        if resetLayout || ((info as? String) == kInvalidateForResetLayout) {
            rowsInfo = nil
            headerInfo = nil
            footerInfo = nil
        }
        
        guard let _ = rowsInfo else {
            return
        }
        
        if let invalidationStr = info as? String {
            switch invalidationStr {
            case kInvalidateForItemHeightChange:
                updateRowsForHeightChange()
            case kInvalidateForHeaderHeightChange:
                updateRowsForHeaderHeightChange()
            case kInvalidateForFooterHeightChange:
                updateRowsForFooterHeightChange()
            case kInvalidateHeaderForPreferredHeight:
                updateRows(fromHeader: true)
            case kInvalidateForSectionInsetsChange:
                updateAllRowsForSectionInsetsChange()
            case kInvalidateForRowSpacingChange:
                updateAllRowsOriginY()
            default: break
            }
        }
        else if let itemIndexPath = info as? IndexPath {
            updateRows(fromIndexPath: itemIndexPath)
        }
    }
    
    override public func invalidateItem(at indexPath: IndexPath) {
        switch rowsInfo[indexPath.item].heightState {
        case .computed:
            rowsInfo[indexPath.item].heightState = .estimated
        case .fixed:
            if rowsInfo[indexPath.item].height != rowHeight {
                rowsInfo[indexPath.item].height = rowHeight
                updateRows(fromIndexPath: indexPath)
            }
        default: break
        }
    }
    
    override public func invalidateSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) {
        switch  elementKind {
        case PuzzleCollectionElementKindSectionHeader:
            if let _ = headerInfo {
                switch headerInfo!.heightState {
                case .computed:
                    headerInfo!.heightState = .estimated
                case .fixed:
                    switch headerHeight {
                    case .fixed(let height):
                        if headerInfo!.height != height {
                            headerInfo!.height = height
                            updateAllRowsOriginY()
                        }
                    default:
                        assert(false, "How it can be? 'headerInfo.heightState' is fixed but 'headerHeight' isn't")
                    }
                    
                default: break
                }
            }
        case PuzzleCollectionElementKindSectionFooter:
            if let _ = footerInfo {
                switch footerInfo!.heightState {
                case .computed:
                    footerInfo!.heightState = .estimated
                case .fixed:
                    switch footerHeight {
                    case .fixed(let height):
                        footerInfo!.height = height
                    default:
                        assert(false, "How it can be? 'footerInfo.heightState' is fixed but 'footerHeight' isn't")
                    }
                default: break
                }
            }
        default: break
        }
    }
    
    override public func prepare(didReloadData: Bool, didUpdateDataSourceCounts: Bool, didResetLayout: Bool) {
        if rowsInfo == nil {
            collectionViewWidth = sectionWidth
            prepareRowsFromScratch()
        }
        else if didReloadData {
            fixRowsList(willInsertOrDeleteRows: false)
        }
        else if didUpdateDataSourceCounts {
            fixRowsList(willInsertOrDeleteRows: true)
        }
        
        if collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            updateAllRowsWidth()
        }
    }
    
    override public func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes] {
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
                maxY = lastItem.maxOriginY + sectionInsets.bottom
            } else if let header = headerInfo {
                maxY = header.maxOriginY + sectionInsets.bottom
            } else {
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
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        guard indexPath.item < rowsInfo.count else {
            return nil
        }
        
        let rowInfo = rowsInfo[indexPath.item]
        let itemAttributes = PuzzleCollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame = CGRect(x: sectionInsets.left, y: rowInfo.originY, width: collectionViewWidth - (sectionInsets.left + sectionInsets.right), height: rowInfo.height)
        itemAttributes.frame = frame
        if rowInfo.heightState != .estimated {
            itemAttributes.cachedSize = frame.size
        }
        return itemAttributes
    }
    
    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        switch elementKind {
        case PuzzleCollectionElementKindSectionHeader:
            if let headerInfo = headerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
                let frame = CGRect(x: 0, y: headerInfo.originY, width: collectionViewWidth, height: headerInfo.height)
                itemAttributes.frame = frame
                if headerInfo.heightState != .estimated {
                    itemAttributes.cachedSize = frame.size
                }
                
                return itemAttributes
            }
            else { return nil }
        case PuzzleCollectionElementKindSectionFooter:
            if let footerInfo = footerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
                let frame = CGRect(x: 0, y: footerInfo.originY, width: collectionViewWidth, height: footerInfo.height)
                itemAttributes.frame = frame
                if footerInfo.heightState != .estimated {
                    itemAttributes.cachedSize = frame.size
                }
                return itemAttributes
            }
            else { return nil }
        default:
            return nil
        }
    }
    
    override public func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
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
                    maxY = lastItem.maxOriginY + sectionInsets.bottom
                } else if let header = headerInfo {
                    maxY = header.maxOriginY
                } else {
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
    
    //PreferredAttributes Invalidation
    override public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        var shouldInvalidate = false
        switch elementCategory {
        case .cell(let indexPath):
            shouldInvalidate = (indexPath.item < numberOfItemsInSection) && rowsInfo[indexPath.item].heightState != .fixed
        case .supplementaryView(_, let elementKind):
            shouldInvalidate = (
                (elementKind == PuzzleCollectionElementKindSectionHeader && headerInfo != nil && headerInfo!.heightState != .fixed)
                || (elementKind == PuzzleCollectionElementKindSectionFooter && footerInfo != nil && footerInfo!.heightState != .fixed)
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

    override public func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? {
        
        var info: Any? = nil
        switch elementCategory {
        case .cell(let indexPath):
            rowsInfo[indexPath.item].height = preferredSize.height
            rowsInfo[indexPath.item].heightState = .computed
            info = indexPath
        case .supplementaryView(_, let elementKind):
            if elementKind == UICollectionElementKindSectionHeader {
                headerInfo!.height = preferredSize.height
                headerInfo!.heightState = .computed
                info = kInvalidateHeaderForPreferredHeight
            }
            else if elementKind == UICollectionElementKindSectionFooter {
                footerInfo!.height = preferredSize.height
                footerInfo!.heightState = .computed
            }
            
        default: break
        }
        
        return info
    }
    
    override public func shouldPinHeaderSupplementaryView() -> Bool {
        return sectionHeaderPinToVisibleBounds
    }
    
    override public func shouldPinFooterSupplementaryView() -> Bool {
        return sectionFooterPinToVisibleBounds
    }
    
    //Updates
    override public func didInsertItem(at index: Int) {
        if estimatedRowHeight != 0 {
            rowsInfoBeforeUpdate?.insert(RowInfo(heightState: .estimated, originY: 0, height: estimatedRowHeight), at: index)
        }
        else {
            rowsInfoBeforeUpdate?.insert(RowInfo(heightState: .fixed, originY: 0, height: rowHeight), at: index)
        }
    }
    
    override public func didDeleteItem(at index: Int) {
        rowsInfoBeforeUpdate?.remove(at: index)
    }
    
    override public func didReloadItem(at index: Int) {
        if let _ = rowsInfoBeforeUpdate , rowsInfoBeforeUpdate![index].heightState == .computed {
            rowsInfoBeforeUpdate![index].heightState = .estimated
        }
    }
    
    override public func didMoveItem(fromIndex: Int, toIndex: Int) {
        if let item = rowsInfoBeforeUpdate?.remove(at: fromIndex) {
            rowsInfoBeforeUpdate?.insert(item, at: toIndex)
        }
    }
    
    override public func didGenerateUpdatesCall(didHadUpdates: Bool) {
        if didHadUpdates , let updatedRowsInfo = rowsInfoBeforeUpdate , updatedRowsInfo.count == rowsInfo.count {
            rowsInfo = updatedRowsInfo
            updateAllRowsOriginY()
        }
        
        rowsInfoBeforeUpdate = nil
    }
    
    // MARK: - Private
    private func prepareRowsFromScratch() {
        
        rowsInfo = [RowInfo](repeating: RowInfo(heightState: .estimated, originY: 0, height: 0), count: numberOfItemsInSection)
        
        switch headerHeight {
        case .fixed(let height):
            headerInfo = HeaderFooterInfo(heightState: .fixed, originY: 0, height: height)
        case .estimated(let height):
            headerInfo = HeaderFooterInfo(heightState: .estimated, originY: 0, height: height)
        default: break
        }
        
        var lastOriginY: CGFloat = (headerInfo?.maxOriginY ?? 0) + sectionInsets.top
        
        if numberOfItemsInSection != 0 {
            
            let heightState: ItemHeightState
            let height: CGFloat
            if estimatedRowHeight != 0 {
                heightState = .estimated
                height = estimatedRowHeight
            }
            else {
                heightState = .fixed
                height = rowHeight
            }
            
            for row in 0 ..< numberOfItemsInSection {
                rowsInfo[row] = RowInfo(heightState: heightState, originY: lastOriginY, height: height)
                lastOriginY += height + rowSpacing
            }
            
            lastOriginY -= rowSpacing
        }
        
        lastOriginY += sectionInsets.bottom
        
        switch footerHeight {
        case .fixed(let height):
            footerInfo = HeaderFooterInfo(heightState: .fixed, originY: lastOriginY, height: height)
        case .estimated(let height):
            footerInfo = HeaderFooterInfo(heightState: .estimated, originY: lastOriginY, height: height)
        default: break
        }
    }
    
    private var rowsInfoBeforeUpdate: [RowInfo]?
    private func fixRowsList(willInsertOrDeleteRows: Bool) {
        guard rowsInfo != nil else {
            prepareRowsFromScratch()
            return
        }
        
        if willInsertOrDeleteRows {
            rowsInfoBeforeUpdate = rowsInfo
        }
        
        // Update section header if needed
        switch headerHeight {
        case .none:
            headerInfo = nil
        case .fixed(let height):
            if let _ = headerInfo {
                headerInfo!.height = height
                headerInfo!.heightState = .fixed
            }
            else {
                headerInfo = HeaderFooterInfo(heightState: .fixed, originY: 0, height: height)
            }
        case .estimated(let height):
            if let _ = headerInfo {
                if headerInfo!.heightState == .estimated {
                    headerInfo!.height = height
                }
            }
            else {
                headerInfo = HeaderFooterInfo(heightState: .estimated, originY: 0, height: height)
            }
        }
        
        //Update rows
        let updatedRows = numberOfItemsInSection
        let oldRows = rowsInfo.count
        let rowsToUpdate = min(oldRows, updatedRows)
        
        var lastOriginY: CGFloat = (headerInfo?.height ?? 0) + sectionInsets.top
        
        let heightState: ItemHeightState
        let height: CGFloat
        if estimatedRowHeight != 0 {
            heightState = .estimated
            height = estimatedRowHeight
        }
        else {
            heightState = .fixed
            height = rowHeight
        }
        
        for row in 0 ..< rowsToUpdate {
            rowsInfo[row].originY = lastOriginY
            if heightState == .fixed {
                rowsInfo[row].heightState = .fixed
                rowsInfo[row].height = height
            }
            else {
                if rowsInfo[row].heightState != .computed {
                    rowsInfo[row].heightState = .estimated
                    rowsInfo[row].height = height
                }
            }
            lastOriginY += rowsInfo[row].height + rowSpacing
        }
        
        if oldRows > updatedRows {
            // Remove rows
            rowsInfo.removeSubrange(updatedRows ..< oldRows)
        }
        else if oldRows < updatedRows {
            
            rowsInfo! += [RowInfo](repeating: RowInfo(heightState: .estimated, originY: 0, height: 0), count: (updatedRows - oldRows))
            
            for row in oldRows ..< updatedRows {
                rowsInfo[row] = RowInfo(heightState: heightState, originY: lastOriginY, height: height)
                lastOriginY += height + rowSpacing
            }
        }
        
        if rowsInfo.isEmpty == false {
            lastOriginY -= height
        }

        lastOriginY += sectionInsets.bottom
        
        // Update section footer if needed
        switch footerHeight {
        case .none:
            footerInfo = nil
        case .fixed(let height):
            if let _ = footerInfo {
                footerInfo!.height = height
                footerInfo!.heightState = .fixed
            }
            else {
                footerInfo = HeaderFooterInfo(heightState: .fixed, originY: lastOriginY, height: height)
            }
        case .estimated(let height):
            if let _ = footerInfo {
                if footerInfo!.heightState == .estimated {
                    footerInfo!.height = height
                }
            }
            else {
                footerInfo = HeaderFooterInfo(heightState: .estimated, originY: lastOriginY, height: height)
            }
        }
    }
    
    private func updateRowsForHeightChange() {
        var lastOriginY: CGFloat = (headerInfo?.height ?? 0) + sectionInsets.top
        
        let heightState: ItemHeightState
        let height: CGFloat
        if estimatedRowHeight != 0 {
            heightState = .estimated
            height = estimatedRowHeight
        }
        else {
            heightState = .fixed
            height = rowHeight
        }
        
        for row in 0 ..< rowsInfo.count {
            if heightState == .fixed {
                rowsInfo[row].heightState = .fixed
                rowsInfo[row].height = height
            }
            else {
                if rowsInfo[row].heightState != .computed {
                    rowsInfo[row].heightState = .estimated
                    rowsInfo[row].height = height
                }
            }
            lastOriginY += rowsInfo[row].height + rowSpacing
        }
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            if rowsInfo.isEmpty == false {
                lastOriginY -= rowSpacing
            }
            
            lastOriginY += sectionInsets.bottom
            
            footerInfo!.originY = lastOriginY
        }
    }
    
    private func updateAllRowsWidth() {
        if let _ = headerInfo , headerInfo!.heightState == .computed {
            headerInfo!.heightState = .estimated
        }
        
        if estimatedRowHeight != 0 {
            for row in 0 ..< rowsInfo.count {
                if rowsInfo[row].heightState == .computed {
                    rowsInfo[row].heightState = .estimated
                }
            }
        }
        
        if let _ = footerInfo , footerInfo!.heightState == .computed {
            footerInfo!.heightState = .estimated
        }
    }
    
    private func updateAllRowsOriginY() {
        var lastOriginY = (headerInfo?.height ?? 0) + sectionInsets.top
        
        for row in 0 ..< rowsInfo.count {
            rowsInfo[row].originY = lastOriginY
            lastOriginY += rowsInfo[row].height + rowSpacing
        }
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            if rowsInfo.isEmpty == false {
                lastOriginY -= rowSpacing
            }
            
            lastOriginY += sectionInsets.bottom
            footerInfo!.originY = lastOriginY
        }
    }
    
    private func updateAllRowsForSectionInsetsChange() {
        
        var lastOriginY = (headerInfo?.height ?? 0) + sectionInsets.top
        
        for row in 0 ..< rowsInfo.count {
            rowsInfo[row].originY = lastOriginY
            lastOriginY += rowsInfo[row].height + rowSpacing
        }
        
        if footerInfo != nil {
            //No need to make those computation if no footer
            if rowsInfo.isEmpty == false {
                lastOriginY -= rowSpacing
            }
            
            lastOriginY += sectionInsets.bottom
            footerInfo!.originY = lastOriginY
        }
    }
    
    private func updateRows(fromIndexPath indexPath: IndexPath? = nil, fromHeader invalidateHeader: Bool = false) {
        
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
                lastOriginY += rowSpacing
            }
            
            for index in firstItemForInvalidation..<numberOfItemsInSection {
                rowsInfo[index].originY = lastOriginY
                lastOriginY = rowsInfo[index].maxOriginY + rowSpacing
            }
            
            lastOriginY -= rowSpacing
        }
        
        if footerInfo != nil {
            lastOriginY += sectionInsets.bottom
            footerInfo!.originY = lastOriginY
        }
    }
    
    private func updateRowsForHeaderHeightChange() {
        
        // Update section header if needed
        switch headerHeight {
        case .none:
            headerInfo = nil
        case .fixed(let height):
            if let _ = headerInfo {
                headerInfo!.height = height
                headerInfo!.heightState = .fixed
            }
            else {
                headerInfo = HeaderFooterInfo(heightState: .fixed, originY: 0, height: height)
            }
        case .estimated(let height):
            if let _ = headerInfo {
                if headerInfo!.heightState == .estimated {
                    headerInfo!.height = height
                }
            }
            else {
                headerInfo = HeaderFooterInfo(heightState: .estimated, originY: 0, height: height)
            }
        }
        
        updateAllRowsOriginY()
    }
    
    private func updateRowsForFooterHeightChange() {
        // Update section footer if needed
        switch footerHeight {
        case .none:
            footerInfo = nil
        case .fixed(let height):
            if let _ = footerInfo {
                footerInfo!.height = height
                footerInfo!.heightState = .fixed
            }
            else {
                let originY: CGFloat
                if let lastRow = rowsInfo.last {
                    originY = lastRow.maxOriginY + sectionInsets.bottom
                }
                else if let header = headerInfo {
                    originY = header.maxOriginY + sectionInsets.top + sectionInsets.bottom
                }
                else {
                    originY = sectionInsets.top + sectionInsets.bottom
                }
                footerInfo = HeaderFooterInfo(heightState: .fixed, originY: originY, height: height)
            }
        case .estimated(let height):
            if let _ = footerInfo {
                if footerInfo!.heightState == .estimated {
                    footerInfo!.height = height
                }
            }
            else {
                let originY: CGFloat
                if let lastRow = rowsInfo.last {
                    originY = lastRow.maxOriginY + sectionInsets.bottom
                }
                else if let header = headerInfo {
                    originY = header.maxOriginY + sectionInsets.top + sectionInsets.bottom
                }
                else {
                    originY = sectionInsets.top + sectionInsets.bottom
                }
                footerInfo = HeaderFooterInfo(heightState: .estimated, originY: originY, height: height)
            }
        }
    }
}


//MARK: - Utils
fileprivate struct RowInfo: CustomStringConvertible {
    var heightState: ItemHeightState
    var originY: CGFloat
    var height: CGFloat
    var maxOriginY: CGFloat {
        return originY + height
    }
    
    func intersects(with rect: CGRect) -> Bool {
        return !(originY >= rect.maxY || maxOriginY <= rect.minY)
    }
    
    var description: String {
        return "Row Info: state:\(heightState) ; origin Y: \(originY) ; Height: \(height)"
    }
}

private let kInvalidateForResetLayout = "Reset"
private let kInvalidateForItemHeightChange = "ItemHeight"
private let kInvalidateForHeaderHeightChange = "HeaderHeight"
private let kInvalidateForFooterHeightChange = "FooterHeight"
private let kInvalidateHeaderForPreferredHeight = "PreferredHeaderHeight"
private let kInvalidateForSectionInsetsChange = "SectionInsets"
private let kInvalidateForRowSpacingChange = "RowSpacing"
