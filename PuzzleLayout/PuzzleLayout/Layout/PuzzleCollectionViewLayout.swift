//
//  PuzzleCollectionViewLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 23/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

//MARK: - CollectionViewDataSourcePuzzleLayout
protocol CollectionViewDataSourcePuzzleLayout : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, collectionViewLayout layout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout
}

//MARK: - PuzzleCollectionViewLayout
final public class PuzzleCollectionViewLayout: UICollectionViewLayout {
    
    fileprivate var sectionsLayoutInfo: [SectionInfo] = []
    
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
    public func reloadSectionsLayout() {
        let context = PuzzleCollectionViewLayoutInvalidationContext(invalidateSectionsLayout: true)
        invalidateLayout(with: context)
    }
    
    func dequeueSectionLayout(for identifier: String) -> PuzzlePieceSectionLayout? {
        return sectionsLayoutInfo.filter ({ (layoutInfo: SectionInfo) -> Bool in
            if let layoutIdentifier = layoutInfo.layout.identifier {
                return layoutIdentifier == identifier
            }
            else {
                return false
            }
        }).first?.layout
    }
    
    public var separatorLineColor: UIColor? {
        didSet {
            let ctx = PuzzleCollectionViewLayoutInvalidationContext()
            for (sectionIndex, sectionInfo) in sectionsLayoutInfo.enumerated() {
                switch sectionInfo.separatorLineType {
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
            height += layoutInfo.layout.heightOfSection
        }
        
        return CGSize(width: collectionView!.bounds.width, height: height)
    }
    
    override public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        guard let ctx = (context as? PuzzleCollectionViewLayoutInvalidationContext) else {
            assert(false, "Invalidation context should be of type 'PuzzleCollectionViewLayoutInvalidationContext'")
            return
        }
        
        if ctx.invalidateEverything || ctx.invalidateDataSourceCounts || ctx.invalidateSectionsLayout {
            prepareSectionsLayout()
        }
        else if let layoutToInvalidate = ctx.invalidateSectionLayoutData {
            if let index = sectionsLayoutInfo.index(where: { (info:SectionInfo) -> Bool in
                return layoutToInvalidate === info.layout
            }) {
                sectionsLayoutInfo[index].updateSectionInfo()
            }
        }
        
        let invalidationInfo = ctx.invalidationInfo
        for sectionInfo in sectionsLayoutInfo {
            let index = sectionInfo.sectionIndex!
            //TODO: should update a section layout if none of ctx.invalidateEverything, ctx.invalidateDataSourceCounts, ctx.invalidateSectionsLayout is true & sectionInfo.numberOfItemsInSection hasn't change and no invalidationInfo[index] ?
            sectionInfo.layout.prepare(for: sectionInfo.numberOfItemsInSection, withInvalidation: ctx, and: invalidationInfo[index])
        }
        
        super.invalidateLayout(with: context)
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [PuzzleCollectionViewLayoutAttributes] = []
        var lastY: CGFloat = 0
        
        let width = collectionView!.bounds.width
        
        //Iterate over each section layout
        for sectionIndex in 0 ..< sectionsLayoutInfo.count {
            let layoutInfo = sectionsLayoutInfo[sectionIndex]
            assert(sectionIndex == layoutInfo.sectionIndex!, "Something went wrong. This shouldn't happen")
            let layout = layoutInfo.layout
            
            
            let sectionHeight = layout.heightOfSection
            let sectionFrame = CGRect(x: 0, y: lastY, width: width, height: sectionHeight)
            
            //Check if section intersects & get its elements layout attributes
            let intersection = rect.intersection(sectionFrame)
            
            if intersection.height > 0 { //Section intersects with rect
                let rectInSectionBounds = CGRect(origin: CGPoint(x: sectionFrame.minX, y: sectionFrame.minY - lastY), size: sectionFrame.size)
                
                //Ask for layout attributes depend the required data info required
                
                //Get items without specifying any information about section origin. Then update for each layout attributes its origin Y
                var items: [PuzzleCollectionViewLayoutAttributes]
                
                //"layoutAttributesForElements(atSection:in:) is required when 'dataRequiredForLayoutAttributes' == .none"
                items = layout.layoutAttributesForElements(in: rectInSectionBounds, sectionIndex: sectionIndex)
                if items.isEmpty == false {
                    //Update for each layout attributes its origin Y
                    for item in items {
                        item.center.y += lastY
                        attributes.append(item)
                        
                        //Add separator lines if needed
                        if item.representedElementCategory != .cell || layoutInfo.separatorLineType == .none || (layoutInfo.separatorLineType == .allButLastItem && item.indexPath.item + 1 == layoutInfo.numberOfItemsInSection) {
                            //No separator line
                        }
                        else {
                            let separatorFrame = CGRect(x: item.frame.minX + layoutInfo.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layoutInfo.separatorLineInsets.left + layoutInfo.separatorLineInsets.right), height: 0.5)
                            if rect.intersects(separatorFrame) {
                                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: PuzzleCollectionElementKindSeparatorLine, with: item.indexPath)
                                separatorLine.frame = separatorFrame
                                separatorLine.zIndex = PuzzleCollectionColoredViewZIndex
                                if let color = layoutInfo.separatorLineColor ?? separatorLineColor {
                                    separatorLine.info = [PuzzleCollectionColoredViewColorKey : color]
                                }
                                attributes.append(separatorLine)
                            }
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
        
        return attributes
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let layoutInfo = sectionsLayoutInfo[indexPath.section]
        let layout = layoutInfo.layout
        
        if let item = layout.layoutAttributesForItem(at: indexPath) {
            let lastY = self.lastY(forSectionAt: indexPath.section)
            item.center.y += lastY
            return item
        }
        else { return nil }
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let layoutInfo = sectionsLayoutInfo[indexPath.section]
        let layout = layoutInfo.layout
        
        if let item = layout.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) {
            let lastY = self.lastY(forSectionAt: indexPath.section)
            item.center.y += lastY
            return item
        }
        else { return nil }
    }
    
    public override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == PuzzleCollectionElementKindSeparatorLine {
            let layoutInfo = sectionsLayoutInfo[indexPath.section]
            if layoutInfo.separatorLineType == .none || (layoutInfo.separatorLineType == .allButLastItem && indexPath.item + 1 == layoutInfo.numberOfItemsInSection) {
                return nil
            }
            else if let item = layoutAttributesForItem(at: indexPath) {
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.frame = CGRect(x: item.frame.minX + layoutInfo.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layoutInfo.separatorLineInsets.left + layoutInfo.separatorLineInsets.right), height: 0.5)
                separatorLine.zIndex = PuzzleCollectionColoredViewZIndex
                if let color = layoutInfo.separatorLineColor ?? separatorLineColor {
                    separatorLine.info = [PuzzleCollectionColoredViewColorKey : color]
                }
                return separatorLine
            }
            else { return nil }
        }
        else {
            let layoutInfo = sectionsLayoutInfo[indexPath.section]
            let layout = layoutInfo.layout
            
            if let item = layout.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath) {
                let lastY = self.lastY(forSectionAt: indexPath.section)
                item.center.y += lastY
                return item
            }
            else { return nil }
        }
    }
    
