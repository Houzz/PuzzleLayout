//
//  ProProfileHeaderDataSource.swift
//  PuzzleExample
//
//  Created by Yossi Avramov on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

private enum Item : Int {
    case profileImage
    case name
    case category
    case reviews
    
    static var max: Int {
        return reviews.rawValue + 1
    }
}

class ProProfileHeaderDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Item.max
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Item(rawValue: indexPath.item)! {
        case .profileImage:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
            cell.imgView.setImage(forURL: User.currentPro.profileImageUrl)
            cell.contentView.borderColor = .white
            cell.contentView.borderWidth = 1
            cell.contentView.clipsToBounds = true
            return cell
        case .name:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
            cell.lbl.text = "Houzz - NEW WAY TO DESIGN YOUR HOME"
            cell.lbl.textColor = .white
            cell.lbl.font = UIFont.mediumSystemFont(ofSize: 14)
            cell.contentView.backgroundColor = .clear
            return cell
        case .category:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
            cell.lbl.text = "Platform for home remodeling and design"
            cell.lbl.textColor = .white
            cell.lbl.font = UIFont.mediumSystemFont(ofSize: 14)
            cell.contentView.backgroundColor = .clear
            return cell
        case .reviews:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReviewStarsCell.identifier, for: indexPath) as! ReviewStarsCell
            cell.update(withStars: 5, halfStar: false)
            cell.numberOfReviewsLabel.text = "15"
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return HeaderLayout()
    }
}







