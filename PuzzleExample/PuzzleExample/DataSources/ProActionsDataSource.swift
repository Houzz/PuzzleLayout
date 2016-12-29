//
//  ProActionsDataSource.swift
//  PuzzleExample
//
//  Created by Yossi Avramov on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

private enum Item : Int {
    case follow
    case website
    case more
    
    static var max: Int {
        return more.rawValue + 1
    }
    
    var title: String {
        switch self {
        case .follow: return "Follow"
        case .website: return "Website"
        case .more: return "More"
        }
    }
}

class ProActionsDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Item.max
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
        cell.lbl.text = Item(rawValue: indexPath.item)!.title
        cell.lbl.textColor = .black
        cell.lbl.font = UIFont.semiboldSystemFont(ofSize: 15)
        cell.lbl.textAlignment = .center
        cell.contentView.backgroundColor = .white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return ColumnBasedPuzzlePieceSectionLayout(columnType: .numberOfColumns(numberOfColumns: 3, itemHeight: 50), sectionInsets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10), minimumInteritemSpacing: 10, minimumLineSpacing: 10, separatorLineStyle: .none)
    }
}
