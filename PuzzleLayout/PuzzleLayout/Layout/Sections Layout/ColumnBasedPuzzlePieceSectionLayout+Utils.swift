//
//  ColumnBasedPuzzlePieceSectionLayout+Utils.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 09/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

public typealias DynamicItemSize = ((_ layout: ColumnBasedPuzzlePieceSectionLayout, _ width: CGFloat) -> CGSize)
public typealias DynamicNumberOfColumns = ((_ layout: ColumnBasedPuzzlePieceSectionLayout, _ width: CGFloat) -> (numberOfColumns: UInt, itemHeight: CGFloat))

public enum ColumnType : CustomStringConvertible {
    case itemSize(size: CGSize)
    case dynamicItemSize(closure: DynamicItemSize)
    case numberOfColumns(numberOfColumns: UInt, itemHeight: CGFloat)
    case dynamicNumberOfColumns(closure: DynamicNumberOfColumns)
    
    var hasItemSize: Bool {
        switch self {
        case .itemSize(_), .dynamicItemSize(_): return true
        default: return false
        }
    }
    
    var hasNumberOfColumns: Bool {
        return !hasItemSize
    }
    
    public var description: String {
        switch self {
        case .itemSize(let size): return "Item size: \(size)"
        case .dynamicItemSize(_): return "Dynamic item size"
        case .numberOfColumns(let numberOfColumns, let itemHeight): return "Number of columns: \(numberOfColumns) ; Item height: \(itemHeight)"
        case .dynamicNumberOfColumns(_): return "Dynamic number of columns"
        }
    }
}

public enum RowAlignmentOnItemSelfSizing {
    case none
    case equalHeight
    case alignCenter
    case alignTop
    case alignBottom
}
