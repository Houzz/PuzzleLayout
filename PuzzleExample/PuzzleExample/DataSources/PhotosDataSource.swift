//
//  PhotosDataSource.swift
//  PuzzleExample
//
//  Created by Yossi Avramov on 15/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class PhotosDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return User.currentPro.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        cell.imgView.setImage(forURL: User.currentPro.photos[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header.identifier, for: indexPath) as! Header
        header.lbl.text = "Photos (\(User.currentPro.photos.count))"
        header.lbl.textColor = .darkGray
        header.lbl.font = UIFont.semiboldSystemFont(ofSize: 14)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return  SwitchablePhotosLayout()
//        let columnType: ColumnType = .dynamicItemSize(closure: { (layout, _, width) -> CGSize in
//            let numberOfColumns: CGFloat
//            if width > 800 {
//                numberOfColumns = 5
//            }
//            else if width > 650 {
//                numberOfColumns = 4
//            }
//            else if width > 500 {
//                numberOfColumns = 3
//            }
//            else {
//                numberOfColumns = 2
//            }
//            
//            let itemWidth = floor((width - (layout.sectionInsets.left + layout.sectionInsets.right + layout.minimumInteritemSpacing * (numberOfColumns - 1))) / numberOfColumns)
//            return CGSize(width: itemWidth, height: itemWidth)
//        })
//        
//        return ColumnBasedPuzzlePieceSectionLayout(columnType: columnType, sectionInsets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10), minimumInteritemSpacing: 2, minimumLineSpacing: 2, headerHeight: .estimated(height: 50))
    }
}

fileprivate class SwitchablePhotosLayout: PuzzlePieceSectionLayout {
    
    var bigItemSize = CGSize.zero
    var smallItemSize = CGSize.zero
    var showSmallItemsOnRight = false
    var showSmallItemsOnBottom = false
    var indexOfBigItem: Int?
    override var heightOfSection: CGFloat {
        if showSmallItemsOnBottom && !showSmallItemsOnRight {
            return 2 + bigItemSize.height + (showSmallItemsOnBottom ? (smallItemSize.height + 2) * 2 : 0) + 2
        }
        else {
            return 2 + bigItemSize.height + (showSmallItemsOnBottom ? (smallItemSize.height + 2) : 0) + 2
        }
    }
    
    private var collectionViewWidth: CGFloat = 0
    private var itemsFrame: [CGRect] = []
    private var ti: Timer?
    deinit {
        ti?.invalidate()
    }
    
    var switchTuple: (from: Int, to: Int)?
    override func invalidate(for reason: InvalidationReason, with info: Any?) {
        super.invalidate(for: reason, with: info)
        if reason != .otherReason {
            bigItemSize = .zero
            smallItemSize = .zero
            itemsFrame = []
        }
        else if let (from,to) = info as? (Int,Int) {
            switchTuple = (from,to)
            let temp = itemsFrame[from]
            itemsFrame[from] = itemsFrame[to]
            itemsFrame[to] = temp
        }
    }
    
    override func prepare(didReloadData: Bool, didUpdateDataSourceCounts: Bool, didResetLayout: Bool) {
        if bigItemSize.height == 0 || itemsFrame.isEmpty || collectionViewWidth != sectionWidth {
            collectionViewWidth = sectionWidth
            prepareMosaic()
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect, sectionIndex: Int) -> [PuzzleCollectionViewLayoutAttributes] {
        
        var elements: [PuzzleCollectionViewLayoutAttributes] = []
        for (index,itemFrame) in itemsFrame.enumerated() {
            if itemFrame.intersects(rect) {
                let attr = PuzzleCollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: sectionIndex))
                attr.frame = itemFrame
                elements.append(attr)
            }
        }
        
        if elements.isEmpty == false && ti == nil {
            DispatchQueue.main.async {
                self.startSwitching()
            }
        }
        
        return elements
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        let attr = PuzzleCollectionViewLayoutAttributes(forCellWith: indexPath)
        if indexPath.item < itemsFrame.count {
            attr.frame = itemsFrame[indexPath.item]
        }
        else {
            attr.frame = .zero
            attr.isHidden = true
        }
        
        return attr
    }
    
    override public func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
        if let switchTuple = switchTuple {
            if itemIndexPath.item == switchTuple.from {
                let attr = PuzzleCollectionViewLayoutAttributes(forCellWith: itemIndexPath)
                attr.frame = itemsFrame[switchTuple.to]
                return attr
            }
            else if itemIndexPath.item == switchTuple.to {
                let attr = PuzzleCollectionViewLayoutAttributes(forCellWith: itemIndexPath)
                attr.frame = itemsFrame[switchTuple.from]
                return attr
            }
            else { return nil }
        }
        else { return nil }
    }
    
