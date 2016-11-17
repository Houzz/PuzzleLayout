//
//  ProProfileViewController.swift
//  PuzzleExample
//
//  Created by Yossi houzz on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class ProProfileViewController: UIViewController, UICollectionViewDataSource, CollectionViewDataSourcePuzzleLayout {

    @IBOutlet var collectionView: UICollectionView!
    private let sectionsDataSource: [CollectionViewDataSourcePuzzleLayout] = [
        ProProfileHeaderDataSource(),
        ProActionsDataSource(),
        AboutMeDataSource(),
        LocationDataSource(),
        PhotosDataSource(),
        ProjectsDataSource(),
        FollowersDataSource(),
        ReviewsDataSource()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.setCollectionViewLayout(PuzzleCollectionViewLayout(), animated: false)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionsDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sectionsDataSource[section].collectionView(collectionView, numberOfItemsInSection: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return sectionsDataSource[indexPath.section].collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return sectionsDataSource[indexPath.section].collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) ?? collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return sectionsDataSource[index].collectionView(collectionView, layout: collectionViewLayout, layoutForSectionAtIndex: index)
    }
}
