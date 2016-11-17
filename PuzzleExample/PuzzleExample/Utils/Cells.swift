//
//  Cells.swift
//  PuzzleExample
//
//  Created by Yossi houzz on 16/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit

class Cell : UICollectionViewCell {
    
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
        
        if (indexPath == nil || indexPath!.section != 0) {
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
        else {
            return super.systemLayoutSizeFitting(targetSize)
        }
    }
}

class HeaderFooter : UICollectionReusableView {
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

class LabelCell: Cell {
    @IBOutlet var lbl: UILabel!
    @IBOutlet var top: NSLayoutConstraint!
    @IBOutlet var leading: NSLayoutConstraint!
    @IBOutlet var bottom: NSLayoutConstraint!
    @IBOutlet var trailing: NSLayoutConstraint!
    
    static var identifier: String {
        return "LabelCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lbl.text = nil
        lbl.textAlignment = .left
        lbl.numberOfLines = 1
        borderWidth = 0
        cornerRadius = 0
        contentView.backgroundColor = .white
        
        top.constant = 0
        leading.constant = 0
        bottom.constant = 0
        trailing.constant = 0
    }
}

class ImageCell: Cell {
    @IBOutlet var imgView: AsyncImageView!
    static var identifier: String {
        return "ImageCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imgView.clear()
        contentView.borderWidth = 0
        contentView.cornerRadius = 0
        contentView.backgroundColor = .white
    }
}

class LabelOverImageCell: Cell {
    @IBOutlet var lbl: UILabel!
    @IBOutlet var imgView: AsyncImageView!
    static var identifier: String {
        return "LabelOverImageCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lbl.text = nil
        lbl.textAlignment = .center
        lbl.numberOfLines = 1
        imgView.clear()
        borderWidth = 0
        cornerRadius = 0
        contentView.backgroundColor = .white
    }
}

class ImageAndLabelCell: Cell {
    @IBOutlet var lbl: UILabel!
    @IBOutlet var imgView: AsyncImageView!
    static var identifier: String {
        return "ImageAndLabelCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lbl.text = nil
        lbl.textAlignment = .left
        lbl.numberOfLines = 1
        imgView.clear()
        borderWidth = 0
        cornerRadius = 0
        imgView.cornerRadius = 0
        imgView.borderWidth = 0
        contentView.backgroundColor = .white
    }
}

class ReviewStarsCell: Cell {
    @IBOutlet var stars: [UIImageView]!
    @IBOutlet var numberOfReviewsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }
    
    func update(withStars numberOfStars: UInt, halfStar: Bool) {
        let onStars = Int(min(5, numberOfStars + (halfStar ? 1 : 0)))
        for index in 0..<onStars {
            stars[index].image = UIImage(named: "star_white2")
        }
        
        if halfStar {
            stars[onStars-1].image = UIImage(named: "star_white1")
        }
        
        for index in onStars..<5 {
            stars[index].image = UIImage(named: "star_white0")
        }
    }
    
    static var identifier: String {
        return "ReviewStarsCell"
    }
}

class Header : HeaderFooter {
    @IBOutlet var lbl: UILabel!
    @IBOutlet var btn: UIButton!
    var onActionTap: (()->Void)?
    
    @IBAction func actionTap(_ sender: AnyObject!) {
        onActionTap?()
    }
    
    static var identifier: String {
        return "header"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lbl.text = nil
        lbl.textAlignment = .left
        lbl.numberOfLines = 1
        btn.isHidden = true
        borderWidth = 0
        cornerRadius = 0
        backgroundColor = .clear
        onActionTap = nil
    }
}

class ProjectCell : Cell {
    @IBOutlet var lbl: UILabel!
    @IBOutlet var imgView: AsyncImageView!
    static var identifier: String {
        return "ProjectCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lbl.text = nil
        imgView.clear()
        contentView.backgroundColor = .white
    }
}

class ReviewCell : Cell {
    @IBOutlet var reviewer: UILabel!
    @IBOutlet var imgView: AsyncImageView!
    @IBOutlet var review: UILabel!
    @IBOutlet var stars: [UIImageView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .white
    }
    
    static var identifier: String {
        return "ReviewCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reviewer.text = nil
        review.text = nil
        imgView.clear()
    }
    
    func update(withRating rating: Double) {
        let numberOfStars: Int = Int(floor(rating))
        let halfStar = Double(numberOfStars) != rating
        let onStars = Int(min(5, numberOfStars + (halfStar ? 1 : 0)))
        for index in 0..<onStars {
            stars[index].image = UIImage(named: "star_white2")
        }
        
        if halfStar {
            stars[onStars-1].image = UIImage(named: "star_white1")
        }
        
        for index in onStars..<5 {
            stars[index].image = UIImage(named: "star_white0")
        }
    }
}
