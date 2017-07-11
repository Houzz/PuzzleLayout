//
//  ColumnBasedPuzzlePieceSectionLayout+Utils.swift
//  PuzzleLayout
//
//  Created by Yossi Avramov on 09/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

public typealias DynamicItemSize = ((_ layout: ColumnBasedPuzzlePieceSectionLayout, _ width: CGFloat) -> CGSize)
public typealias DynamicNumberOfColumns = ((_ layout: ColumnBasedPuzzlePieceSectionLayout, _ width: CGFloat) -> (numberOfColumns: UInt, itemHeight: CGFloat))
public typealias QuickDynamicItemSize = ((_ layout: QuickColumnBasedPuzzlePieceSectionLayout, _ width: CGFloat) -> CGSize)
public typealias QuickDynamicNumberOfColumns = ((_ layout: QuickColumnBasedPuzzlePieceSectionLayout, _ width: CGFloat) -> (numberOfColumns: UInt, itemHeight: CGFloat))

/// The type of column in 'ColumnBasedPuzzlePieceSectionLayout'
public enum ColumnType : CustomStringConvertible {
    
    /// Columns number computed from item size & collection view size
    case itemSize(size: CGSize)
    
    /// Columns number computed from item size & collection view size. The item size will be asked again when collection width is changed.
    case dynamicItemSize(closure: DynamicItemSize)
    case quickDynamicItemSize(closure: QuickDynamicItemSize)

    /// Number of columns if fixed. The item size will be computed from collection width & number of columns.
    case numberOfColumns(numberOfColumns: UInt, itemHeight: CGFloat)
    
    /// The item size will be computed from collection width & number of columns. closure will be called when collection view width changed, given a chance to re-compute the number of columns
    case dynamicNumberOfColumns(closure: DynamicNumberOfColumns)
    case quickDynamicNumberOfColumns(closure: QuickDynamicNumberOfColumns)

    /// The Number of columns if fixed. The item width is computed from collection width & number of columns. The item height = (itemWidth * heightWidthRatio) + heightConstant
    case numberOfColumnsWithWidthDependency(numberOfColumns: UInt, heightWidthRatio: CGFloat, heightConstant: CGFloat)
    
    /// check if columns number should be computed from item size. Should be used by 'ColumnBasedPuzzlePieceSectionLayout' only
    internal var hasItemSize: Bool {
        switch self {
        case .itemSize(_), .dynamicItemSize(_), .quickDynamicItemSize(_): return true
        default: return false
        }
    }
    
    /// check if item size should be computed from columns number. Should be used by 'ColumnBasedPuzzlePieceSectionLayout' only
    var hasNumberOfColumns: Bool {
        return !hasItemSize
    }
    
    public var description: String {
        switch self {
        case .itemSize(let size): return "Item size: \(size)"
        case .dynamicItemSize(_): return "Dynamic item size"
        case .quickDynamicItemSize(_): return "Dynamic item size"
        case .numberOfColumns(let numberOfColumns, let itemHeight): return "Number of columns: \(numberOfColumns) ; Item height: \(itemHeight)"
        case .numberOfColumnsWithWidthDependency(let numberOfColumns, let heightWidthRatio, let heightConstant): return "Number of columns: \(numberOfColumns) ; Item height = (<ItemWidth> * \(heightWidthRatio)) + \(heightConstant)"
        case .dynamicNumberOfColumns(_): return "Dynamic number of columns"
        case .quickDynamicNumberOfColumns(_): return "Dynamic number of columns"
        }
    }
}

/// The row alignment when items in the same row has different height
public enum RowAlignmentOnItemSelfSizing {
    
    /// No alignment. This shouldn't be used when item size is estimated.
    case none
    
    /// Make items on same row having equal height (will choose the bigger item height in the row as the final height)
    case equalHeight
    
    /// Align items to have equal center
    case alignCenter
    
    /// Align items to have equal origin min y
    case alignTop
    
    /// Align items to have equal origin max y
    case alignBottom
}
