//
//  InfoDataSources.swift
//  PuzzleExample
//
//  Created by Yossi houzz on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class AboutMeDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
        cell.lbl.text = User.currentPro.aboutMe
        cell.lbl.textColor = .black
        cell.lbl.font = UIFont.systemFont(ofSize: 12)
        cell.lbl.numberOfLines = 0
        cell.lbl.textAlignment = .left
        cell.leading.constant = 10
        cell.trailing.constant = 10
        cell.top.constant = 10
        cell.bottom.constant = 10
        cell.contentView.backgroundColor = .white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header.identifier, for: indexPath) as! Header
        header.backgroundColor = .clear
        header.lbl.text = "About me"
        header.lbl.textColor = .darkGray
        header.lbl.font = UIFont.semiboldSystemFont(ofSize: 14)
        header.btn.isHidden = true
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return RowsPuzzlePieceSectionLayout(estimatedRowHeight: 50, sectionInsets: UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0), rowSpacing: 0, headerHeight: .estimated(height: 50), separatorLineStyle: .none)
    }
}

class LocationDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as! ImageCell
        cell.imgView.setImage(forLocation: User.currentPro.location)
        cell.contentView.backgroundColor = .white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header.identifier, for: indexPath) as! Header
        header.backgroundColor = .clear
        header.lbl.text = "Location"
        header.lbl.textColor = .darkGray
        header.lbl.font = UIFont.semiboldSystemFont(ofSize: 14)
        header.btn.isHidden = true
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return RowsPuzzlePieceSectionLayout(rowHeight: 200, sectionInsets: UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0), rowSpacing: 0, headerHeight: .estimated(height: 50), separatorLineStyle: .none)
    }
}

