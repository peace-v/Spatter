
//
// AppDelegate.swift
// Spatter
//
// Created by Molay on 15/12/5.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess

let keychain = Keychain()
let clientID = keychain["client_id"]
let clientSecret = keychain["client_secret"]
var likedPhotosArray: [Dictionary<String, String>] = [Dictionary<String, String>]()
var likedPhotoIDArray: NSMutableArray = []
var likedTotalItems = 0
var username = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
//    var totalItems = 0
//    var perItem = 30
//    var page = 1
//    var totalPages: Int {
//        get {
//            return Int(ceilf(Float(totalItems) / Float(perItem)))
//        }
//    }
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
        let cache = NSURLCache.sharedURLCache()
        cache.removeAllCachedResponses()
        
		if (!(NSUserDefaults.standardUserDefaults().boolForKey("firstLaunch"))) {
			NSUserDefaults.standardUserDefaults().setBool(false, forKey: "firstLaunch")
			NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isLogin")
			NSUserDefaults.standardUserDefaults().synchronize()
			keychain["client_id"] = "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d"
			keychain["client_secret"] = "915698939466b067ec1655727d1af0ce40ba717258f366200473969033a2ab5f"
		}
		
		if (NSUserDefaults.standardUserDefaults().boolForKey("isLogin")) {
//			Alamofire.request(.POST, "https://unsplash.com/oauth/token", parameters: [
//					"client_id": clientID!,
//					"client_secret": clientSecret!,
//					"refresh_token": keychain["refresh_token"]!,
//					"grant_type": "refresh_token"
//				]).validate().responseJSON(completionHandler: {response in
//					switch response.result {
//					case .Success:
//						if let value = response.result.value {
//							let json = JSON(value)
////							refreshToken = json["refresh_token"].stringValue
////							accessToken = json["access_token"].stringValue
//							keychain["refresh_token"] = json["refresh_token"].stringValue
//							keychain["access_token"] = json["access_token"].stringValue
//							
//							self.getLikedPhotoArray()
//						}
//					case .Failure(let error):
//						print(error)
//					}
//				})
//		}
		BaseNetworkRequest.getUsername()
        }
		return true
	}
	
	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
//	func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
	// print("the redirect uri is \(url)")
	// let urlString = url.absoluteString
	// if (urlString.containsString("code")) {
	// let urlArray = urlString.componentsSeparatedByString("=")
	// code = urlArray[1]
	// isLogin = true
	//
	// Alamofire.request(.POST, "https://unsplash.com/oauth/token", parameters: [
	// "client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d",
	// "client_secret": "915698939466b067ec1655727d1af0ce40ba717258f366200473969033a2ab5f",
	// "redirect_uri": "spatter://com.yuying.spatter",
	// "code": code,
	// "grant_type": "authorization_code"
	// ]).validate().responseJSON(completionHandler: {response in
	// switch response.result {
	// case .Success:
	// if let value = response.result.value {
	// let json = JSON(value)
	// refreshToken = json["refresh_token"].stringValue
	// accessToken = json["access_token"].stringValue
	// }
	// case .Failure(let error):
	// print(error)
	// }
	// })
	// }
	
//		let storyboard = UIStoryboard(name: "Main", bundle: nil)
	// let navController = storyboard.instantiateViewControllerWithIdentifier("navController")
	// self.window?.rootViewController = navController
	// self.window?.makeKeyAndVisible()
	//
	// return true
	// }
	
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
		if (sourceApplication == "com.apple.SafariViewService") {
			NSNotificationCenter.defaultCenter().postNotificationName("DismissSafariVC", object: url)
			return true
		}
		return true
	}
	
	// MARK: getLikedPhotoArray
//	func getLikedPhotoArray() {
//        print("get username")
//		Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
//				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
//				"client_id": clientID!
//			]).validate().responseJSON(completionHandler: {response in
//				switch response.result {
//				case .Success:
//					if let value = response.result.value {
//						let json = JSON(value)
//						// print("JSON:\(json)")
//						username = json["username"].stringValue
//						self.getLikedPhoto()
//					}
//				case .Failure(let error):
//					print(error)
//				}
//			})}
//	
//	func getLikedPhoto() {
//        print("get liked photos")
//		if (photoIDArray.count < self.totalItems || photoIDArray.count == 0) {
//			Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
//					"client_id": clientID!,
//					"page": self.page,
//					"per_page": self.perItem
//				]).validate().responseJSON(completionHandler: {response in
//					switch response.result {
//					case .Success:
//						if (self.page == 1) {
//							self.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
//						}
//						self.page += 1
//						if let value = response.result.value {
//							let json = JSON(value)
//							// print("JSON:\(json)")
//							if (json.count == 0) {
//								self.page -= 1
//								return
//							}
//							for (_, subJson): (String, JSON) in json {
//								var photoDic = Dictionary<String, String>()
//								photoDic["regular"] = subJson["urls"] ["regular"].stringValue
//								photoDic["small"] = subJson["urls"] ["small"].stringValue
//								photoDic["id"] = subJson["id"].stringValue
//								photoDic["download"] = subJson["links"] ["download"].stringValue
//								photoDic["name"] = subJson["user"] ["name"].stringValue
//								if (!photoIDArray.contains(subJson["id"].stringValue)) {
//									photoIDArray.append(subJson["id"].stringValue)
//									likedPhotosArray.append(photoDic)
//								}
//							}
//                            self.getLikedPhoto()
//						}
//					case .Failure(let error):
//						print(error)
//					}
//				})
//		} else {
//            print(photoIDArray)
//			return
//		}
//	}
}

