//
//  ColumnBasedPuzzlePieceSectionLayout.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 05/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

public class ColumnBasedPuzzlePieceSectionLayout: PuzzlePieceSectionLayout, PuzzlePieceSectionLayoutSeperatable {
    
    //MARK: - Public
    public var sectionInsets: UIEdgeInsets = .zero {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForRowInfoChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else if let _ = itemsInfo {
                if let type = estimatedColumnType ?? columnType {
                    if type.hasItemSize {
                        itemSizeBased_fixForRowInfoChange()
                    }
                    else {
                        columnsNumberBased_fixForRowInfoChange()
                    }
                }
            }
        }
    }

    public var minimumInteritemSpacing: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForRowInfoChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else if let _ = itemsInfo {
                if let type = estimatedColumnType ?? columnType {
                    if type.hasItemSize {
                        itemSizeBased_fixForRowInfoChange()
                    }
                    else {
                        columnsNumberBased_fixForRowInfoChange()
                    }
                }
            }
        }
    }

    public var minimumLineSpacing: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForMinimumLineSpacingChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else if let _ = itemsInfo {
                updateItemsOriginY(forceUpdateOrigin: true)
            }
        }
    }

    public private(set) var columnType: ColumnType? = .itemSize(size: CGSize(width: 50, height: 50))
    public private(set) var estimatedColumnType: ColumnType? = nil
    public private(set) var rowAlignment: RowAlignmentOnItemSelfSizing = .none
    public func setColumnType(_ type: ColumnType) {
        estimatedColumnType = nil
        rowAlignment = .none
        columnType = type
        if let ctx = self.invalidationContext(with: kInvalidateForColumnTypeChange) {
            parentLayout!.invalidateLayout(with: ctx)
        }
        else if let _ = itemsInfo {
            updateItemsList()
        }
    }
    
    public func setEstimatedColumnType(_ type: ColumnType, rowAlignment: RowAlignmentOnItemSelfSizing) {
        columnType = nil
        
        if rowAlignment == .none {
            #if DEBUGLog
                DEBUGLog("'rowAlignment' can't be none. Set to alignCenter")
            #endif
            self.rowAlignment = .alignCenter
        }
        else {
            self.rowAlignment = rowAlignment
        }
        
        estimatedColumnType = type
        if let ctx = self.invalidationContext(with: kInvalidateForColumnTypeChange) {
            parentLayout!.invalidateLayout(with: ctx)
        }
        else if let _ = itemsInfo {
            updateItemsList()
        }
    }
    
    public func updateRowAlignment(to rowAlignment: RowAlignmentOnItemSelfSizing) {
        guard estimatedColumnType != nil else {
            #if DEBUGLog
                DEBUGLog("can't update 'rowAlignment' when 'estimatedColumnType' is nil.")
            #endif
            return
        }
        
        if rowAlignment == .none {
            #if DEBUGLog
                DEBUGLog("'rowAlignment' can't be none. Set to alignCenter")
            #endif
            self.rowAlignment = .alignCenter
        }
        else {
            self.rowAlignment = rowAlignment
        }
        
        if let ctx = self.invalidationContext(with: kInvalidateForRowAlignmentChange) {
            parentLayout!.invalidateLayout(with: ctx)
        }
    }
    
    public var headerHeight: HeadeFooterHeightSize = .none {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForHeaderEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateItemsOriginY(updateHeaderHeight: true)
            }
        }
    }
    
    public var sectionHeaderPinToVisibleBounds: Bool = false {
        didSet {
            switch headerHeight {
            case .none: break
            default:
                if let ctx = self.invalidationContext(with: kInvalidateForHeaderEstimatedHeightChange) {
                    parentLayout!.invalidateLayout(with: ctx)
                }
            }
        }
    }
    
    public var footerHeight: HeadeFooterHeightSize = .none {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForFooterEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateFooter()
            }
        }
    }
    
    public var sectionFooterPinToVisibleBounds: Bool = false {
        didSet {
            switch footerHeight {
            case .none: break
            default:
                if let ctx = self.invalidationContext(with: kInvalidateForFooterEstimatedHeightChange) {
                    parentLayout!.invalidateLayout(with: ctx)
                }
            }
        }
    }
    
    public var showTopGutter: Bool = false {
        didSet {
            if oldValue != showTopGutter && sectionInsets.top != 0, let ctx = self.invalidationContext {
                ctx.invalidateSectionLayoutData = self
                ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSectionTopGutter, at: [indexPath(forIndex: 0)!])
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    public var showBottomGutter: Bool = false {
        didSet {
            if oldValue != showBottomGutter && sectionInsets.bottom != 0, let ctx = self.invalidationContext {
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
    
    //MARK: - Init
    public init(columnType: ColumnType, sectionInsets: UIEdgeInsets = .zero, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0,
         headerHeight: HeadeFooterHeightSize = .none, sectionHeaderPinToVisibleBounds: Bool = false,
         footerHeight: HeadeFooterHeightSize = .none, sectionFooterPinToVisibleBounds: Bool = false,
         separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem, separatorLineInsets: UIEdgeInsets = .zero, separatorLineColor: UIColor? = nil,
         showTopGutter: Bool = false, showBottomGutter: Bool = false) {
        self.columnType = columnType
        self.sectionInsets = sectionInsets
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.headerHeight = headerHeight
        self.sectionHeaderPinToVisibleBounds = sectionHeaderPinToVisibleBounds
        self.footerHeight = footerHeight
        self.sectionFooterPinToVisibleBounds = sectionFooterPinToVisibleBounds
        self.showTopGutter = showTopGutter
        self.showBottomGutter = showBottomGutter
        super.init()
        self.separatorLineStyle = separatorLineStyle
        self.separatorLineInsets = separatorLineInsets
        self.separatorLineColor = separatorLineColor
    }
    
    public init(estimatedColumnType: ColumnType, rowAlignment: RowAlignmentOnItemSelfSizing = .alignCenter,
         sectionInsets: UIEdgeInsets = .zero, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0,
         headerHeight: HeadeFooterHeightSize = .none, sectionHeaderPinToVisibleBounds: Bool = false,
         footerHeight: HeadeFooterHeightSize = .none, sectionFooterPinToVisibleBounds: Bool = false,
         separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem, separatorLineInsets: UIEdgeInsets = .zero, separatorLineColor: UIColor? = nil,
         showTopGutter: Bool = false, showBottomGutter: Bool = false) {
        self.estimatedColumnType = estimatedColumnType
        self.rowAlignment = rowAlignment
        self.sectionInsets = sectionInsets
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.headerHeight = headerHeight
        self.sectionHeaderPinToVisibleBounds = sectionHeaderPinToVisibleBounds
        self.footerHeight = footerHeight
        self.sectionFooterPinToVisibleBounds = sectionFooterPinToVisibleBounds
        self.showTopGutter = showTopGutter
        self.showBottomGutter = showBottomGutter
        super.init()
        self.separatorLineStyle = separatorLineStyle
        self.separatorLineInsets = separatorLineInsets
        self.separatorLineColor = separatorLineColor
    }
    
    //MARK: - PuzzlePieceSectionLayout
    override public var heightOfSection: CGFloat {
        var maxY: CGFloat = 0
        if let footer = footerInfo {
            maxY = footer.maxOriginY
        } else if let lastItem = itemsInfo.last {
            maxY = lastItem.frame.minY + lastItem.rowHeight + sectionInsets.bottom
        } else if let header = headerInfo {
            maxY = header.maxOriginY + sectionInsets.bottom
        }
        
        return maxY
    }
    
    override public func invalidate(willReloadData: Bool, willUpdateDataSourceCounts: Bool, resetLayout: Bool, info: Any?) {
        
        super.invalidate(willReloadData: willReloadData, willUpdateDataSourceCounts: willUpdateDataSourceCounts, resetLayout: resetLayout, info: info)
        
        if resetLayout || ((info as? String) == kInvalidateForResetLayout) {
            itemsInfo = nil
            headerInfo = nil
            footerInfo = nil
        }
        
        guard let _ = itemsInfo else {
            return
        }
        
        if let invalidationStr = info as? String {
            switch invalidationStr {
            case kInvalidateForRowInfoChange:
                if let type = estimatedColumnType ?? columnType {
                    if type.hasItemSize {
                        itemSizeBased_fixForRowInfoChange()
                    }
                    else {
                        columnsNumberBased_fixForRowInfoChange()
                    }
                }
            case kInvalidateForColumnTypeChange:
                updateItemsList()
            case kInvalidateForHeaderEstimatedHeightChange:
                updateItemsOriginY(updateHeaderHeight: true)
            case kInvalidateHeaderForPreferredHeight, kInvalidateForMinimumLineSpacingChange:
                updateItemsOriginY(forceUpdateOrigin: true)
            case kInvalidateForFooterEstimatedHeightChange:
                updateFooter()
            default: break
            }
        }
        else if let itemIndexPath = info as? IndexPath {
            updateItems(fromIndexPath: itemIndexPath)
        }
    }
    
    override public func invalidateItem(at indexPath: IndexPath) {
        switch itemsInfo[indexPath.item].heightState {
        case .computed:
            itemsInfo[indexPath.item].heightState = .estimated
        case .fixed:
            if itemsInfo[indexPath.item].frame.height != itemSize.height {
                itemsInfo[indexPath.item].frame.size.height = itemSize.height
                itemsInfo[indexPath.item].rowHeight = itemSize.height
                updateItems(fromIndexPath: indexPath)
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
                            updateItemsOriginY(forceUpdateOrigin: true)
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
                        if footerInfo!.height != height {
                            footerInfo!.height = height
                        }
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
        if itemsInfo == nil {
            collectionViewWidth = sectionWidth
            prepareItemsFromScratch()
        }
        else if didUpdateDataSourceCounts {
            if fixCountOfItemsList() || (collectionViewWidth != sectionWidth) {
                collectionViewWidth = sectionWidth
                updateItemsList()
            }
        }
        else if collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            updateItemsList()
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
        
        for itemIndex in 0 ..< numberOfItemsInSection {
            let itemInfo = itemsInfo[itemIndex]
            var itemFrame = itemInfo.frame
            switch rowAlignment {
            case .equalHeight:
                itemFrame.size.height = itemInfo.rowHeight
            case .alignBottom:
                itemFrame.origin.y += (itemInfo.rowHeight - itemFrame.height)
            case .alignCenter:
                itemFrame.origin.y += (itemInfo.rowHeight - itemFrame.height) * 0.5
            default: break
            }
            
            if itemFrame.intersects(rect) {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forCellWith: IndexPath(item: itemIndex, section: sectionIndex))
                itemAttributes.frame = itemFrame
                if itemInfo.heightState != .estimated {
                    itemAttributes.cachedSize = itemFrame.size
                }
                
                attributesInRect.append(itemAttributes)
            } else if rect.maxY < itemInfo.frame.minY {
                break
            }
        }
        
        if showBottomGutter && sectionInsets.bottom != 0 {
            let maxY: CGFloat
            if let footer = footerInfo {
                maxY = footer.originY
            } else if let lastItem = itemsInfo.last {
                maxY = lastItem.frame.minY + lastItem.rowHeight + sectionInsets.bottom
            } else if let header = headerInfo {
                maxY = header.maxOriginY + sectionInsets.bottom
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
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        guard indexPath.item < itemsInfo.count else {
            return nil
        }
        
        let itemInfo = itemsInfo[indexPath.item]
        let itemAttributes = PuzzleCollectionViewLayoutAttributes(forCellWith: indexPath)
        var itemFrame = itemInfo.frame
        switch rowAlignment {
        case .equalHeight:
            itemFrame.size.height = itemInfo.rowHeight
        case .alignBottom:
            itemFrame.origin.y += (itemInfo.rowHeight - itemFrame.height)
        case .alignCenter:
            itemFrame.origin.y += (itemInfo.rowHeight - itemFrame.height) * 0.5
        default: break
        }
        
        itemAttributes.frame = itemFrame
        if itemInfo.heightState != .estimated {
            itemAttributes.cachedSize = itemFrame.size
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
            } else { return nil }
        case PuzzleCollectionElementKindSectionFooter:
            if let footerInfo = footerInfo {
                let itemAttributes = PuzzleCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
                let frame = CGRect(x: 0, y: footerInfo.originY, width: collectionViewWidth, height: footerInfo.height)
                itemAttributes.frame = frame
                if footerInfo.heightState != .estimated {
                    itemAttributes.cachedSize = frame.size
                }
                return itemAttributes
            } else { return nil }
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
                } else if let lastItem = itemsInfo.last {
                    maxY = lastItem.frame.minY + lastItem.rowHeight + sectionInsets.bottom
                } else if let header = headerInfo {
                    maxY = header.maxOriginY + sectionInsets.bottom
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
    
    override public func shouldPinHeaderSupplementaryView() -> Bool {
        return sectionHeaderPinToVisibleBounds
    }
    
    override public func shouldPinFooterSupplementaryView() -> Bool {
        return sectionFooterPinToVisibleBounds
    }
    
    //PreferredAttributes Invalidation
    override public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        var shouldInvalidate = false
        switch elementCategory {
        case .cell(let indexPath):
            if (estimatedColumnType != nil && (indexPath.item < numberOfItemsInSection)) && preferredSize.height != originalSize.height {
                shouldInvalidate = (itemsInfo[indexPath.item].heightState != .computed || itemsInfo[indexPath.item].rowHeight < preferredSize.height)
            }
        case .supplementaryView(_, let elementKind):
            shouldInvalidate = (
                ((elementKind == PuzzleCollectionElementKindSectionHeader && headerInfo != nil && headerInfo!.heightState != .fixed)
                    || (elementKind == PuzzleCollectionElementKindSectionFooter && footerInfo != nil && footerInfo!.heightState != .fixed) )
                    && (preferredSize.height != originalSize.height)
            )
        default: break
        }
        
        if shouldInvalidate {
            preferredSize.width = originalSize.width
            preferredSize.height = ceil(preferredSize.height)
            return true
        }
        else { return false }
    }
    
    override public func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? {
        
        var info: Any? = nil
        switch elementCategory {
        case .cell(let indexPath):
            itemsInfo[indexPath.item].frame.size.height = preferredSize.height
            itemsInfo[indexPath.item].heightState = .computed
            info = indexPath
        case .supplementaryView(_, let elementKind):
            if elementKind == PuzzleCollectionElementKindSectionHeader {
                headerInfo!.height = preferredSize.height
                headerInfo!.heightState = .computed
                info = kInvalidateHeaderForPreferredHeight
            }
            else if elementKind == PuzzleCollectionElementKindSectionFooter {
                footerInfo!.height = preferredSize.height
                footerInfo!.heightState = .computed
            }
            
        default: break
        }
        
        return info
    }
    
    //MARK: - Private properties
    fileprivate var itemsInfo: [ItemInfo]!
    fileprivate var headerInfo: HeaderFooterInfo?
    fileprivate var footerInfo: HeaderFooterInfo?
    fileprivate var numberOfColumnsInRow: Int = 1
    fileprivate var itemSize: CGSize = .zero
    fileprivate var actualInteritemSpacing: CGFloat = 0
    
    fileprivate var collectionViewWidth: CGFloat = 0
    
    //MARK: - Private 
    fileprivate func numberOfColumns(from itemSize: CGSize) -> Int {
        guard itemSize.width != 0 else {
            return 0
        }
        
        let contentWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        return Int(floor((contentWidth + minimumInteritemSpacing) / (itemSize.width + minimumInteritemSpacing)))
    }
    
    fileprivate func itemWidth(from numberOfColumns: Int) -> CGFloat {
        guard numberOfColumnsInRow != 0 else {
            return 0
        }
        
        let contentWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        var itemWidth = (contentWidth - (minimumInteritemSpacing * (CGFloat(numberOfColumns - 1))))
        itemWidth /= CGFloat(numberOfColumns)
        return floor(itemWidth * 2) * 0.5 //Floor to nearest half
    }
    
    private func prepareItemsFromScratch() {
        updateItemSizeAndNumberOfColumns()
        let heightState: ItemHeightState = (estimatedColumnType != nil) ? .estimated : .fixed

        itemsInfo = [ItemInfo](repeating: ItemInfo(heightState: heightState), count: numberOfItemsInSection)
        guard numberOfColumnsInRow != 0 else {
            assert(false, "Number of columns can't be 0")
            return
        }
        
        switch headerHeight {
        case .fixed(let height):
            headerInfo = HeaderFooterInfo(heightState: .fixed, originY: 0, height: height)
        case .estimated(let height):
            headerInfo = HeaderFooterInfo(heightState: .estimated, originY: 0, height: height)
        default: break
        }
        
        var lastOriginY: CGFloat = (headerInfo?.maxOriginY ?? 0) + sectionInsets.top
        
        if numberOfItemsInSection != 0 {
            if numberOfColumnsInRow == 1 {
                let originX = (collectionViewWidth - itemSize.width) * 0.5
                for index in 0..<numberOfItemsInSection {
                    itemsInfo[index] = ItemInfo(heightState: heightState, frame: CGRect(origin: CGPoint(x: originX, y: lastOriginY), size: itemSize))
                    lastOriginY += itemSize.height + minimumLineSpacing
                }
            }
            else {
                var startItemIndex = 0
                while startItemIndex < numberOfItemsInSection {
                    let endItemIndex = min(startItemIndex + numberOfColumnsInRow - 1, numberOfItemsInSection - 1)
                    var lastOriginX = sectionInsets.left
                    for index in startItemIndex...endItemIndex {
                        itemsInfo[index] = ItemInfo(heightState: heightState, frame: CGRect(origin: CGPoint(x: lastOriginX, y: lastOriginY), size: itemSize))
                        lastOriginX += itemSize.width + actualInteritemSpacing
                    }
                    
                    startItemIndex = endItemIndex + 1
                    lastOriginY += itemSize.height + minimumLineSpacing
                }
            }
            
            lastOriginY -= minimumLineSpacing
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
    
    //MARK: - Updates
    private func updateItemSizeAndNumberOfColumns() {
        assert(estimatedColumnType != nil || columnType != nil, "'estimatedColumnType' and 'columnType' can't be both nil")
        let type = (estimatedColumnType ?? columnType)!
        switch type {
        case .itemSize(let itemSize):
            self.itemSize = itemSize
            self.numberOfColumnsInRow = numberOfColumns(from: itemSize)
        case .dynamicItemSize(let closure):
            self.itemSize = closure(self, collectionViewWidth)
            self.numberOfColumnsInRow = numberOfColumns(from: itemSize)
        case .numberOfColumns(let numberOfColumns, let height):
            self.itemSize = CGSize(width: 0, height: height)
            self.numberOfColumnsInRow = Int(numberOfColumns)
            self.itemSize.width = itemWidth(from: self.numberOfColumnsInRow)
        case .dynamicNumberOfColumns(let closure):
            let res = closure(self, collectionViewWidth)
            self.itemSize = CGSize(width: 0, height: res.itemHeight)
            self.numberOfColumnsInRow = Int(res.numberOfColumns)
            self.itemSize.width = itemWidth(from: self.numberOfColumnsInRow)
        case .numberOfColumnsWithWidthDependency(let numberOfColumns, let heightWidthRatio, let heightConstant):
            self.numberOfColumnsInRow = Int(numberOfColumns)
            self.itemSize.width = itemWidth(from: self.numberOfColumnsInRow)
            self.itemSize.height = (self.itemSize.width * heightWidthRatio) + heightConstant
        }
        
        updateActualInteritemSpacing()
    }
    
    fileprivate func updateActualInteritemSpacing() {
        guard numberOfColumnsInRow != 0 else {
            actualInteritemSpacing = 0
            return
        }
        
        guard itemSize.width != 0 else {
            actualInteritemSpacing = 0
            return
        }
        
        let contentWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        actualInteritemSpacing = floor((contentWidth - (CGFloat(numberOfColumnsInRow) * (itemSize.width))) / CGFloat(numberOfColumnsInRow-1) * 2) * 0.5
    }
    
    fileprivate func updateItemsOriginXForMultipleColumns(updateItemWidth: Bool) {
        var startItemIndex = 0
        var rowIndex = 0
        
        while startItemIndex < numberOfItemsInSection {
            let endItemIndex = min(startItemIndex + numberOfColumnsInRow - 1, numberOfItemsInSection - 1)
            var lastOriginX = sectionInsets.left
            
            for index in startItemIndex...endItemIndex {
                itemsInfo[index].frame.origin.x = lastOriginX
                
                if updateItemWidth {
                    itemsInfo[index].frame.size.width = itemSize.width
                    if itemsInfo[index].heightState != .fixed {
                        itemsInfo[index].heightState = .estimated
                    }
                }
                
                lastOriginX += itemSize.width + actualInteritemSpacing
            }
            
            startItemIndex = endItemIndex + 1
            rowIndex += 1
        }
    }
    
    fileprivate func updateItemsWidthAndOriginXForSingleColumn() {
        let originX = (collectionViewWidth - itemSize.width) * 0.5
        for index in 0..<numberOfItemsInSection {
            itemsInfo[index].frame.origin.x = originX
            itemsInfo[index].frame.size.width = itemSize.width
            if itemsInfo[index].heightState != .fixed {
                itemsInfo[index].heightState = .estimated
            }
        }
    }
    
    fileprivate func updateItemsOriginY(forceUpdateOrigin: Bool = false, updateItemHeight: Bool = false, updateHeaderHeight: Bool = false) {
        var didUpdateHeader = false
        if updateHeaderHeight {
            let oldHeight = (headerInfo?.maxOriginY ?? 0)
            updateHeader()
            didUpdateHeader = (headerInfo?.maxOriginY ?? 0) != oldHeight
        }
        
        guard forceUpdateOrigin || didUpdateHeader || updateItemHeight else {
            return
        }
        
        if numberOfColumnsInRow == 1 {
            updateItemsOriginYForSingleColumn(forceUpdateOrigin: forceUpdateOrigin, updateItemHeight: updateItemHeight)
        }
        else {
            updateItemsOriginYForMultipleColumns(forceUpdateOrigin: forceUpdateOrigin, updateItemHeight: updateItemHeight)
        }
    }
    
    private func updateItemsOriginYForMultipleColumns(forceUpdateOrigin: Bool = false, updateItemHeight: Bool = false) {
        guard let _ = itemsInfo else { return }
        
        var lastOriginY: CGFloat = (headerInfo?.maxOriginY ?? 0) + sectionInsets.top
        
        var startItemIndex = 0
        
        let estiamted: Bool = (estimatedColumnType != nil)
        
        if numberOfItemsInSection != 0 {
            while startItemIndex < numberOfItemsInSection {
                let endItemIndex = min(startItemIndex + numberOfColumnsInRow - 1, numberOfItemsInSection - 1)
                var lastOriginX = sectionInsets.left
                
                var maxHeight: CGFloat = 0
                for index in startItemIndex...endItemIndex {
                    if updateItemHeight {
                        if estiamted {
                            if itemsInfo[index].heightState != .computed {
                                itemsInfo[index].heightState = .estimated
                                itemsInfo[index].frame.size.height = itemSize.height
                            }
                        }
                        else {
                            itemsInfo[index].frame.size.height = itemSize.height
                            itemsInfo[index].heightState = .fixed
                        }
                    }
                    
                    maxHeight = max(maxHeight, itemsInfo[index].frame.height)
                }
                
                for index in startItemIndex...endItemIndex {
                    itemsInfo[index].frame.origin = CGPoint(x: lastOriginX, y: lastOriginY)
                    itemsInfo[index].rowHeight = maxHeight
                    lastOriginX += itemSize.width + actualInteritemSpacing
                }
                
                startItemIndex = endItemIndex + 1
                lastOriginY += maxHeight + minimumLineSpacing
            }
            lastOriginY -= minimumLineSpacing
        }
        
        lastOriginY += sectionInsets.bottom
        updateFooter(originY: lastOriginY)
    }
    
    private func updateItemsOriginYForSingleColumn(forceUpdateOrigin: Bool = false, updateItemHeight: Bool = false) {
        guard let _ = itemsInfo else { return }

        let originX = (collectionViewWidth - itemSize.width) * 0.5
        var lastOriginY: CGFloat = (headerInfo?.maxOriginY ?? 0) + sectionInsets.top
        let estiamted: Bool = (estimatedColumnType != nil)
        
        if numberOfItemsInSection != 0 {
            for index in 0..<numberOfItemsInSection {
                itemsInfo[index].frame.origin = CGPoint(x: originX, y: lastOriginY)
                itemsInfo[index].rowHeight = itemsInfo[index].frame.height
                
                if updateItemHeight {
                    if estiamted {
                        if itemsInfo[index].heightState != .computed {
                            itemsInfo[index].heightState = .estimated
                            itemsInfo[index].frame.size.height = itemSize.height
                        }
                    }
                    else {
                        itemsInfo[index].frame.size.height = itemSize.height
                        itemsInfo[index].heightState = .fixed
                    }
                }
                
                lastOriginY += itemsInfo[index].frame.height + minimumLineSpacing
            }
            lastOriginY -= minimumLineSpacing
        }
        
        lastOriginY += sectionInsets.bottom
        updateFooter(originY: lastOriginY)
    }
    
    private func updateItems(fromIndexPath indexPath: IndexPath) {
        if numberOfColumnsInRow == 1 {
            itemsInfo[indexPath.item].rowHeight = itemsInfo[indexPath.item].frame.height
            
            var lastOriginY: CGFloat = itemsInfo[indexPath.item].frame.maxY
            if indexPath.item + 1 != numberOfItemsInSection {
                lastOriginY += minimumLineSpacing
                for index in indexPath.item ..< numberOfItemsInSection {
                    itemsInfo[index].frame.origin.y = lastOriginY
                    lastOriginY += itemsInfo[index].rowHeight + minimumLineSpacing
                }
            }
            
            lastOriginY += sectionInsets.bottom
            updateFooter(originY: lastOriginY)

        }
        else {
            var startItemIndex = indexPath.item - (indexPath.item % numberOfColumnsInRow)
            var lastOriginY: CGFloat = itemsInfo[indexPath.item].frame.minY
            if startItemIndex < numberOfItemsInSection {
                while startItemIndex < numberOfItemsInSection {
                    let endItemIndex = min(startItemIndex + numberOfColumnsInRow - 1, numberOfItemsInSection - 1)
                    var maxHeight: CGFloat = 0
                    for index in startItemIndex...endItemIndex {
                        maxHeight = max(maxHeight, itemsInfo[index].frame.height)
                    }
                    
                    for index in startItemIndex...endItemIndex {
                        itemsInfo[index].frame.origin.y = lastOriginY
                        itemsInfo[index].rowHeight = maxHeight
                    }
                    
                    lastOriginY += maxHeight + minimumLineSpacing
                    startItemIndex = endItemIndex + 1
                }
                
                lastOriginY -= minimumLineSpacing
            }
            else {
                lastOriginY = itemsInfo[indexPath.item].frame.maxY
            }
            
            lastOriginY += sectionInsets.bottom
            updateFooter(originY: lastOriginY)
        }
    }
    
    private func updateHeader() {
        switch headerHeight {
        case .none:
            if let _ = headerInfo {
                headerInfo = nil
            }
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
    }
    
    private func updateFooter(originY: CGFloat? = nil) {
        var lastOriginY: CGFloat! = originY
        if lastOriginY == nil {
            if let lastItem = itemsInfo.last {
                lastOriginY = lastItem.frame.origin.y + lastItem.rowHeight + sectionInsets.bottom
            }
            else if let header = headerInfo {
                lastOriginY = header.maxOriginY + sectionInsets.top + sectionInsets.bottom
            }
            else {
                lastOriginY = sectionInsets.top + sectionInsets.bottom
            }
        }
        
        // Update section footer if needed
        switch footerHeight {
        case .none:
            footerInfo = nil
        case .fixed(let height):
            if let _ = footerInfo {
                footerInfo!.originY = lastOriginY
                footerInfo!.height = height
                footerInfo!.heightState = .fixed
            }
            else {
                footerInfo = HeaderFooterInfo(heightState: .fixed, originY: lastOriginY, height: height)
            }
        case .estimated(let height):
            if let _ = footerInfo {
                footerInfo!.originY = lastOriginY
                if footerInfo!.heightState == .estimated {
                    footerInfo!.height = height
                }
            }
            else {
                footerInfo = HeaderFooterInfo(heightState: .estimated, originY: lastOriginY, height: height)
            }
        }
    }
    
    /*
     1. Section insets or minimum inter-item spacing changed & based on item size:
        1.1. Compute number of column
        1.2. Number of columns did change:
            1.2.1. Fix origin X & origin Y
            1.2.2. Fix row height
            1.2.3. Fix row index
            1.2.4. fix item index at row
        1.3. Number of columns didn’t change:
            1.3.1 Number of columns is 1: Do nothing.
            1.3.2 Number of columns is bigger than 1: Update origin X
     */
    private func itemSizeBased_fixForRowInfoChange() {
        let updatedNumberOfColumns = numberOfColumns(from: self.itemSize)
        updateActualInteritemSpacing()
        guard numberOfItemsInSection != 0 else {
            self.numberOfColumnsInRow = updatedNumberOfColumns
            return
        }
        
        if updatedNumberOfColumns != self.numberOfColumnsInRow {
            self.numberOfColumnsInRow = updatedNumberOfColumns
            updateItemsOriginY(forceUpdateOrigin: true)
        }
        else {
            if numberOfColumnsInRow != 1 {
                updateItemsOriginXForMultipleColumns(updateItemWidth: false)
            }
        }
    }
    
    /*
     1. Section insets or minimum inter-item spacing changed & based on number of columns:
        1.1. Compute item width
        1.2. Compute actual interitem spacing
        1.3. Update origin X and item width
        1.4. If height state isn’t fixed. Set it as estimated.
     */
    private func columnsNumberBased_fixForRowInfoChange() {
        self.itemSize.width = itemWidth(from: self.numberOfColumnsInRow)
        updateActualInteritemSpacing()
        if numberOfColumnsInRow == 1 {
            updateItemsWidthAndOriginXForSingleColumn()
        }
        else {
            updateItemsOriginXForMultipleColumns(updateItemWidth: true)
        }
    }
    
    private func fixCountOfItemsList() -> Bool {
        guard itemsInfo != nil else {
            prepareItemsFromScratch()
            return false
        }
        
        let heightState: ItemHeightState = (estimatedColumnType != nil) ? .estimated : .fixed
        
        let updatedItemsNumber = numberOfItemsInSection
        let oldItemsNumber = itemsInfo.count
        
        if oldItemsNumber > updatedItemsNumber {
            itemsInfo.removeSubrange(updatedItemsNumber ..< oldItemsNumber)
            return true
        }
        else if oldItemsNumber < updatedItemsNumber {
            itemsInfo! += [ItemInfo](repeating: ItemInfo(heightState: heightState), count: updatedItemsNumber-oldItemsNumber)
            return true
        }
        else { return false }
    }
    
    private func updateItemsList() {
        let oldItemSize = itemSize
        updateItemSizeAndNumberOfColumns()
        
        guard numberOfColumnsInRow != 0 else {
            assert(false, "Number of columns can't be 0")
            return
        }
        
        let didChangeItemWidth = oldItemSize.width != itemSize.width
        let didChangeItemHeight = oldItemSize.height != itemSize.height
        updateHeader()
        
        var lastOriginY = (headerInfo?.maxOriginY ?? 0) + sectionInsets.top
        
        if numberOfItemsInSection != 0 {
            if numberOfColumnsInRow == 1 {
                let originX = (collectionViewWidth - itemSize.width) * 0.5
                for index in 0..<numberOfItemsInSection {
                    itemsInfo[index].frame.origin = CGPoint(x: originX, y: lastOriginY)
                    itemsInfo[index].frame.size.width = itemSize.width
                    if didChangeItemHeight && itemsInfo[index].heightState != .computed {
                        itemsInfo[index].frame.size.height = itemSize.height
                    }
                    
                    if didChangeItemWidth && itemsInfo[index].heightState == .computed {
                        itemsInfo[index].heightState = .estimated
                    }
                    
                    lastOriginY += itemsInfo[index].frame.height + minimumLineSpacing
                }
            }
            else {
                var startItemIndex = 0
                while startItemIndex < numberOfItemsInSection {
                    let endItemIndex = min(startItemIndex + numberOfColumnsInRow - 1, numberOfItemsInSection - 1)
                    var lastOriginX = sectionInsets.left
                    var maxHeight: CGFloat = 0
                    for index in startItemIndex...endItemIndex {
                        if didChangeItemHeight && itemsInfo[index].heightState != .computed {
                            itemsInfo[index].frame.size.height = itemSize.height
                        }
                        
                        if didChangeItemWidth && itemsInfo[index].heightState == .computed {
                            itemsInfo[index].heightState = .estimated
                        }
                        
                        maxHeight = max(maxHeight, itemsInfo[index].frame.height)
                    }
                    
                    for index in startItemIndex...endItemIndex {
                        itemsInfo[index].frame.origin = CGPoint(x: lastOriginX, y: lastOriginY)
                        itemsInfo[index].frame.size.width = itemSize.width
                        
                        itemsInfo[index].rowHeight = maxHeight
                        lastOriginX += itemSize.width + actualInteritemSpacing
                    }
                    
                    startItemIndex = endItemIndex + 1
                    lastOriginY += maxHeight + minimumLineSpacing
                }
            }
            lastOriginY -= minimumLineSpacing
        }
        
        lastOriginY += sectionInsets.bottom
        updateFooter(originY: lastOriginY)
    }
}

//MARK: - Utils
private struct ItemInfo: CustomStringConvertible {
    var heightState: ItemHeightState
    var frame: CGRect
    var needInvalidation: Bool = false
    var rowHeight: CGFloat = 0
    
    init(heightState: ItemHeightState, frame: CGRect = .zero) {
        self.heightState = heightState
        self.frame = frame
        self.rowHeight = frame.height
    }
    
    var description: String {
        return "Item Info: State:\(heightState) ; Frame: \(frame)"
    }
}

private let kInvalidateForResetLayout = "reset"
private let kInvalidateForRowInfoChange = "RowInfo"
private let kInvalidateForColumnTypeChange = "ColumnType"
private let kInvalidateForMinimumLineSpacingChange = "MinimumLineSpacing"
private let kInvalidateForHeaderEstimatedHeightChange = "HeaderEstimatedHeight"
private let kInvalidateForFooterEstimatedHeightChange = "FooterEstimatedHeight"
private let kInvalidateHeaderForPreferredHeight = "PreferredHeaderHeight"
private let kInvalidateForRowAlignmentChange = "RowAlignment"
