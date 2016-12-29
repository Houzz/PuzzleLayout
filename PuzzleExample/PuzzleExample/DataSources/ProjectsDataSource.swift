//
//  ProjectsDataSource.swift
//  PuzzleExample
//
//  Created by Yossi Avramov on 15/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class ProjectsDataSource : NSObject, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {
    private var isExpanded = false
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isExpanded ? User.currentPro.projects.count : 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProjectCell.identifier, for: indexPath) as! ProjectCell
        let project = User.currentPro.projects[indexPath.item]
        cell.imgView.setImage(forURL: project.url)
        cell.lbl.text = project.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Header.identifier, for: indexPath) as! Header
        header.lbl.text = "Projects (\(User.currentPro.projects.count))"
        header.lbl.textColor = .darkGray
        header.lbl.font = UIFont.semiboldSystemFont(ofSize: 14)
        header.btn.isHidden = false
        header.btn.setTitle(isExpanded ? "Show Less" : "Show more", for: .normal)
        let btn = header.btn!
        let sectionIndex = indexPath.section
        header.onActionTap = { [weak self] in
            if let strongSelf = self {
                let oldNumberOfItems = strongSelf.isExpanded ? User.currentPro.projects.count : 4
                strongSelf.isExpanded = !strongSelf.isExpanded
                header.btn.setTitle(strongSelf.isExpanded ? "Show Less" : "Show more", for: .normal)
                let newNumberOfItems = strongSelf.isExpanded ? User.currentPro.projects.count : 4
                btn.isEnabled = false
                collectionView.performBatchUpdates({ 
                    if oldNumberOfItems < newNumberOfItems {
                        let indexPaths = (oldNumberOfItems..<newNumberOfItems).map({ (item: Int) -> IndexPath in
                            return IndexPath(item: item, section: sectionIndex)
                        })
                        collectionView.insertItems(at: indexPaths)
                    }
                    else {
                        let indexPaths = (newNumberOfItems..<oldNumberOfItems).map({ (item: Int) -> IndexPath in
                            return IndexPath(item: item, section: sectionIndex)
                        })
                        collectionView.deleteItems(at: indexPaths)
                    }
                }, completion: { _ in
                    btn.isEnabled = true
                })
            }
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        let columnType: ColumnType = .dynamicItemSize(closure: { (layout, width) -> CGSize in
            let numberOfColumns: CGFloat
            if width > 510 { numberOfColumns = 4 }
            else { numberOfColumns = 2 }
            
            let itemWidth = floor((width - (layout.sectionInsets.left + layout.sectionInsets.right + layout.minimumInteritemSpacing * (numberOfColumns - 1))) / numberOfColumns)
            return CGSize(width: itemWidth, height: itemWidth + 30)
        })
        
        return ColumnBasedPuzzlePieceSectionLayout(estimatedColumnType: columnType, rowAlignment: .equalHeight, sectionInsets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10), minimumInteritemSpacing: 10, minimumLineSpacing: 10, headerHeight: .estimated(height: 50))
    }
}