//MARK: - Layout
fileprivate class HeaderLayout: PuzzlePieceSectionLayout {
    
    override var parentLayout: PuzzleCollectionViewLayout? {
        didSet {
            if let parentLayout = parentLayout {
                parentLayout.register(HeaderBackground.self, forDecorationViewOfKind: HeaderBackground.elementKind)
            }
        }
    }
    
    override var heightOfSection: CGFloat {
        return headerHeight
    }
    
    private var collectionViewWidth: CGFloat = 0
    private var headerHeight: CGFloat = 0
    private var itemsInfo: [ItemInfo] = []
    override func invalidate(for reason: InvalidationReason, with info: Any?) {
        super.invalidate(for: reason, with: info)
        if reason != .otherReason {
            headerHeight = 0
            itemsInfo = []
        }
        else if info is Int {
            prepareHeaderFrames()
        }
    }
    
    override func prepare(for reason: InvalidationReason, updates: [SectionUpdate]?) {
        if headerHeight == 0 || itemsInfo.isEmpty || collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            prepareHeaderFrames()
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes] {
        guard headerHeight != 0 else {
            return []
        }
        
        let backgroundAttr = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: HeaderBackground.elementKind, with: IndexPath(item: 0, section: 0))
        backgroundAttr.zIndex = -1
        backgroundAttr.frame = CGRect(x: 0, y: 0, width: collectionViewWidth, height: headerHeight)
        backgroundAttr.info = User.currentPro.backgroundImageUrl
        
        var elements = [backgroundAttr]
        for (index,itemInfo) in itemsInfo.enumerated() {
            if itemInfo.frame.intersects(rect) {
                let attr = PuzzleCollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: sectionIndex))
                attr.frame = itemInfo.frame
                elements.append(attr)
            }
        }
        
        return elements
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        let attr = PuzzleCollectionViewLayoutAttributes(forCellWith: indexPath)
        if indexPath.item < itemsInfo.count {
            attr.frame = .zero
            attr.isHidden = true
        }
        else {
            attr.frame = itemsInfo[indexPath.item].frame
        }
        
        return attr
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        if elementKind == HeaderBackground.elementKind {
            let backgroundAttr = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: HeaderBackground.elementKind, with: IndexPath(item: 0, section: 0))
            backgroundAttr.zIndex = -1
            backgroundAttr.frame = CGRect(x: 0, y: 0, width: collectionViewWidth, height: headerHeight)
            backgroundAttr.info = User.currentPro.backgroundImageUrl
            return backgroundAttr
        }
        else { return nil }
    }
    
    // -------- Item attributes invalidation
    override func shouldInvalidate(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: inout CGSize, withOriginalSize originalSize: CGSize) -> Bool {
        switch elementCategory {
        case .cell(let itemIndex):
            switch Item(rawValue: itemIndex)! {
            case .profileImage:
                return false
            case .name, .category, .reviews:
                let frame = itemsInfo[itemIndex].fittedFrame
                if frame == nil || preferredSize != frame!.size {
                    return true
                }
            }
        default: break
        }
        
        return false
    }
    
    override func invalidationInfo(for elementCategory: InvalidationElementCategory, forPreferredSize preferredSize: CGSize, withOriginalSize originalSize: CGSize) -> Any? {
        switch elementCategory {
        case .cell(let itemIndex):
            switch Item(rawValue: itemIndex)! {
            case .name, .category, .reviews:
                itemsInfo[itemIndex].fittedFrame = CGRect(origin: itemsInfo[itemIndex].frame.origin, size: preferredSize)
                return itemIndex
            default: break
            }
        default: break
        }
        return nil
    }
    // --------
    
    private func prepareHeaderFrames() {
        guard let parentLayout = parentLayout else {
            return
        }
        
        let collectionHeight = parentLayout.collectionView!.bounds.height
        let isVerical = collectionViewWidth + 100 < collectionHeight
        headerHeight = floor(collectionHeight * 0.4)
        if isVerical && collectionHeight < 400 {
            headerHeight = 150
        }
        headerHeight = min(headerHeight, 300)
        
        let isBig = collectionViewWidth > 500
        let profileImageSize: CGFloat = isBig ? 100 : 75
        let inlinePadding: CGFloat = (isBig ? 16 : 8)
        let betweenLabelsPadding: CGFloat = 8
        if isVerical {
            var insets: CGFloat = (isBig ? 40 : 30)
            if itemsInfo.isEmpty {
                let profileImageInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: (collectionViewWidth - profileImageSize) * 0.5, y: insets, width: profileImageSize, height: profileImageSize))
                let nameInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: inlinePadding, y: profileImageInfo.frame.maxY + inlinePadding, width: collectionViewWidth - inlinePadding * 2, height: 20))
                let categoryInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: nameInfo.frame.minX, y: nameInfo.frame.maxY + betweenLabelsPadding, width: nameInfo.frame.width, height: 20))
                let reviewsInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: categoryInfo.frame.minX, y: categoryInfo.frame.maxY + inlinePadding, width: categoryInfo.frame.width, height: 20))
                itemsInfo = [profileImageInfo, nameInfo, categoryInfo, reviewsInfo]
            }
            
            var profileImageFrame = itemsInfo[Item.profileImage.rawValue].frame
            var nameFrame = itemsInfo[Item.name.rawValue].fittedFrame ?? itemsInfo[Item.name.rawValue].frame
            var categoryFrame = itemsInfo[Item.category.rawValue].fittedFrame ?? itemsInfo[Item.category.rawValue].frame
            var reviewsFrame = itemsInfo[Item.reviews.rawValue].fittedFrame ?? itemsInfo[Item.reviews.rawValue].frame
            
            let totalHeight = insets + (profileImageFrame.height) + (inlinePadding + nameFrame.height) + (betweenLabelsPadding + categoryFrame.height) + (inlinePadding + reviewsFrame.height) + insets
            if totalHeight > headerHeight {
                var diff = totalHeight - headerHeight
                insets -= min(20, diff)
                diff -= min(20, diff)
                
                profileImageFrame.size.width -= diff
                profileImageFrame.size.height = profileImageFrame.size.width
                
                let updatedTotalHeight = insets + (profileImageFrame.height) + (inlinePadding + nameFrame.height) + (betweenLabelsPadding + categoryFrame.height) + (inlinePadding + reviewsFrame.height) + insets
                profileImageFrame.origin.y = (headerHeight - updatedTotalHeight) * 0.5 + insets
            }
            else {
                profileImageFrame.origin.y = (headerHeight - totalHeight) * 0.5 + insets
            }
            
            profileImageFrame.origin.x = (collectionViewWidth - profileImageFrame.width) * 0.5
            
            nameFrame.origin.y = profileImageFrame.maxY + inlinePadding
            nameFrame.origin.x = (collectionViewWidth - nameFrame.width) * 0.5
            
            categoryFrame.origin.y = nameFrame.maxY + betweenLabelsPadding
            categoryFrame.origin.x = (collectionViewWidth - categoryFrame.width) * 0.5
            
            reviewsFrame.origin.y = categoryFrame.maxY + inlinePadding
            reviewsFrame.origin.x = (collectionViewWidth - reviewsFrame.width) * 0.5
            
            itemsInfo[Item.profileImage.rawValue].frame = profileImageFrame
            itemsInfo[Item.name.rawValue].frame = nameFrame
            itemsInfo[Item.category.rawValue].frame = categoryFrame
            itemsInfo[Item.reviews.rawValue].frame = reviewsFrame
        }
        else {
            let horizontalPadding: CGFloat = (isBig ? 20 : 10)
            if itemsInfo.isEmpty {
                let profileImageInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: horizontalPadding, y: headerHeight - horizontalPadding - profileImageSize, width: profileImageSize, height: profileImageSize))
                let reviewWidth: CGFloat = 100
                let reviewsInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: collectionViewWidth - reviewWidth - horizontalPadding, y: profileImageInfo.frame.minY, width: reviewWidth, height: 20))
                
                let nameInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: profileImageInfo.frame.maxX + inlinePadding, y: profileImageInfo.frame.minY, width: reviewsInfo.frame.minX - (inlinePadding * 2) - profileImageInfo.frame.maxX, height: 20))
                
                let categoryInfo = ItemInfo(heightState: .estimated, frame: CGRect(x: nameInfo.frame.minX, y: nameInfo.frame.maxY + betweenLabelsPadding, width: nameInfo.frame.width, height: 20))
                itemsInfo = [profileImageInfo, nameInfo, categoryInfo, reviewsInfo]
            }
            
            var profileImageFrame = itemsInfo[Item.profileImage.rawValue].frame
            var nameFrame = itemsInfo[Item.name.rawValue].fittedFrame ?? itemsInfo[Item.name.rawValue].frame
            var categoryFrame = itemsInfo[Item.category.rawValue].fittedFrame ?? itemsInfo[Item.category.rawValue].frame
            var reviewsFrame = itemsInfo[Item.reviews.rawValue].fittedFrame ?? itemsInfo[Item.reviews.rawValue].frame
            
            let maxProfileHeight: CGFloat = (headerHeight - 40) * 0.5
            let labelsHeight = nameFrame.height + betweenLabelsPadding + categoryFrame.height
            profileImageFrame.size.height = max(min(labelsHeight, maxProfileHeight), profileImageSize)
            profileImageFrame.size.width = profileImageFrame.size.height
            profileImageFrame.origin.y = headerHeight - horizontalPadding - profileImageSize
            profileImageFrame.origin.x = horizontalPadding
            
            reviewsFrame.origin.y = profileImageFrame.minY
            reviewsFrame.origin.x = collectionViewWidth - reviewsFrame.width - horizontalPadding
            
            nameFrame.origin.y = profileImageFrame.minY
            nameFrame.origin.x = profileImageFrame.maxX + inlinePadding
            let maxLabelWidth = (reviewsFrame.minX - profileImageFrame.maxX - (inlinePadding * 2))
            nameFrame.size.width = min(nameFrame.size.width, maxLabelWidth)
            nameFrame.size.height = min(profileImageFrame.size.height, nameFrame.size.height)
            
            categoryFrame.origin.x = nameFrame.minX
            categoryFrame.origin.y = nameFrame.maxY + betweenLabelsPadding
            categoryFrame.size.width = min(categoryFrame.size.width, maxLabelWidth)
            categoryFrame.size.height = min(profileImageFrame.size.height - nameFrame.height - betweenLabelsPadding, categoryFrame.size.height)
            
            itemsInfo[Item.profileImage.rawValue].frame = profileImageFrame
            itemsInfo[Item.name.rawValue].frame = nameFrame
            itemsInfo[Item.category.rawValue].frame = categoryFrame
            itemsInfo[Item.reviews.rawValue].frame = reviewsFrame
        }
    }
}

