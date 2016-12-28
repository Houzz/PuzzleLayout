//
//  PuzzleCollectionViewLayout+Utils.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 08/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

/// An enum for Header & Footer required size
public enum HeadeFooterHeightSize : CustomStringConvertible {
    
    /// No header/footer
    case none
    
    /// Header/footer with fixed size
    case fixed(height: CGFloat)
    
    /// Header/footer with self-sizing
    case estimated(height: CGFloat)
    
    var isEstimated: Bool {
        switch self {
        case .estimated(_) : return true
        default: return false
        }
    }
    
    public var description: String {
        switch self {
        case .none: return "None"
        case .fixed(let height): return "Fixed: \(height)"
        case .estimated(let height): return "Estimated: \(height)"
        }
    }
}

/// An enum for item height state
enum ItemHeightState : Int, CustomStringConvertible {
    
    /// Item size is fixed & shouldn't be self-sized
    case fixed
    
    /// Item size is estimated & should be computed
    case estimated
    
    /// Item size is computed
    case computed
    
    var description: String {
        switch self {
        case .fixed: return "Fixed height"
        case .estimated: return "Estimated height"
        case .computed: return "Computed height"
        }
    }
}

/// Structure for keeping header/footer info
struct HeaderFooterInfo : CustomStringConvertible {
    
    /// The header/footer height state
    var heightState: ItemHeightState
    
    /// The header/footer origin Y in section coordinate system.
    var originY: CGFloat
    
    /// The header/footer current height
    var height: CGFloat
    
    ///The header/footer max Y in section coordinate system.
    var maxOriginY: CGFloat {
        return originY + height
    }
    
    /**
     Check if header/footer is intersecting a given rect.
     
     - parameter rect: A CGRect in section coordinate system.
     
     - returns: True, if the header/footer intersects the given rect. Othersize, false.
     */
    func intersects(with rect: CGRect) -> Bool {
        return !(originY >= rect.maxY || maxOriginY <= rect.minY)
    }
    
    var description: String {
        return "Row Info: state:\(heightState) ; origin Y: \(originY) ; Height: \(height)"
    }
}
