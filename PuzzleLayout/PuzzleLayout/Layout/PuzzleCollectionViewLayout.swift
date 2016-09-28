//
//  PuzzleCollectionViewLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 23/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

//MARK: - Layout subclasses
final public class PuzzleCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext {
    fileprivate var invalidationInfo: [Int:Any] = [:]
    public let invalidateSectionsLayout: Bool
    public let invalidateForWidthChange: Bool
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
    
    fileprivate init(invalidateForWidthChange: Bool, invalidationInfo: [Int:Any]) {
        self.invalidateSectionsLayout = false
        self.invalidateForWidthChange = invalidateForWidthChange
        self.invalidationInfo = invalidationInfo
        super.init()
    }
    
    fileprivate init(invalidationInfo: [Int:Any]) {
        self.invalidateSectionsLayout = false
        self.invalidateForWidthChange = false
        self.invalidationInfo = invalidationInfo
        super.init()
    }
}

final public class PuzzleCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes {
    var cachedSize: CGSize? = nil
    var info: Any? = nil
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let c = super.copy(with: zone)
        if let c = c as? PuzzleCollectionViewLayoutAttributes {
            c.cachedSize = self.cachedSize
            c.info = self.info
        }
        return c
    }
}

//MARK: - CollectionViewDataSourcePuzzleLayout
protocol CollectionViewDataSourcePuzzleLayout : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, collectionViewLayout layout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout
}

//MARK: - SectionPuzzleLayout extension
extension PuzzlePieceSectionLayout {
    var sectionWidth: CGFloat {
        if let collectionView = parentLayout?.collectionView {
            return collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        }
        else {
            return 0
        }
    }
    
    var traitCollection: UITraitCollection {
        return parentLayout?.collectionView?.traitCollection ?? UITraitCollection(traitsFrom: [UITraitCollection(horizontalSizeClass: .unspecified),UITraitCollection(verticalSizeClass: .unspecified)])
    }
    
    fileprivate func sectionIndex(for layout: PuzzlePieceSectionLayout) -> Int? {
        guard let parentLayout = parentLayout else {
            return nil
        }
        
        guard let sectionIndex = parentLayout.sectionsLayoutInfo.index(where: { (info:SectionInfo) -> Bool in
            return layout === info.layout
        }) else {
            print("Can't create invalidation context before layout was placed on 'PuzzleCollectionViewLayout'")
            return nil
        }
        
        return sectionIndex
    }
    
    func invalidationContext(with info: Any?, for layout: PuzzlePieceSectionLayout) -> PuzzleCollectionViewLayoutInvalidationContext? {
        guard let sectionIndex = sectionIndex(for: layout) else {
            return nil
        }
        
        return PuzzleCollectionViewLayoutInvalidationContext(invalidationInfo: [sectionIndex:info])
    }
    
    func invalidationContextForSeparatorLines(of layout: PuzzlePieceSectionLayout) -> PuzzleCollectionViewLayoutInvalidationContext? {
        guard let sectionIndex = sectionIndex(for: layout) else {
            return nil
        }
        
        let layoutInfo = parentLayout!.sectionsLayoutInfo[sectionIndex]
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.invalidateSectionLayoutData = layout
        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<layoutInfo.numberOfItemsInSection!))
        return ctx
    }
    
    func invalidationContextForTopGutter(of layout: PuzzlePieceSectionLayout) -> PuzzleCollectionViewLayoutInvalidationContext? {
        guard let sectionIndex = sectionIndex(for: layout) else {
            return nil
        }
        
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.invalidateSectionLayoutData = layout
        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSectionTopGutter, at: [IndexPath(item: 0, section: sectionIndex)])
        return ctx
    }
    
    func invalidationContextForBottomGutter(of layout: PuzzlePieceSectionLayout) -> PuzzleCollectionViewLayoutInvalidationContext? {
        guard let sectionIndex = sectionIndex(for: layout) else {
            return nil
        }
        
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.invalidateSectionLayoutData = layout
        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSectionBottomGutter, at: [IndexPath(item: 0, section: sectionIndex)])
        return ctx
    }
}