private struct ItemInfo: CustomStringConvertible {
    var heightState: ItemHeightState
    var frame: CGRect
    var fittedFrame: CGRect? = nil
    init(heightState: ItemHeightState, frame: CGRect = .zero) {
        self.heightState = heightState
        self.frame = frame
    }
    
    var description: String {
        return "Item Info: State:\(heightState) ; Frame: \(frame)"
    }
}

private class HeaderBackground : UICollectionReusableView {
    var imgView: AsyncImageView!
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if imgView == nil {
            imgView = AsyncImageView(frame: bounds)
            imgView.translatesAutoresizingMaskIntoConstraints = false
            imgView.contentMode = .scaleAspectFill
            addSubview(imgView)
            imgView!.topAnchor.constraint(equalTo: topAnchor).isActive = true
            imgView!.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            imgView!.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            imgView!.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            
            let overlay = UIView(frame: bounds)
            overlay.isUserInteractionEnabled = false
            overlay.backgroundColor = UIColor(white: 0, alpha: 0.5)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            addSubview(overlay)
            overlay.topAnchor.constraint(equalTo: topAnchor).isActive = true
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            
            clipsToBounds = true
        }
        
        imgView.clear()
        if let url = (layoutAttributes as? PuzzleCollectionViewLayoutAttributes)?.info as? URL {
            imgView.setImage(forURL: url)
        }
    }
    
    class var elementKind: String {
        return "HeaderBackgroundKind"
    }
}

