//
//  Note.swift
//  ZaCloudNotepad
//
//  Created by Zachary Kanzhe Liu on 2016-01-31.
//  Copyright © 2016 Zachary Kanzhe Liu. All rights reserved.
//

import Foundation

class Note: NSObject, NSCoding {
    
    var title:NSString!
    var note:NSString!
    var lastModified:NSDate!
    var createDate:NSDate!
    var author:NSString!
   // var locked:Bool
    var lockingTime:NSDate!
    var updateDevice:NSString!
    
    
    init(title:String, noteText:String, author:String) {
        self.title = title as NSString
        self.note = noteText as NSString
        self.author = author as NSString
        lastModified = NSDate()
        
        if(createDate == nil){
            createDate = lastModified
        }
        
       // locked = false
    }
    
    
    override init(){
        self.title = "" as NSString
        self.note = "" as NSString
        self.author = "" as NSString
        lastModified = NSDate()
        
        if(createDate == nil){
            createDate = lastModified
        }
        
       // locked = false
    }

    
    
    init(title:NSString, note:NSString, author:NSString, createDate:NSDate, lastModified:NSDate) {
        self.title = title
        self.note = note
        self.author = author
        self.createDate = createDate
        self.lastModified = lastModified
        
       
        
        
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard let title = decoder.decodeObjectForKey("title") as? NSString,
            let author = decoder.decodeObjectForKey("author") as? NSString,
            let note = decoder.decodeObjectForKey("note") as? NSString,
            let createDate = decoder.decodeObjectForKey("createDate") as? NSDate,
            let lastModified = decoder.decodeObjectForKey("lastModified") as? NSDate
        
        
        
            else {
                print("decoding failure from note")
                return nil }
        
        self.init(
            title: title,
            note: note,
            author: author,
            createDate: createDate,
            lastModified:lastModified
        )
    }
    
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.title, forKey: "title")
        coder.encodeObject(self.author, forKey: "author")
        coder.encodeObject(self.note, forKey: "note")
        coder.encodeObject(self.createDate, forKey: "createDate")
        coder.encodeObject(self.lastModified, forKey: "lastModified")
        
        
        
    }
    
   }