//
//  ReviewsDataSource.swift
//  PuzzleExample
//
//  Created by Yossi houzz on 15/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class ReviewsDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return User.currentPro.reviews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReviewCell.identifier, for: indexPath) as! ReviewCell
        let review = User.currentPro.reviews[indexPath.item]
        cell.reviewer.text = review.userName
        cell.imgView.setImage(forURL: review.profileImageURL)
        cell.review.text = review.comment
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case PuzzleCollectionElementKindSectionFooter:
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
        default:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header.identifier, for: indexPath) as! Header
            header.lbl.text = "Reviews (\(User.currentPro.reviews.count))"
            header.lbl.textColor = .darkGray
            header.lbl.font = UIFont.semiboldSystemFont(ofSize: 14)
            return header
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return RowsPuzzlePieceSectionLayout(estimatedRowHeight: 100, sectionInsets: .zero, rowSpacing: 0, headerHeight: .estimated(height: 50), footerHeight: .estimated(height: 50), sectionFooterPinToVisibleBounds: true, separatorLineStyle: .allButLastItem)
    }
}