//MARK: - PuzzleCollectionViewLayout
private let PuzzleCollectionElementKindSeparatorLine = "!_SeparatorLine_!"
public let PuzzleCollectionElementKindSectionTopGutter = "!_SectionTopGutter_!"
public let PuzzleCollectionElementKindSectionBottomGutter = "!_SectionBottomGutter_!"
public let PuzzleCollectionColoredViewZIndex = 2
public let PuzzleCollectionColoredViewColorKey = "!_BackgroundColor_!"

public let PuzzleCollectionElementKindSectionHeader: String = UICollectionElementKindSectionHeader
public let PuzzleCollectionElementKindSectionFooter: String = UICollectionElementKindSectionFooter

final public class PuzzleCollectionViewLayout: UICollectionViewLayout {
    override public class var layoutAttributesClass : AnyClass {
        return PuzzleCollectionViewLayoutAttributes.self
    }
    
    override public class var invalidationContextClass : AnyClass {
        return PuzzleCollectionViewLayoutInvalidationContext.self
    }
    
    fileprivate var sectionsLayoutInfo: [SectionInfo] = []
    
    func sectionLayoutForIdentifier(_ identifier: String) -> PuzzlePieceSectionLayout? {
        return sectionsLayoutInfo.filter ({ (layoutInfo: SectionInfo) -> Bool in
            if let layoutIdentifier = layoutInfo.layout.identifier {
                return layoutIdentifier == identifier
            }
            else {
                return false
            }
        }).first?.layout
    }
    
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
    
    //MARK: - Override
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
        
        let invalidationInfo: [Int:Any]? = ctx.invalidationInfo
        for sectionInfo in sectionsLayoutInfo {
            let index = sectionInfo.sectionIndex!
            sectionInfo.layout.prepare(for: sectionInfo.numberOfItemsInSection!, withInvalidation: ctx, and: invalidationInfo?[index])
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
                        if item.representedElementCategory != .cell || layoutInfo.separatorLineType == .none || (layoutInfo.separatorLineType == .allButLastItem && item.indexPath.item + 1 == layoutInfo.numberOfItemsInSection!) {
                            //No separator line
                        }
                        else {
                            let separatorFrame = CGRect(x: item.frame.minX + layoutInfo.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layoutInfo.separatorLineInsets.left + layoutInfo.separatorLineInsets.right), height: 0.5)
                            if rect.intersects(separatorFrame) {
                                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: PuzzleCollectionElementKindSeparatorLine, with: item.indexPath)
                                separatorLine.frame = separatorFrame
                                separatorLine.zIndex = PuzzleCollectionColoredViewZIndex
                                separatorLine.info = [PuzzleCollectionColoredViewColorKey : layoutInfo.separatorLineColor]
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
            if layoutInfo.separatorLineType == .none || (layoutInfo.separatorLineType == .allButLastItem && indexPath.item + 1 == layoutInfo.numberOfItemsInSection!) {
                return nil
            }
            else if let item = layoutAttributesForItem(at: indexPath) {
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.frame = CGRect(x: item.frame.minX + layoutInfo.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layoutInfo.separatorLineInsets.left + layoutInfo.separatorLineInsets.right), height: 0.5)
                separatorLine.zIndex = PuzzleCollectionColoredViewZIndex
                separatorLine.info = [PuzzleCollectionColoredViewColorKey : layoutInfo.separatorLineColor]
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
        return layoutInfo.layout.shouldInvalidate(forPreferredAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
    }
    
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let ctx = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes) as! PuzzleCollectionViewLayoutInvalidationContext
        let sectionIndex = originalAttributes.indexPath.section
        let layoutInfo = sectionsLayoutInfo[sectionIndex]
        if let info = layoutInfo.layout.invalidationInfo(forPreferredAttributes: preferredAttributes, withOriginalAttributes: originalAttributes) {
            ctx.invalidationInfo[sectionIndex] = info
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
    
    //MARK: -
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
                    context.invalidationInfo[index] = info
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
                context.invalidationInfo[index] = info
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
    var numberOfItemsInSection: Int!
    
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

fileprivate extension IndexPath {
    static func indexPaths(for section: Int, itemsRange: CountableRange<Int>) -> [IndexPath] {
        return itemsRange.map({ item -> IndexPath in return IndexPath(item: item, section: section) })
    }
}
