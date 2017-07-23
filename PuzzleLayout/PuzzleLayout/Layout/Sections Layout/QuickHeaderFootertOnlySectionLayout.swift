//
//  HeaderFootertOnlySectionLayout.swift
//  PuzzleLayout
//
//  Created by Yossi Avramov on 13/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

/// A layout for showing only header and/or footer
public class QuickHeaderFootertOnlySectionLayout : QuickPuzzlePieceSectionLayout {
    //MARK: - Public
    
    /**
     Init a section layout which might present header and/or footer only
     
     - parameter headerHeight: The header height. Default, no header.
     
     - parameter footerHeight: The fotter height. Default, no footer.
     
     - parameter insets: The inset between the header and footer. If only one of them exit, the inset will be from the header/footer to the section bounds.
     
     - parameter showGutter: Should show a gutter view if inset > 0.
     */
    public init(headerHeight: HeadeFooterHeightSize = .none, footerHeight: HeadeFooterHeightSize = .none, insets: CGFloat = 0, showGutter: Bool = false) {
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
        self.insets = insets
        self.showGutter = showGutter
        super.init()
    }
    
    /**
     The default height type to use for section header. The default height is no header.
     
     Section header is positioned a section origin (0,0) in section coordinate system (Inset doesn't affect it).
     */
    public var headerHeight: HeadeFooterHeightSize = .none {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForHeaderHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateForHeaderHeightChange() }
        }
    }
    
    /**
     The default height type to use for section footer. The default height is no footer.
     
     Section footer is positioned a section origin (0,sectionHeight-footerHeight) in section coordinate system.
     */
    public var footerHeight: HeadeFooterHeightSize = .none {
        didSet {
            if let ctx = self.invalidationContext(with: kInvalidateForFooterHeightChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateForFooterHeightChange() }
        }
    }
    
    /// The inset between the header and footer. If only one of them exit, the inset will be from the header/footer to the section bounds.
    public var insets: CGFloat = 0 {
        didSet {
            if let ctx = invalidationContext(with: kInvalidateForInsetsChange) {
                parentLayout!.invalidateLayout(with: ctx)
            }
            else { updateFooterOriginY() }
        }
    }
    
    /// A Boolean value indicating whether should show a view on inset space. View will be presented only if inset > 0.
    public var showGutter: Bool = false {
        didSet {
            if insets != 0, let ctx = self.invalidationContext {
                ctx.invalidateSectionLayoutData = self
                ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSectionTopGutter, at: [indexPath(forIndex: 0)!])
                parentLayout!.invalidateLayout(with: ctx)
            }
        }
    }
    
    /// Reset the layout
    public func resetLayout() {
        if let ctx = self.invalidationContext(with: kInvalidateForResetLayout) {
            ctx.invalidateSectionLayoutData = self
            parentLayout!.invalidateLayout(with: ctx)
        }
    }
    
    //MARK: - Private properties
    
    /// The header info (current height & origin Y in section coordinate system)
    private var headerInfo: HeaderFooterInfo?
    
    /// The footer info (current height & origin Y in section coordinate system)
    private var footerInfo: HeaderFooterInfo?
    
    private var collectionViewWidth: CGFloat = 0
    
    //MARK: - PuzzlePieceSectionLayout
    override public var heightOfSection: CGFloat {
        var maxY: CGFloat = 0
        if let footer = footerInfo {
            maxY = footer.maxOriginY
        } else if let header = headerInfo {
            maxY = header.maxOriginY + insets
        }
        
        return maxY
    }
    
    override public func invalidate(for reason: InvalidationReason, with info: Any?) {
        super.invalidate(for: reason, with: info)
        
        if reason == .resetLayout || ((info as? String) == kInvalidateForResetLayout) {
            headerInfo = nil
            footerInfo = nil
        }
        
        if let invalidationStr = info as? String {
            switch invalidationStr {
            case kInvalidateForHeaderHeightChange:
                updateForHeaderHeightChange()
            case kInvalidateForFooterHeightChange:
                updateForFooterHeightChange()
            case kInvalidateHeaderForPreferredHeight:
                updateFooterOriginY()
            case kInvalidateForInsetsChange where footerInfo != nil && headerInfo != nil:
                updateFooterOriginY()
            default: break
            }
        }
    }
    
    override public func invalidateSupplementaryView(ofKind elementKind: String, at index: Int) {
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
                            
                            if let _ = footerInfo {
                                footerInfo!.originY = headerInfo!.height + insets
                            }
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
    
    override public func prepare(for reason: InvalidationReason, updates: [SectionUpdate]?) {
        super.prepare(for: reason, updates: updates)
        if footerInfo == nil && headerInfo == nil {
            preparFromScratch()
        }
        else if reason == .reloadData {
            fixHeaderFooter()
        }
        
        if collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            updateHeaderFooterWidth()
        }
    }
    
    override public func layoutItems(in rect: CGRect, sectionIndex: Int) -> [ItemKey] {
        var itemsInRect = [ItemKey]()
        
        if let headerInfo = headerInfo, headerInfo.intersects(with: rect) {
            itemsInRect.append(ItemKey(indexPath: IndexPath(item: 0, section: sectionIndex), kind: PuzzleCollectionElementKindSectionHeader, category: .supplementaryView))
        }
        
        if showGutter && (headerInfo != nil || footerInfo != nil) && insets != 0 {
            let topGutterFrame = CGRect(x: 0, y: (headerInfo?.height ?? 0), width: collectionViewWidth, height: insets)
            if rect.intersects(topGutterFrame) {
                itemsInRect.append(ItemKey(indexPath: IndexPath(item: 0, section: sectionIndex), kind: PuzzleCollectionElementKindSectionTopGutter, category: .decorationView))
            }
        }
        
        if let footerInfo = footerInfo, footerInfo.intersects(with: rect) {
            itemsInRect.append(ItemKey(indexPath: IndexPath(item: 0, section: sectionIndex), kind: PuzzleCollectionElementKindSectionFooter, category: .supplementaryView))
        }
        
        return itemsInRect
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
            if showGutter && (headerInfo != nil || footerInfo != nil) && insets != 0 {
                let originY: CGFloat = headerInfo?.maxOriginY ?? 0
                let gutterAttributes = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                gutterAttributes.frame = CGRect(x: 0, y: originY, width: collectionViewWidth, height: insets)
                if let gutterColor = separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                else if let gutterColor = parentLayout?.separatorLineColor {
                    gutterAttributes.info = [PuzzleCollectionColoredViewColorKey : gutterColor]
                }
                
                gutterAttributes.zIndex = PuzzleCollectionSeparatorsViewZIndex
                return gutterAttributes
            }
        }
        
        return nil
    }
    
    //PreferredAttributes Invalidation
    override public func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        var shouldInvalidate = false
        switch elementCategory {
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
    
    override public func shouldPinHeaderSupplementaryView() -> Bool {
        return false
    }
    
    override public func shouldPinFooterSupplementaryView() -> Bool {
        return false
    }
    
    // MARK: - Private
    private func preparFromScratch() {
        
        switch headerHeight {
        case .fixed(let height):
            headerInfo = HeaderFooterInfo(heightState: .fixed, originY: 0, height: height)
        case .estimated(let height):
            headerInfo = HeaderFooterInfo(heightState: .estimated, originY: 0, height: height)
        default: break
        }
        
        let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
        switch footerHeight {
        case .fixed(let height):
            footerInfo = HeaderFooterInfo(heightState: .fixed, originY: footerOriginY, height: height)
        case .estimated(let height):
            footerInfo = HeaderFooterInfo(heightState: .estimated, originY: footerOriginY, height: height)
        default: break
        }
    }
    
    private func fixHeaderFooter() {
        
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
                let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
                footerInfo = HeaderFooterInfo(heightState: .fixed, originY: footerOriginY, height: height)
            }
        case .estimated(let height):
            if let _ = footerInfo {
                if footerInfo!.heightState == .estimated {
                    footerInfo!.height = height
                }
            }
            else {
                let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
                footerInfo = HeaderFooterInfo(heightState: .estimated, originY: footerOriginY, height: height)
            }
        }
    }
    
    
    private func updateHeaderFooterWidth() {
        if let _ = headerInfo , headerInfo!.heightState == .computed {
            headerInfo!.heightState = .estimated
        }
        
        if let _ = footerInfo , footerInfo!.heightState == .computed {
            footerInfo!.heightState = .estimated
        }
    }
    
    private func updateFooterOriginY() {
        
        if let _ = footerInfo {
            //No need to make those computation if no footer
            let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
            footerInfo!.originY = footerOriginY
        }
    }
    
    private func updateForHeaderHeightChange() {
        
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
        
        if footerInfo != nil {
            let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
            footerInfo!.originY = footerOriginY
        }
    }
    
    private func updateForFooterHeightChange() {
        
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
                let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
                footerInfo = HeaderFooterInfo(heightState: .fixed, originY: footerOriginY, height: height)
            }
        case .estimated(let height):
            if let _ = footerInfo {
                if footerInfo!.heightState == .estimated {
                    footerInfo!.height = height
                }
            }
            else {
                let footerOriginY: CGFloat = (headerInfo?.height ?? 0) + insets
                footerInfo = HeaderFooterInfo(heightState: .estimated, originY: footerOriginY, height: height)
            }
        }
    }
}

private let kInvalidateForResetLayout = "Reset"
private let kInvalidateForHeaderHeightChange = "HeaderHeight"
private let kInvalidateForFooterHeightChange = "FooterHeight"
private let kInvalidateHeaderForPreferredHeight = "PreferredHeaderHeight"
private let kInvalidateForInsetsChange = "Insets"
