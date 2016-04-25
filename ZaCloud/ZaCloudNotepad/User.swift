//
//  user.swift
//  ZaCloudNotepad
//
//  Created by Zachary Kanzhe Liu on 2016-01-31.
//  Copyright © 2016 Zachary Kanzhe Liu. All rights reserved.
//

import Foundation


class User : NSObject, NSCoding {
    var username:NSString!
    
    
    init(name:String){
        username = name as NSString
        
    }

    required convenience init?(coder decoder: NSCoder){
        
        guard let username = decoder.decodeObjectForKey("username") as? NSString
            else {
                print("decoding failure from sync date")
                return nil }
        
        self.init(
            name:username as String
            
        )
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.username, forKey: "username")
        
    }
    


}