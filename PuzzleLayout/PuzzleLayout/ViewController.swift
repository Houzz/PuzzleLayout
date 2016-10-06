//
//  ViewController.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 28/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CollectionViewDataSourcePuzzleLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let layouts = [
        RowsPuzzlePieceSectionLayout(estimatedItemHeight: 44, estimatedHeaderHeight: 30, separatorLineStyle: .all),
        RowsPuzzlePieceSectionLayout(estimatedItemHeight: 50, sectionInsets: UIEdgeInsetsMake(0, 15, 0, 15)),
        RowsPuzzlePieceSectionLayout(estimatedItemHeight: 60, separatorLineStyle: .none),
        RowsPuzzlePieceSectionLayout(estimatedItemHeight: 70, sectionInsets: UIEdgeInsetsMake(30, 20, 30, 0), estimatedHeaderHeight: 40, estimatedFooterHeight: 100),
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareDataSource()
        let layout = PuzzleCollectionViewLayout()
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let delay = DispatchTime.now() + DispatchTimeInterval.seconds(10)
        DispatchQueue.main.asyncAfter(deadline: delay) {
            DebugLog("Will delete")
            
            self.itemsInSection[0].remove(at: 3)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(item: 3, section: 0)])
                }, completion: nil)
        }
    }
    
    var itemsInSection: [[String]] = []
    private func prepareDataSource() {
        
        let numberOfSections = layouts.count
        itemsInSection = Array(repeating: [], count: numberOfSections)
        for section in 0..<numberOfSections {
            let numberOfItems = 10 * (section + 1)
            itemsInSection[section] = (0..<numberOfItems).map({ itemIndex -> String in
                let numberOfLines = Int(arc4random_uniform(200)) + 15
                let numberOfCharacters = Int(arc4random_uniform(10)) + 1
                return String.randomString(withLength: numberOfCharacters, minNumberOfLines: numberOfLines)
            })
        }
    }
    
    //MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return layouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsInSection[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        cell.lbl.text = itemsInSection[indexPath.section][indexPath.item]
        cell.contentView.backgroundColor = backgrounds[indexPath.item % backgrounds.count]
        return cell
    }
    
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: false)
            if indexPath.item % 2 == 0 {
                collectionView.collectionViewLayout.invalidateLayout()
            }
            else {
                collectionView.collectionViewLayout.invalidateLayout(with: UICollectionViewFlowLayoutInvalidationContext())
            }
        }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == PuzzleCollectionElementKindSectionHeader {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        }
        else if kind == PuzzleCollectionElementKindSectionFooter {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
        }
        else {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "", for: indexPath)
        }
    }
    
    let backgrounds: [UIColor] = [
        .red,
        .green,
        .cyan,
        .gray
    ]
    
    //MARK: - CollectionViewDataSourcePuzzleLayout
    func collectionView(_ collectionView: UICollectionView, collectionViewLayout layout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return layouts[index]
    }
}

class Cell : UICollectionViewCell {
    @IBOutlet weak var lbl: UILabel!
    
    var indexPath: IndexPath?
    private var cachedSize: CGSize?
    
    override func prepareForReuse() {
        cachedSize = nil
        indexPath = nil
        super.prepareForReuse()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        indexPath = layoutAttributes.indexPath
        cachedSize = (layoutAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize
    }
    
    private var widthLayout: NSLayoutConstraint!
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        if let cachedSize = cachedSize , cachedSize.width == targetSize.width {
            return cachedSize
        }
        
        if widthLayout == nil {
            widthLayout = self.contentView.widthAnchor.constraint(equalToConstant: targetSize.width)
        }
        else {
            widthLayout.constant = targetSize.width
        }
        widthLayout.isActive = true
        setNeedsLayout()
        let size = super.systemLayoutSizeFitting(targetSize)
        widthLayout.isActive = false
        return size
    }
}

class HeaderFooter : UICollectionReusableView {
    @IBOutlet weak var lbl: UILabel!
}

extension String {
    public static func randomString(withLength length: Int = 8, minNumberOfLines: Int = 1) -> String {
        let letters: String = "abcdefghijklmnopqrstuvwxyz0123456789"
        let lettersCount = UInt32(letters.characters.count)
        var randomString: String = ""
        var numberOfLines = minNumberOfLines
        for _ in 0 ..< 100 {
            let rand = arc4random_uniform(lettersCount)
            let c = letters[letters.index(letters.startIndex, offsetBy: Int(rand))]
            randomString.append(c)
            if numberOfLines != 0 && rand % 10 == 5 {
                randomString.append("\n")
                numberOfLines -= 1
            }
        }
        
        return randomString
    }
}

func DebugLog(_ message:  String) {
    print(message)
}