    private var invalidationInfoForBoundsChange: InvalidationInfoForBoundsChange?
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
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
            for sectionInfo in sectionsLayoutInfo {
                let layout = sectionInfo.layout
                guard layout.mayRequireInvalidationOnOriginChange() else {
                    continue
                }
                
                let sectionHeight = layout.heightOfSection
                
                let oldSectionFrame = CGRect(x: 0, y: lastY, width: oldWidth, height: sectionHeight)
                let newSectionFrame = CGRect(x: 0, y: lastY, width: newWidth, height: sectionHeight)
                
                //Check if section intersects & get its elements layout attributes
                let oldFrameIntersection = oldSectionFrame.intersection(oldBounds)
                let newFrameIntersection = newSectionFrame.intersection(newBounds)
                
                
                if oldFrameIntersection.height > 0 || newFrameIntersection.height > 0 {
                    let oldSectionBounds = CGRect(origin: CGPoint(x: oldFrameIntersection.minX, y: oldFrameIntersection.minY - lastY), size: oldFrameIntersection.size)
                    let newSectionBounds = CGRect(origin: CGPoint(x: newFrameIntersection.minX, y: newFrameIntersection.minY - lastY), size: newFrameIntersection.size)
                    if layout.shouldInvalidate(forNewBounds: newSectionBounds, currentBounds: oldSectionBounds) {
                        let index = sectionInfo.sectionIndex!
                        invalidationInfo.sectionsIndex.append(index)
                        invalidationInfo.sectionsNewBounds[index] = newSectionBounds
                        invalidationInfo.sectionsOldBounds[index] = oldSectionBounds
                    }
                }
                else if oldFrameIntersection.minY >= oldBounds.maxY && newFrameIntersection.minY >= newBounds.maxY { //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                    break
                }
//                else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//                }
                
                lastY += sectionHeight
            }
            