//    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> PuzzleCollectionViewLayoutAttributes? {
//        if elementKind == HeaderBackground.elementKind {
//            let backgroundAttr = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: HeaderBackground.elementKind, with: IndexPath(item: 0, section: 0))
//            backgroundAttr.zIndex = -1
//            backgroundAttr.frame = CGRect(x: 0, y: 0, width: collectionViewWidth, height: headerHeight)
//            backgroundAttr.info = User.currentPro.backgroundImageUrl
//            return backgroundAttr
//        }
//        else { return nil }
//    }
    
    func prepareMosaic() {
        guard let parentLayout = parentLayout else {
            return
        }
        
        if indexOfBigItem == nil {
            indexOfBigItem = 0
        }
        
        let collectionHeight = parentLayout.collectionView!.bounds.height
        let maxSize = min(max(collectionHeight, collectionViewWidth), 400)
        showSmallItemsOnRight = (collectionHeight < collectionViewWidth || maxSize * 1.5 < collectionViewWidth)
        showSmallItemsOnBottom = (collectionViewWidth < collectionHeight || maxSize * 1.4 < collectionHeight)
        bigItemSize = CGSize(width: maxSize, height: maxSize)
        if showSmallItemsOnRight && showSmallItemsOnBottom && numberOfItemsInSection < 9 {
            showSmallItemsOnRight = collectionHeight < collectionViewWidth
            showSmallItemsOnBottom = !showSmallItemsOnRight
        }
        
        if showSmallItemsOnRight && showSmallItemsOnBottom {
            let numberOfItemsInRowAndColumn: CGFloat = 4
            let s = floor(bigItemSize.width - (2 * (numberOfItemsInRowAndColumn - 1))) / numberOfItemsInRowAndColumn
            let padding = (bigItemSize.width - (s * numberOfItemsInRowAndColumn)) / (numberOfItemsInRowAndColumn - 1)
            smallItemSize = CGSize(width: s, height: s)
            let visibleItems = 1 + Int(numberOfItemsInRowAndColumn * 2) + 1
            itemsFrame = [CGRect](repeating: CGRect.zero, count: visibleItems)
            let bigIndex = indexOfBigItem ?? 0
            itemsFrame[bigIndex] = CGRect(origin: CGPoint(x: (collectionViewWidth - bigItemSize.width - smallItemSize.width - 2)*0.5 + 2 + smallItemSize.width, y: 2), size: bigItemSize)
            
            
            var lastOriginY: CGFloat = itemsFrame[bigIndex].minY
            let originX: CGFloat = itemsFrame[bigIndex].minX - padding - smallItemSize.width
            let verticalItems = (bigIndex < 5) ? (0 ..< 6) : (0 ..< 5)
            for index in verticalItems {
                if index != bigIndex {
                    itemsFrame[index] = CGRect(origin: CGPoint(x: originX, y: lastOriginY), size: smallItemSize)
                    lastOriginY += smallItemSize.height + padding
                }
            }
            
            var lastOriginX: CGFloat = originX
            let originY: CGFloat = itemsFrame[bigIndex].maxY + 2
            for index in verticalItems.last! ..< visibleItems {
                if index != bigIndex {
                    itemsFrame[index] = CGRect(origin: CGPoint(x: lastOriginX, y: originY), size: smallItemSize)
                    lastOriginX += smallItemSize.width + padding
                }
            }
        }
        else if showSmallItemsOnRight {
            
            let numberOfItemsColumn: CGFloat = 4
            let s = floor(bigItemSize.width - (2 * (numberOfItemsColumn - 1))) / numberOfItemsColumn
            let padding = (bigItemSize.width - (s * numberOfItemsColumn)) / (numberOfItemsColumn - 1)
            smallItemSize = CGSize(width: s, height: s)
            let visibleItems = 1 + Int(numberOfItemsColumn * 2)
            itemsFrame = [CGRect](repeating: CGRect.zero, count: visibleItems)
            let bigIndex = indexOfBigItem ?? 0
            itemsFrame[bigIndex] = CGRect(origin: CGPoint(x: (collectionViewWidth - bigItemSize.width - (smallItemSize.width + 2) * 2)*0.5, y: 2), size: bigItemSize)
            
            var lastOriginY: CGFloat = itemsFrame[bigIndex].minY
            var lastOriginX: CGFloat = itemsFrame[bigIndex].maxX + padding
            var count: Int = 0
            for index in (0 ..< visibleItems) {
                if index != bigIndex {
                    itemsFrame[index] = CGRect(origin: CGPoint(x: lastOriginX, y: lastOriginY), size: smallItemSize)
                    lastOriginY += smallItemSize.height + padding
                    
                    count += 1
                    if count == Int(numberOfItemsColumn) {
                        lastOriginX += 2 + smallItemSize.width
                        lastOriginY = itemsFrame[bigIndex].minY
                    }
                }
            }
        }
        else { //showSmallItemsOnBottom
            let numberOfItemsRow: CGFloat = 4
            let s = floor(bigItemSize.width - (2 * (numberOfItemsRow - 1))) / numberOfItemsRow
            let padding = (bigItemSize.width - (s * numberOfItemsRow)) / (numberOfItemsRow - 1)
            smallItemSize = CGSize(width: s, height: s)
            let visibleItems = 1 + Int(numberOfItemsRow * 2)
            itemsFrame = [CGRect](repeating: CGRect.zero, count: visibleItems)
            let bigIndex = indexOfBigItem ?? 0
            itemsFrame[bigIndex] = CGRect(origin: CGPoint(x: (collectionViewWidth - bigItemSize.width)*0.5, y: 2), size: bigItemSize)
            
            var lastOriginY: CGFloat = itemsFrame[bigIndex].maxY + padding
            var lastOriginX: CGFloat = itemsFrame[bigIndex].minX
            var count: Int = 0
            for index in (0 ..< visibleItems) {
                if index != bigIndex {
                    itemsFrame[index] = CGRect(origin: CGPoint(x: lastOriginX, y: lastOriginY), size: smallItemSize)
                    lastOriginX += smallItemSize.height + padding
                    
                    count += 1
                    if count == Int(numberOfItemsRow) {
                        lastOriginY += 2 + smallItemSize.height
                        lastOriginX = itemsFrame[bigIndex].minX
                    }
                }
            }
        }
    }
    
    func startSwitching() {
        if ti == nil {
            ti = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(SwitchablePhotosLayout.showNext(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func stopSwitching() {
        ti?.invalidate()
        ti = nil
    }
    
    @objc func showNext(_ ti: Timer?) {
        let old = indexOfBigItem!
        let new = (old + 1) % itemsFrame.count
        let tuple: (from: Int, to: Int) = (from: old, to: new)
        guard let context = invalidationContext(with: tuple) else {
            return
        }
        
        indexOfBigItem! = new
        UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: {
            self.parentLayout!.invalidateLayout(with: context)
        }, completion: nil)
    }
}


