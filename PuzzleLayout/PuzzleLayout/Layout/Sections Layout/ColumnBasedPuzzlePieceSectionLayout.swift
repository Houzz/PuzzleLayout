//
//  ColumnBasedPuzzlePieceSectionLayout.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 05/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

public typealias DynamicItemSize = ((_ traitCollection: UITraitCollection, _ width: CGFloat) -> CGSize)
public typealias DynamicNumberOfColumns = ((_ traitCollection: UITraitCollection, _ width: CGFloat) -> (count: UInt, itemHeight: CGFloat))

public enum ColumnType {
    case itemSize(size: CGSize)
    case dynamicItemSize(closure: DynamicItemSize)
    case numberOfColumns(count: UInt, itemHeight: CGFloat)
    case dynamicNumberOfColumns(closure: DynamicNumberOfColumns)
}

public enum RowAlignmentOnItemSelfSizing {
    case RowItemsEqualHeight
    case RowItemsAlignCenter
    case RowItemsAlignTop
    case RowItemsAlignBottom
}

public class ColumnBasedPuzzlePieceSectionLayout: PuzzlePieceSectionLayout {
    public var sectionInsets = UIEdgeInsets.zero {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateRequiredFixItemsList) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                fixItemsList()
            }
        }
    }

    public var minimumInteritemSpacing: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateRequiredFixItemsList) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                fixItemsList()
            }
        }
    }

    public var minimumLineSpacing: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateRequiredFixItemsList) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                fixItemsList()
            }
        }
    }

    public private(set) var columnType: ColumnType? = .itemSize(size: CGSize(width: 50, height: 50))
    public private(set) var estimatedColumnType: ColumnType? = nil
    public func setColumnType(_ type: ColumnType) {
        estimatedColumnType = nil
        columnType = type
        if let ctx = self.invalidationContext(with: kInvalidateRequiredFixItemsList) {
            parentLayout!.invalidateLayout(with: ctx)
        }
        else {
            fixItemsList()
        }
    }
    
    public func setEstimatedColumnType(_ type: ColumnType) {
        columnType = nil
        estimatedColumnType = type
        if let ctx = self.invalidationContext(with: kInvalidateRequiredFixItemsList) {
            parentLayout!.invalidateLayout(with: ctx)
        }
        else {
            fixItemsList()
        }
    }
    
    public var estimatedHeaderHeight: CGFloat = kEstimatedHeaderFooterHeightNone {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForHeaderEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateItemsForEstimatedHeaderHeight(forceUpdate: false)
            }
        }
    }
    
    public var estimatedFooterHeight: CGFloat = kEstimatedHeaderFooterHeightNone {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForFooterEstimatedHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else {
                updateFooterForEstimatedFooterHeight()
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
    
    //MARK: - Init
    init(columnType: ColumnType?, sectionInsets: UIEdgeInsets = .zero, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0,
         estimatedHeaderHeight: CGFloat = kEstimatedHeaderFooterHeightNone, estimatedFooterHeight: CGFloat = kEstimatedHeaderFooterHeightNone,
         separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem, showTopGutter: Bool = false, showBottomGutter: Bool = false) {
        self.columnType = columnType
        self.sectionInsets = sectionInsets
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.estimatedHeaderHeight = estimatedHeaderHeight
        self.estimatedFooterHeight = estimatedFooterHeight
        self.showTopGutter = showTopGutter
        self.showBottomGutter = showBottomGutter
        super.init()
        self.separatorLineStyle = separatorLineStyle
    }
    
    init(estimatedColumnType: ColumnType?, sectionInsets: UIEdgeInsets = .zero, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0,
         estimatedHeaderHeight: CGFloat = kEstimatedHeaderFooterHeightNone, estimatedFooterHeight: CGFloat = kEstimatedHeaderFooterHeightNone,
         separatorLineStyle: PuzzlePieceSeparatorLineStyle = .allButLastItem, showTopGutter: Bool = false, showBottomGutter: Bool = false) {
        self.estimatedColumnType = estimatedColumnType
        self.sectionInsets = sectionInsets
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.estimatedHeaderHeight = estimatedHeaderHeight
        self.estimatedFooterHeight = estimatedFooterHeight
        self.showTopGutter = showTopGutter
        self.showBottomGutter = showBottomGutter
        super.init()
        self.separatorLineStyle = separatorLineStyle
    }
    
    //MARK: - PuzzlePieceSectionLayout
    public override var heightOfSection: CGFloat {
        var maxY: CGFloat = 0
        if let footer = footerInfo {
            maxY = footer.frame.maxY
        } else if let lastItem = itemsInfo.last {
            let frame = rowFrame(for: lastItem)
            assert(frame.isNull == false, "Frame can't be null")
            maxY = frame.maxY + sectionInsets.bottom
        } else if let header = headerInfo {
            maxY = header.frame.maxY + sectionInsets.bottom
        }
        
        return maxY
    }
    
    public override func prepare(with context: PuzzleCollectionViewLayoutInvalidationContext, and info: Any?) {
        
        if (info as? String) == kInvalidateForResetLayout {
            itemsInfo = nil
            headerInfo = nil
            footerInfo = nil
        }
        
        if itemsInfo == nil {
            collectionViewWidth = sectionWidth
            prepareItemsFromScratch()
        }
        else if context.invalidateEverything || context.invalidateDataSourceCounts || context.invalidateForWidthChange || collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            fixItemsList()
        }
        else if let invalidationStr = info as? String {
            switch invalidationStr {
            case kInvalidateRequiredFixItemsList:
                fixItemsList()
            case kInvalidateForHeaderEstimatedHeightChange:
                updateItemsForEstimatedHeaderHeight(forceUpdate: false)
            case kInvalidateHeaderForPreferredHeight:
                updateItemsForEstimatedHeaderHeight(forceUpdate: true)
            default: break
            }
        }
//        else if let itemIndexPath = info as? IndexPath {
//            updateRows(forIndexPath: itemIndexPath)
//        }
    }
    
    //MARK: - Private properties
    private var itemsInfo: [ItemInfo]!
    private var headerInfo: ItemInfo?
    private var footerInfo: ItemInfo?
    private var numberOfItemsInColumn: Int = 1
    private var itemSize: CGSize = .zero
    private var actualInteritemSpacing: CGFloat = 0
    
    private var collectionViewWidth: CGFloat = 0
    
    //MARK: - Private 
    private func rowFrame(for item: ItemInfo) -> CGRect {
        guard item.rowIndex != -1 && item.itemIndexInRow != -1 else {
            return .null
        }
        
        let startItemIndexAtRow = numberOfItemsInColumn * item.rowIndex
        let endItemIndexAtRow = min(numberOfItemsInSection-1, startItemIndexAtRow+numberOfItemsInColumn-1)
        var maxHeight = item.frame.height
        for index in startItemIndexAtRow...endItemIndexAtRow {
            let currentItem = itemsInfo[index]
            maxHeight = max(maxHeight, currentItem.frame.height)
        }
        
        return CGRect(x: 0, y: item.frame.minY, width: collectionViewWidth, height: maxHeight)
    }
    
    private func computeNumberOfColumnsFromItemSize() {
        let contentWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        numberOfItemsInColumn = Int(floor((contentWidth + minimumInteritemSpacing) / (itemSize.width + minimumInteritemSpacing)))
    }
    
    private func computeItemSizeFromNumberOfColumns() {
        let contentWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        var itemWidth = (contentWidth - (minimumInteritemSpacing * (CGFloat(numberOfItemsInColumn - 1))))
        itemWidth /= CGFloat(numberOfItemsInColumn)
        self.itemSize.width = floor(itemWidth * 2) * 0.5 //Floor to nearest half
    }
    
    private func updateItemSizeAndNumberOfColumns() {
        assert(estimatedColumnType != nil || columnType != nil, "'estimatedColumnType' and 'columnType' can't be both nil")
        let type = (estimatedColumnType ?? columnType)!
        switch type {
        case .itemSize(let size):
            self.itemSize = size
            computeNumberOfColumnsFromItemSize()
        case .dynamicItemSize(let closure):
            self.itemSize = closure(traitCollection, collectionViewWidth)
            computeNumberOfColumnsFromItemSize()
        case .numberOfColumns(let count, let height):
            self.itemSize = CGSize(width: 0, height: height)
            self.numberOfItemsInColumn = Int(count)
            computeItemSizeFromNumberOfColumns()
        case .dynamicNumberOfColumns(let closure):
            let res = closure(traitCollection, collectionViewWidth)
            self.itemSize = CGSize(width: 0, height: res.itemHeight)
            self.numberOfItemsInColumn = Int(res.count)
            computeItemSizeFromNumberOfColumns()
        }
        
        let contentWidth = collectionViewWidth - (sectionInsets.left + sectionInsets.right)
        actualInteritemSpacing = floor((contentWidth - (CGFloat(numberOfItemsInColumn) * (itemSize.width))) / CGFloat(numberOfItemsInColumn-1) * 2) * 0.5
    }
    
    private func prepareItemsFromScratch() {
        updateItemSizeAndNumberOfColumns()
        let heightState: ItemHeightState = (estimatedColumnType != nil) ? .estimated : .fixed
        var lastOriginY: CGFloat = 0
        
        itemsInfo = [ItemInfo](repeating: ItemInfo(heightState: heightState), count: numberOfItemsInSection)
        
        if estimatedHeaderHeight != kEstimatedHeaderFooterHeightNone {
            headerInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedHeaderHeight))
            lastOriginY += estimatedHeaderHeight
        }
        
        if numberOfItemsInSection != 0 {
            
            lastOriginY += sectionInsets.top
            if numberOfItemsInColumn == 1 {
                let originX = (collectionViewWidth - itemSize.width) * 0.5
                for index in 0..<numberOfItemsInSection {
                    itemsInfo[index] = ItemInfo(heightState: heightState, frame: CGRect(origin: CGPoint(x: originX, y: lastOriginY), size: itemSize))
                    itemsInfo[index].itemIndexInRow = 0
                    itemsInfo[index].rowIndex = index
                    
                    lastOriginY += itemSize.height + minimumLineSpacing
                }
            }
            else {
                var startItemIndex = 0
                var rowIndex = 0
                while startItemIndex < numberOfItemsInSection {
                    let endItemIndex = min(startItemIndex + numberOfItemsInColumn - 1, numberOfItemsInSection - 1)
                    var lastOriginX = sectionInsets.left
                    for index in startItemIndex...endItemIndex {
                        itemsInfo[index] = ItemInfo(heightState: heightState, frame: CGRect(origin: CGPoint(x: lastOriginX, y: lastOriginY), size: itemSize))
                        itemsInfo[index].itemIndexInRow = index - startItemIndex
                        itemsInfo[index].rowIndex = rowIndex
                        lastOriginX += itemSize.width + actualInteritemSpacing
                    }
                    
                    startItemIndex = endItemIndex + 1
                    lastOriginY += itemSize.height + minimumLineSpacing
                    rowIndex += 1
                }
            }
            lastOriginY -= minimumLineSpacing
            lastOriginY += sectionInsets.bottom
        }
        
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            footerInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedFooterHeight))
            lastOriginY += estimatedFooterHeight
        }
    }
    
    private func fixItemsList() {
        guard itemsInfo != nil else {
            prepareItemsFromScratch()
            return
        }
        
        updateItemSizeAndNumberOfColumns()
        
        let heightState: ItemHeightState = (estimatedColumnType != nil) ? .estimated : .fixed
        var lastOriginY: CGFloat = 0
        
        let updatedItemsNumber = numberOfItemsInSection
        let oldItemsNumber = itemsInfo.count
        
        // Update section header if needed
        if estimatedHeaderHeight != kEstimatedHeaderFooterHeightNone {
            if headerInfo == nil {
                headerInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedHeaderHeight))
            }
            else if headerInfo!.heightState != .computed {
                headerInfo!.frame.size.height = estimatedHeaderHeight
            }
            
            lastOriginY += headerInfo!.frame.height
        }
        else if headerInfo != nil {
            headerInfo = nil
        }
        
        lastOriginY += sectionInsets.top
        
        if oldItemsNumber > updatedItemsNumber {
            itemsInfo.removeSubrange(updatedItemsNumber ..< oldItemsNumber)
        }
        else if oldItemsNumber < updatedItemsNumber {
            itemsInfo! += [ItemInfo](repeating: ItemInfo(heightState: heightState), count: updatedItemsNumber-oldItemsNumber)
        }
        
        if itemsInfo.isEmpty == false {
            lastOriginY += sectionInsets.top
            if numberOfItemsInColumn == 1 {
                let originX = (collectionViewWidth - itemSize.width) * 0.5
                for index in 0..<numberOfItemsInSection {
                    switch heightState {
                    case .fixed:
                        itemsInfo[index].frame = CGRect(origin: CGPoint(x: originX, y: lastOriginY), size: itemSize)
                    case .estimated:
                        if itemsInfo[index].heightState == .computed {
                            itemsInfo[index].frame = CGRect(x: originX, y: lastOriginY, width: itemSize.width, height: itemsInfo[index].frame.size.height)
                        }
                        else {
                            itemsInfo[index].frame = CGRect(origin: CGPoint(x: originX, y: lastOriginY), size: itemSize)
                        }
                    default: break
                    }
                    
                    itemsInfo[index].heightState = heightState
                    itemsInfo[index].itemIndexInRow = 0
                    itemsInfo[index].rowIndex = index
                    
                    lastOriginY += itemsInfo[index].frame.height + minimumLineSpacing
                }
            }
            else {
                var startItemIndex = 0
                var rowIndex = 0
                while startItemIndex < numberOfItemsInSection {
                    let endItemIndex = min(startItemIndex + numberOfItemsInColumn - 1, numberOfItemsInSection - 1)
                    var lastOriginX = sectionInsets.left
                    
                    var maxHeight: CGFloat = 0
                    for index in startItemIndex...endItemIndex {
                        switch heightState {
                        case .fixed:
                            itemsInfo[index].frame = CGRect(origin: CGPoint(x: lastOriginX, y: lastOriginY), size: itemSize)
                        case .estimated:
                            if itemsInfo[index].heightState == .computed {
                                itemsInfo[index].frame = CGRect(x: lastOriginX, y: lastOriginY, width: itemSize.width, height: itemsInfo[index].frame.size.height)
                            }
                            else {
                                itemsInfo[index].frame = CGRect(origin: CGPoint(x: lastOriginX, y: lastOriginY), size: itemSize)
                            }
                        default: break
                        }
                        
                        itemsInfo[index].heightState = heightState
                        itemsInfo[index].itemIndexInRow = index - startItemIndex
                        itemsInfo[index].rowIndex = rowIndex
                        maxHeight = max(maxHeight, itemsInfo[index].frame.size.height)
                        lastOriginX += itemSize.width + actualInteritemSpacing
                    }
                    
                    startItemIndex = endItemIndex + 1
                    lastOriginY += maxHeight + minimumLineSpacing
                    rowIndex += 1
                }
            }
            
            lastOriginY -= minimumLineSpacing
            lastOriginY += sectionInsets.bottom
        }
        
        // Update section footer if needed
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            if footerInfo == nil {
                footerInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: 0, y: lastOriginY, width: collectionViewWidth, height: estimatedFooterHeight))
            }
            else if footerInfo!.heightState != .computed {
                footerInfo!.frame.size.height = estimatedFooterHeight
            }
            
            footerInfo!.frame.origin.y = lastOriginY
            lastOriginY += footerInfo!.frame.height
        }
        else if footerInfo != nil {
            footerInfo = nil
        }
    }
    
    private func updateItemsForEstimatedHeaderHeight(forceUpdate: Bool) {
        var lastOriginY: CGFloat = 0
        
        var didUpdateHeader = forceUpdate
        // Update section header if needed
        if estimatedHeaderHeight != kEstimatedHeaderFooterHeightNone {
            if headerInfo!.heightState != .computed {
                headerInfo!.frame.size.height = estimatedHeaderHeight
                lastOriginY += headerInfo!.frame.height
                didUpdateHeader = true
            }
        }
        else if headerInfo != nil {
            headerInfo = nil
            didUpdateHeader = true
        }
        
        guard didUpdateHeader else {
            //There's no update. No need to update origin Y of items & footer
            return
        }
        
        lastOriginY += sectionInsets.top
        
        if itemsInfo.isEmpty == false {
            lastOriginY += sectionInsets.top
            if numberOfItemsInColumn == 1 {
                for index in 0..<numberOfItemsInSection {
                    itemsInfo[index].frame.origin.y = lastOriginY
                    lastOriginY += itemsInfo[index].frame.height + minimumLineSpacing
                }
            }
            else {
                var startItemIndex = 0
                while startItemIndex < numberOfItemsInSection {
                    let endItemIndex = min(startItemIndex + numberOfItemsInColumn - 1, numberOfItemsInSection - 1)
                    
                    var maxHeight: CGFloat = 0
                    for index in startItemIndex...endItemIndex {
                        itemsInfo[index].frame.origin.y = lastOriginY
                        maxHeight = max(maxHeight, itemsInfo[index].frame.size.height)
                    }
                    
                    startItemIndex = endItemIndex + 1
                    lastOriginY += maxHeight + minimumLineSpacing
                }
            }
            
            if footerInfo != nil {
                //No need to make those computation if there's no footer
                lastOriginY -= minimumLineSpacing
                lastOriginY += sectionInsets.bottom
            }
        }
        
        footerInfo?.frame.origin.y = lastOriginY
    }
    
    func updateFooterForEstimatedFooterHeight() {
        if estimatedFooterHeight != kEstimatedHeaderFooterHeightNone {
            if footerInfo!.heightState != .computed {
                footerInfo!.frame.size.height = estimatedFooterHeight
            }
        }
        else if footerInfo != nil {
            footerInfo = nil
        }
    }
}