            if invalidationInfo.sectionsIndex.isEmpty {
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
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        
        let oldBounds = collectionView!.bounds
        let context = super.invalidationContext(forBoundsChange: newBounds) as! PuzzleCollectionViewLayoutInvalidationContext
        if newBounds.width != oldBounds.width {
            invalidateForWidthChange(byBoundsChange: newBounds, oldBounds: oldBounds, with: context)
        }
        else if newBounds.minY != oldBounds.minY, let _ = invalidationInfoForBoundsChange {
            invalidateForOriginYChange(with: context)
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
        let layoutInfo = sectionsLayoutInfo[originalAttributes.indexPath.section]
        let invalidationType: InvalidationElementCategory
        switch preferredAttributes.representedElementCategory {
        case .cell:
            invalidationType = .cell(indexPath: originalAttributes.indexPath)
        case .supplementaryView:
            invalidationType = .supplementaryView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        case .decorationView:
            invalidationType = .decorationView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        }
        
        if layoutInfo.layout.shouldInvalidate(for: invalidationType, forPreferredSize: &preferredAttributes.size, withOriginalSize: originalAttributes.size) {
            preferredAttributes.frame.origin.y = originalAttributes.frame.origin.y
            return true
        }
        else { return false }
    }
    
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let ctx = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes) as! PuzzleCollectionViewLayoutInvalidationContext
        if ctx.contentOffsetAdjustment.y != 0 {
            DebugLog("Invalidate \(ctx.contentOffsetAdjustment) ; Preferred: \(preferredAttributes.size) ; Original: \(originalAttributes.size) ; Rect: \(collectionView!.bounds) ; \(originalAttributes.frame)")
        }
        
        let sectionIndex = originalAttributes.indexPath.section
        let layoutInfo = sectionsLayoutInfo[sectionIndex]
        
        let invalidationType: InvalidationElementCategory
        switch preferredAttributes.representedElementCategory {
        case .cell:
            invalidationType = .cell(indexPath: originalAttributes.indexPath)
        case .supplementaryView:
            invalidationType = .supplementaryView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        case .decorationView:
            invalidationType = .decorationView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        }
        
