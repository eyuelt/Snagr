//
//  Song.swift
//  Snagr
//
//  Created by Eyuel Tessema on 2/28/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

import Foundation

class Song {
    var title: String!
    var artist: String!
    var timePlayed: NSDate!
    var status: String!
    
    init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
    
    init(propertyList: AnyObject) {
        let dict = propertyList as [String:String]
        title = dict["title"]
        artist = dict["artist"]
        timePlayed = dateFromString(dict["timePlayed"]!)
        status = dict["status"]
    }
    
    var propertyList: [String:String] {
        var dict = [String:String]()
        dict["title"] = title
        dict["artist"] = artist
        dict["timePlayed"] = stringFromDate(timePlayed)
        dict["status"] = status
        return dict
    }
    
    let DateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    
    func stringFromDate(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = DateFormat
        return formatter.stringFromDate(date)
    }
    
    func dateFromString(str: String) -> NSDate? {
        let formatter = NSDateFormatter()
        formatter.dateFormat = DateFormat
        return formatter.dateFromString(str)
    }
}