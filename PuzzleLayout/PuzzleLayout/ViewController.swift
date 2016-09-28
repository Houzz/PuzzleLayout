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
        RowsSectionPuzzleLayout(estimatedItemHeight: 44, estimatedHeaderHeight: 30),
        RowsSectionPuzzleLayout(estimatedItemHeight: 50, sectionInsets: UIEdgeInsetsMake(0, 15, 0, 15)),
        RowsSectionPuzzleLayout(estimatedItemHeight: 60),
        RowsSectionPuzzleLayout(estimatedItemHeight: 70, sectionInsets: UIEdgeInsetsMake(30, 20, 30, 0), estimatedHeaderHeight: 40, estimatedFooterHeight: 100),
        ]
    
    private var item_numberOfLinesMapper: [IndexPath:Int] = [:]
    private var item_numberOfCharactersMapper: [IndexPath:Int] = [:]
    
    private var header_numberOfLinesMapper: [IndexPath:Int] = [:]
    private var header_numberOfCharactersMapper: [IndexPath:Int] = [:]
    
    private var footer_numberOfLinesMapper: [IndexPath:Int] = [:]
    private var footer_numberOfCharactersMapper: [IndexPath:Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = PuzzleCollectionViewLayout()
        collectionView.setCollectionViewLayout(layout, animated: false)
        //        let layout = collectionView.collectionViewLayout as! TableGridLayout
        //        layout.sectionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        //        layout.lineSpacing = 8
        //        layout.itemSpacing = 8
        //        layout.estimatedHeight = 40
    }
    
    //MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return layouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 * (section + 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        if item_numberOfLinesMapper[indexPath] == nil {
            item_numberOfLinesMapper[indexPath] = Int(arc4random_uniform(10)) + 1
        }
        
        if item_numberOfCharactersMapper[indexPath] == nil {
            item_numberOfCharactersMapper[indexPath] = Int(arc4random_uniform(200)) + 15
        }
        
        cell.lbl.text = String.randomString(withLength: item_numberOfCharactersMapper[indexPath]!, minNumberOfLines: item_numberOfLinesMapper[indexPath]!)
        cell.contentView.backgroundColor = backgrounds[(indexPath as NSIndexPath).item % backgrounds.count]
        return cell
    }
    
    //    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //        collectionView.deselectItem(at: indexPath, animated: false)
    //        if indexPath.item % 2 == 0 {
    //            collectionView.collectionViewLayout.invalidateLayout()
    //        }
    //        else {
    //            collectionView.collectionViewLayout.invalidateLayout(with: UICollectionViewFlowLayoutInvalidationContext())
    //        }
    //    }
    
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
    override func prepareForReuse() {
        super.prepareForReuse()
        indexPath = nil
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        indexPath = layoutAttributes.indexPath
    }
    
    private var widthLayout: NSLayoutConstraint!
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        if widthLayout == nil {
            widthLayout = self.widthAnchor.constraint(equalToConstant: targetSize.width)
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
