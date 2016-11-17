//
//  FollowersDataSource.swift
//  PuzzleExample
//
//  Created by Yossi houzz on 15/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class FollowersDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return User.currentPro.followers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        let follower = User.currentPro.followers[indexPath.item]
        cell.imgView.setImage(forURL: follower.url)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header.identifier, for: indexPath) as! Header
        header.lbl.text = "Followers (\(User.currentPro.followers.count))"
        header.lbl.textColor = .darkGray
        header.lbl.font = UIFont.semiboldSystemFont(ofSize: 14)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        let columnType: ColumnType = .dynamicItemSize(closure: { (layout, width) -> CGSize in
            let numberOfItems = User.currentPro.followers.count
            var numberOfColumns = numberOfItems
            let widthForItems = (width - (layout.sectionInsets.left + layout.sectionInsets.right + layout.minimumInteritemSpacing * CGFloat(numberOfColumns - 1)))
            var itemWidth: CGFloat = floor(widthForItems / CGFloat(numberOfColumns))
            while itemWidth < 75 {
                numberOfColumns = Int(CGFloat(numberOfColumns) * 0.5)
                let widthForItems = (width - (layout.sectionInsets.left + layout.sectionInsets.right + layout.minimumInteritemSpacing * CGFloat(numberOfColumns - 1)))
                itemWidth = floor(widthForItems / CGFloat(numberOfColumns))
            }
            
            return CGSize(width: itemWidth, height: itemWidth)
        })
        
        return ColumnBasedPuzzlePieceSectionLayout(columnType: columnType, sectionInsets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10), minimumInteritemSpacing: 2, minimumLineSpacing: 2, headerHeight: .estimated(height: 50))
    }
}