        (preferredAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize = preferredAttributes.size
        if let info = layoutInfo.layout.invalidationInfo(for: invalidationType, forPreferredSize: preferredAttributes.size, withOriginalSize: originalAttributes.size) {
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
        
        let numberOfSections = dataSource.numberOfSections?(in: collectionView!) ?? 1
        if numberOfSections > 0 {
            var newLayouts: [SectionInfo] = [SectionInfo](repeating: SectionInfo(), count: numberOfSections)
            for layoutInfo in sectionsLayoutInfo {
                layoutInfo.layout.parentLayout = nil
            }
            
            for sectionIndex in 0 ..< numberOfSections {
                let numberOfItems = dataSource.collectionView(collectionView!, numberOfItemsInSection: sectionIndex)
                let layout = dataSource.collectionView(collectionView!, collectionViewLayout: self, layoutForSectionAtIndex: sectionIndex)
                
                var info = SectionInfo(layout: layout, parentLayout: self)
                info.update(withSectionIndex: sectionIndex, numberOfItemsInSection: numberOfItems)
                newLayouts[sectionIndex] = info
            }
            
            sectionsLayoutInfo = newLayouts
        }
        else {
            let sectionsInfo = sectionsLayoutInfo
            sectionsLayoutInfo = []
            
            for layoutInfo in sectionsInfo {
                layoutInfo.layout.parentLayout = nil
            }
        }
    }
    
    //MARK: - Private
    private func lastY(forSectionAt index: Int) -> CGFloat {
        if index == 0 {
            return 0
        }
        else {
            var lastY: CGFloat = 0
            for currentIndex in 0...(index-1) {
                let layoutInfo = sectionsLayoutInfo[currentIndex]
                lastY += layoutInfo.layout.heightOfSection
            }
            return lastY
        }
    }
    
    private func heightOfPrecedeSections(toSectionAt index: Int) -> CGFloat {
        if index == 0 {
            return 0
        }
        else {
            var height: CGFloat = 0
            for currentIndex in 0...(index-1) {
                let layoutInfo = sectionsLayoutInfo[currentIndex]
                height += layoutInfo.layout.heightOfSection
            }
            return height
        }
    }
    
    private func invalidateForWidthChange(byBoundsChange newBounds: CGRect, oldBounds: CGRect, with context: PuzzleCollectionViewLayoutInvalidationContext) {
        context.invalidateForWidthChange = true
        var lastY: CGFloat = 0
        for sectionInfo in sectionsLayoutInfo {
            let layout = sectionInfo.layout
            let sectionHeight = layout.heightOfSection
            
            let oldSectionFrame = CGRect(x: 0, y: lastY, width: oldBounds.width, height: sectionHeight)
            let newSectionFrame = CGRect(x: 0, y: lastY, width: newBounds.width, height: sectionHeight)
            
            //Check if section intersects & get its elements layout attributes
            let oldFrameIntersection = oldSectionFrame.intersection(oldBounds)
            let newFrameIntersection = newSectionFrame.intersection(newBounds)
            
            
            if oldFrameIntersection.height > 0 || newFrameIntersection.height > 0 {
                let oldSectionBounds = CGRect(origin: CGPoint(x: oldFrameIntersection.minX, y: oldFrameIntersection.minY - lastY), size: oldFrameIntersection.size)
                let newSectionBounds = CGRect(origin: CGPoint(x: newFrameIntersection.minX, y: newFrameIntersection.minY - lastY), size: newFrameIntersection.size)
                if let info = layout.invalidationInfo(forNewBounds: newSectionBounds, currentBounds: oldSectionBounds) {
                    let index = sectionInfo.sectionIndex!
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
    
    private func invalidateForOriginYChange(with context: PuzzleCollectionViewLayoutInvalidationContext) {
        let invalidationInfo = invalidationInfoForBoundsChange!
        for index in invalidationInfo.sectionsIndex {
            let layout = sectionsLayoutInfo[index].layout
            let oldSectionBounds = invalidationInfo.sectionsOldBounds[index]!
            let newSectionBounds = invalidationInfo.sectionsNewBounds[index]!
            if let info = layout.invalidationInfo(forNewBounds: newSectionBounds, currentBounds: oldSectionBounds) {
                context.setInvalidationInfo(info, forSectionAtIndex: index)
            }
        }
    }
}

//MARK: - Private Util
fileprivate struct SectionInfo  {
    private let _layout: PuzzlePieceSectionLayout!
    var layout: PuzzlePieceSectionLayout {
        return _layout!
    }
    
    var separatorLineType: PuzzlePieceSeparatorLineStyle = .none
    var separatorLineInsets: UIEdgeInsets = .zero
    var separatorLineColor: UIColor?
    
    var sectionIndex: Int!
    var numberOfItemsInSection: Int = 0
    
    init(layout: PuzzlePieceSectionLayout, parentLayout: PuzzleCollectionViewLayout) {
        _layout = layout
        layout.parentLayout = parentLayout
    }
    
    init() {
        _layout = nil
    }
    
    mutating func update(withSectionIndex sectionIndex: Int, numberOfItemsInSection: Int) {
        self.sectionIndex = sectionIndex
        self.numberOfItemsInSection = numberOfItemsInSection
        updateSectionInfo()
    }
    
    mutating func updateSectionInfo() {
        self.separatorLineType = layout.separatorLineStyle
        self.separatorLineColor = layout.separatorLineColor
        if self.separatorLineType == .none {
            self.separatorLineInsets = .zero
        }
        else {
            self.separatorLineInsets = layout.separatorLineInsets
        }
    }
    
    var isNull: Bool {
        return (_layout == nil)
    }
}

fileprivate struct InvalidationInfoForBoundsChange {
    var sectionsIndex: [Int] = []
    var sectionsOldBounds: [Int:CGRect] = [:]
    var sectionsNewBounds: [Int:CGRect] = [:]
}

fileprivate class ColoredDecorationView : UICollectionReusableView {
    fileprivate override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        let dict = (layoutAttributes as! PuzzleCollectionViewLayoutAttributes).info as? [AnyHashable:Any]
        backgroundColor = dict?[PuzzleCollectionColoredViewColorKey] as? UIColor ?? UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1)
    }
}


//MARK: - SectionPuzzleLayout extension
extension PuzzlePieceSectionLayout {
    public var sectionWidth: CGFloat {
        if let collectionView = parentLayout?.collectionView {
            return collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
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
    
    fileprivate var sectionIndex: Int? {
        guard let parentLayout = parentLayout else {
            return nil
        }
        
        guard let sectionIndex = parentLayout.sectionsLayoutInfo.index(where: { (info:SectionInfo) -> Bool in
            return self === info.layout
        }) else {
            print("Can't create invalidation context before layout was placed on 'PuzzleCollectionViewLayout'")
            return nil
        }
        
        return sectionIndex
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
    
    public func invalidationContextForSeparatorLines(for newStyle: PuzzlePieceSeparatorLineStyle, oldStyle: PuzzlePieceSeparatorLineStyle? = nil) -> PuzzleCollectionViewLayoutInvalidationContext? {
        let _oldStyle = oldStyle ?? newStyle
        if newStyle == _oldStyle && newStyle == .none {
            return nil
        }
        
        guard let sectionIndex = sectionIndex else {
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
