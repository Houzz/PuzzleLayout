//
//  ViewController.swift
//  PuzzleLayout
//
//  Created by Yossi Avramov on 28/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CollectionViewDataSourcePuzzleLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let layouts: [PuzzlePieceSectionLayout] = [
        RowsPuzzlePieceSectionLayout(estimatedRowHeight: 200, sectionInsets: UIEdgeInsetsMake(0, 10, 0, 10), rowSpacing: 4, headerHeight: .estimated(height: 50), footerHeight: .fixed(height: 100)),
        ColumnBasedPuzzlePieceSectionLayout(columnType: ColumnType.dynamicNumberOfColumns(closure: { (_, width) -> (numberOfColumns: UInt, itemHeight: CGFloat) in
            if width > 800 { return (5, 175) }
            else if width > 600 { return (4, 160) }
            else if width > 400 { return (3, 150) }
            else { return (2, 120) }
        }), sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), minimumInteritemSpacing: 5, minimumLineSpacing: 5, headerHeight: .estimated(height: 50), footerHeight: .estimated(height: 50), separatorLineStyle: .all, separatorLineInsets: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)),
        HeaderFootertOnlySectionLayout(headerHeight: .fixed(height: 75), footerHeight: .estimated(height: 30), insets: 15, showGutter: true),
        ColumnBasedPuzzlePieceSectionLayout(columnType: ColumnType.numberOfColumns(numberOfColumns: 4, itemHeight: 175), sectionInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), minimumInteritemSpacing: 8, minimumLineSpacing: 8, headerHeight: .fixed(height: 75), footerHeight: .estimated(height: 100), separatorLineStyle: .none),
        ColumnBasedPuzzlePieceSectionLayout(estimatedColumnType: ColumnType.numberOfColumns(numberOfColumns: 4, itemHeight: 175), sectionInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), minimumInteritemSpacing: 8, minimumLineSpacing: 8, headerHeight: .fixed(height: 75), footerHeight: .estimated(height: 100), separatorLineStyle: .none),
        ColumnBasedPuzzlePieceSectionLayout(estimatedColumnType: ColumnType.numberOfColumns(numberOfColumns: 5, itemHeight: 120), rowAlignment: .equalHeight, sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), minimumInteritemSpacing: 5, minimumLineSpacing: 5, separatorLineStyle: .all),
        ColumnBasedPuzzlePieceSectionLayout(estimatedColumnType: ColumnType.numberOfColumns(numberOfColumns: 3, itemHeight: 120), rowAlignment: .alignTop, sectionInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), minimumInteritemSpacing: 5, minimumLineSpacing: 5, separatorLineStyle: .all),
        ColumnBasedPuzzlePieceSectionLayout(estimatedColumnType: ColumnType.dynamicNumberOfColumns(closure: { (_, width) -> (numberOfColumns: UInt, itemHeight: CGFloat) in
            if width > 800 { return (5, 175) }
            else if width > 600 { return (4, 160) }
            else if width > 400 { return (3, 150) }
            else { return (2, 120) }
        }), rowAlignment: .alignBottom, sectionInsets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), minimumInteritemSpacing: 20, minimumLineSpacing: 20, headerHeight: .fixed(height: 50), footerHeight: .fixed(height: 50), separatorLineStyle: .none),
        RowsPuzzlePieceSectionLayout(rowHeight: 44, headerHeight: .fixed(height: 100), separatorLineStyle: .all),
        RowsPuzzlePieceSectionLayout(rowHeight: 60, sectionInsets: UIEdgeInsetsMake(20, 20, 20, 20), rowSpacing: 0, headerHeight: .estimated(height: 100), footerHeight: .estimated(height: 100), separatorLineStyle: .none, showTopGutter: true, showBottomGutter: false),
        RowsPuzzlePieceSectionLayout(estimatedRowHeight: 50, sectionInsets: UIEdgeInsetsMake(20, 20, 20, 20), showTopGutter: true, showBottomGutter: true),
        ColumnBasedPuzzlePieceSectionLayout(columnType: ColumnType.numberOfColumnsWithWidthDependency(numberOfColumns: 3, heightWidthRatio: 1, heightConstant: 45), sectionInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), minimumInteritemSpacing: 10, minimumLineSpacing: 10)
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.allowsMultipleSelection = true
        prepareDataSource()
        let layout = PuzzleCollectionViewLayout()
        layout.separatorLineColor = .black
        collectionView.setCollectionViewLayout(layout, animated: false)
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout {
        return layouts[index]
    }
}

class Cell : UICollectionViewCell {
    @IBOutlet weak var lbl: UILabel!
    
    var indexPath: IndexPath?
    fileprivate var cachedSize: CGSize?
    
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

func DEBUGLog(_ message:  String) {
    print(message)
}