fileprivate enum ItemHeightState : Int, CustomStringConvertible {
    case fixed
    case estimated
    case computed
    
    var description: String {
        switch self {
        case .fixed: return "Fixed height"
        case .estimated: return "Estimated height"
        case .computed: return "Computed height"
        }
    }
}

fileprivate struct ItemInfo: CustomStringConvertible {
    var heightState: ItemHeightState
    var frame: CGRect
    var itemIndexInRow: Int = -1
    var rowIndex: Int = -1
    var needInvalidation: Bool = false
    var rowHeight: CGFloat = 0
    
    init(heightState: ItemHeightState, frame: CGRect = .zero) {
        self.heightState = heightState
        self.frame = frame
    }
    
    var description: String {
        return "Item Info: Row index: \(rowIndex) ; Item index in row: \(itemIndexInRow) ; State:\(heightState) ; Frame: \(frame)"
    }
}

private let kInvalidateForResetLayout = "reset"
private let kInvalidateRequiredFixItemsList = "fixItemsList"
private let kInvalidateForHeaderEstimatedHeightChange = "HeaderEstimatedHeight"
private let kInvalidateForFooterEstimatedHeightChange = "FooterEstimatedHeight"
private let kInvalidateHeaderForPreferredHeight = "Invalidate_Header"
