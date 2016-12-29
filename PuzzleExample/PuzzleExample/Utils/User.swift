//
//  User.swift
//  PuzzleExample
//
//  Created by Yossi Avramov on 14/11/2016.
//  Copyright © 2016 Houzz. All rights reserved.
//

import Foundation
import CoreLocation

let user: User = {
    let path = Bundle.main.path(forResource: "Profile", ofType: "plist")!
    let myDict = NSDictionary(contentsOfFile: path)
    return User(dict: myDict as! [String:Any])
}()

class User {
    class var currentPro: User {
        return user
    }
    
    let profileImageUrl: URL
    let backgroundImageUrl: URL
    let aboutMe: String
    let location: CLLocation
    let projects: [Project]
    let followers: [Follower]
    let reviews: [Review]
    let photos: [URL]
    init(dict: [String:Any]) {
        profileImageUrl = URL(string: dict["ProfileImage"] as! String)!
        backgroundImageUrl = URL(string: dict["BackgroundImage"] as! String)!
        aboutMe = (dict["AboutMe"] as! String).replacingOccurrences(of: "\\n", with: "")
        
        let lat = dict["Latitude"] as! Double
        let lon = dict["Longitude"] as! Double
        location = CLLocation(latitude: lat, longitude: lon)
        
        projects = (dict["Projects"] as! [[String:String]]).map({ p -> Project in
            return Project(name: p["Name"]!, urlStr: p["Image"]!)
        })
        
        followers = (dict["Followers"] as! [[String:String]]).map({ p -> Follower in
            return Follower(name: p["Name"]!, urlStr: p["ProfileImage"]!)
        })
        
        reviews = (dict["Reviews"] as! [[String:Any]]).map({ p -> Review in
            return Review(userName: p["Name"] as! String, profileImageURLStr: p["ProfileImage"] as! String, comment: p["Comment"] as! String)
        })
        
        photos = (dict["Photos"] as! [String]).map({ p -> URL in
            return URL(string: p)!
        })
    }
}

struct Project {
    let name: String
    let url: URL
    
    init(name: String, urlStr: String) {
        self.name = name
        self.url = URL(string: urlStr)!
    }
}

struct Follower {
    let name: String
    let url: URL
    
    init(name: String, urlStr: String) {
        self.name = name
        self.url = URL(string: urlStr)!
    }
}

struct Review {
    let userName: String
    let profileImageURL: URL
    let comment: String
    init(userName: String, profileImageURLStr: String, comment: String) {
        self.userName = userName
        self.profileImageURL = URL(string: profileImageURLStr)!
        self.comment = comment
    }
}

