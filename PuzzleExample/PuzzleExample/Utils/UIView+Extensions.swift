//
//  UIView+Extensions.swift
//  PuzzleExample
//
//  Created by Yossi Avramov on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

extension UIView {
    var borderColor: UIColor? {
        get {
            if let c = layer.borderColor {
                return UIColor(cgColor: c)
            }
            else { return nil }
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}

extension UIFont {
    class func mediumSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightMedium)
    }
    
    class func semiboldSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightSemibold)
    }
    
    class func lightSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight)
    }
}
