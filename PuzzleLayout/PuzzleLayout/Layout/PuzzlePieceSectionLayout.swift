//
//  PuzzlePieceSectionLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 23/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

public enum PuzzlePieceSeparatorLineStyle : Int {
    case none
    case allButLastItem
    case all
}

public enum InvalidationElementCategory {
    case cell(indexPath: IndexPath)
    
    case supplementaryView(indexPath: IndexPath, elementKind: String)
    
    case decorationView(indexPath: IndexPath, elementKind: String)
}
