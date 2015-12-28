//
// UserModel.swift
// Spatter
//
// Created by Molay on 15/12/28.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit

class UserModel: NSObject, NSCoding {
    
    static let userModelFilePath = ((NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) [0]) as NSString).stringByAppendingPathComponent("user.data")
//    static var user:NSMutableArray?
    
    var name: NSString!
    var avatar: NSData?
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(self.name, forKey: "name")
		aCoder.encodeObject(self.avatar, forKey: "avatar")
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init()
		self.name = aDecoder.decodeObjectForKey("name") as! NSString
		self.avatar = aDecoder.decodeObjectForKey("avatar") as? NSData
	}
	
	override init() {}
}
