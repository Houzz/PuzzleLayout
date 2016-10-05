//
//  ColumnBasedPuzzlePieceSectionLayout.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 05/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

typealias DynamicItemSize = ((_ traitCollection: UITraitCollection, _ size: CGSize) -> CGSize)
typealias DynamicNumberOfColumns = ((_ traitCollection: UITraitCollection, _ size: CGSize) -> UInt)

enum ColumnType {
    case ItemSize(size: CGSize)
    case DynamicItemSize(closure: DynamicItemSize)
    case NumberOfColumns(count: UInt)
    case DynamicNumberOfColumns(closure: DynamicNumberOfColumns)
}

//public class ColumnBasedPuzzlePieceSectionLayout: NSObject, PuzzlePieceSectionLayout {
//    
//}
