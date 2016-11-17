//
//  AsyncImageView.swift
//  PuzzleExample
//
//  Created by Yossi houzz on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import UIKit
import CoreLocation

class AsyncImageView : UIImageView {
    private var canUsePlaceholder: Bool = true
    private var currentTask: URLSessionTask?
    private var timer: Timer?
    private var location: CLLocation?
    private var url: URL? {
        willSet {
            invalidateTimer()
            currentTask?.cancel()
            canUsePlaceholder = true
        }
        didSet {
            if let url = url {
                currentTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    DispatchQueue.main.async { [weak self] in
                        self?.didDownload(data: data, error: error, forURL: url)
                    }
                })
                
                currentTask!.resume()
            }
        }
    }
    
    override var image: UIImage? {
        get {
            return super.image
        }
        set {
            canUsePlaceholder = newValue != nil
            super.image = newValue
        }
    }
    
    private func didDownload(data: Data?, error: Error?, forURL url: URL) {
        guard self.url == url else {
            return
        }
        
        if let data = data , let image = UIImage(data: data) {
            canUsePlaceholder = false
            super.image = image
        }
        else {
            canUsePlaceholder = true
            print("\(error)")
            startRetryTimer()
        }
    }
    
    private func startRetryTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(AsyncImageView.retry(_:)), userInfo: nil, repeats: false)
    }
    
    private func invalidateTimer () {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func retry(_ ti: Timer) {
        invalidateTimer()
        let url = self.url
        self.url = url
    }
    
    func clear() {
        self.location = nil
        self.url = nil
    }
    
    func setImage(forURL url: URL) {
        self.location = nil
        self.url = url
    }
    
    func setImage(forLocation location: CLLocation) {
        self.location = location
        let coord = location.coordinate
        self.url = URL(string: "https://maps.googleapis.com/maps/api/staticmap?center=\(coord.latitude),\(coord.longitude)&zoom=13&size=\(Int(ceil(bounds.width * 2)))x\(Int(ceil((bounds.height + 100) * 2)))")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let location = location {
            self.setImage(forLocation: location)
        }
    }
    
    var placeholder: UIImage? {
        didSet {
            if canUsePlaceholder {
                super.image = placeholder
            }
        }
    }
}

private let cache = NSCache<NSString, AnyObject>()
class MyCache {
    class func image(forURL url: URL) -> UIImage? {
        return image(forKey: url.relativePath)
    }
    
    class func image(forKey key: String) -> UIImage? {
        if let data = cache.object(forKey: key as NSString) as? Data {
            return UIImage(data: data)
        }
        else { return nil }
    }
    
    class func setImage(_ img: UIImage, forURL url: URL) {
        setImage(img, forKey: url.relativePath)
    }
    
    class func setImage(_ img: UIImage, forKey key: String) {
        guard let data = UIImagePNGRepresentation(img) else {
            return
        }
        
        cache.setObject(data as AnyObject, forKey: key as NSString)
    }
}
