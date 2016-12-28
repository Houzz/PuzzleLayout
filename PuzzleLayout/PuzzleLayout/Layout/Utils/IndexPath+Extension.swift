//
//  IndexPath+Extension.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 29/09/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import Foundation

internal extension IndexPath {
    
    /**
     Generate a list of IndexPath from a range of numbers for a given section
     
     - parameter section: The section index
     
     - parameter itemsRange: The range of numbers
     
     - returns: list of IndexPath
     */
    static func indexPaths(for section: Int, itemsRange: CountableRange<Int>) -> [IndexPath] {
        return itemsRange.map({ item -> IndexPath in return IndexPath(item: item, section: section) })
    }
}
