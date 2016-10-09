//
//  PuzzleCollectionViewLayout+Utils.swift
//  PuzzleLayout
//
//  Created by Yossi houzz on 08/10/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

public enum HeadeFooterHeightSize : CustomStringConvertible {
    case none
    case fixed(height: CGFloat)
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

enum ItemHeightState : Int, CustomStringConvertible {
    case fixed
    case estimated
    case computed
    
    var description: String {
        switch self {
        case .fixed: return "Fixed height"
        case .estimated: return "Estimated height"
        case .computed: return "Computed height"
        }
    }
}

struct HeaderFooterInfo : CustomStringConvertible {
    var heightState: ItemHeightState
    var originY: CGFloat
    var height: CGFloat
    var maxOriginY: CGFloat {
        return originY + height
    }
    
    func intersects(with rect: CGRect) -> Bool {
        return !(originY >= rect.maxY || maxOriginY <= rect.minY)
    }
    
    var description: String {
        return "Row Info: state:\(heightState) ; origin Y: \(originY) ; Height: \(height)"
    }
}
