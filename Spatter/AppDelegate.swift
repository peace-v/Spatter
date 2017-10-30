
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
var avatarURL = ""

var isConnectedInternet = true
var reachLimit = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var reach: TMReachability?
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
        // set userDefailts when first launch
		if (!(UserDefaults.standard.bool(forKey: "notFirstLaunch"))) {
			UserDefaults.standard.set(true, forKey: "notFirstLaunch")
			UserDefaults.standard.set(false, forKey: "isLogin")
			UserDefaults.standard.synchronize()
			keychain["client_id"] = "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d"
			keychain["client_secret"] = "915698939466b067ec1655727d1af0ce40ba717258f366200473969033a2ab5f"
		}
		
		if (UserDefaults.standard.bool(forKey: "isLogin")) {
            if (keychain["access_token"] != nil) {
			BaseNetworkRequest.loadProfile()
            }
		}
		
		reach = TMReachability.forInternetConnection()
		reach!.reachableOnWWAN = false
		NotificationCenter.default.addObserver(self,
			selector: #selector(AppDelegate.reachabilityChanged(_:)),
			name: NSNotification.Name.reachabilityChanged,
			object: nil)
		reach!.startNotifier()
        
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
		if (sourceApplication == "com.apple.SafariViewService") {
			NotificationCenter.default.post(name: Notification.Name(rawValue: "DismissSafariVC"), object: url)
			return true
		}
		return true
	}
	
	// MARK: TMReachability notification
    
	@objc func reachabilityChanged(_ notification: Notification) {
		if reach!.isReachableViaWiFi() || reach!.isReachableViaWWAN() {
//            print("connected")
			NotificationCenter.default.post(name: Notification.Name(rawValue: "CanAccessInternet"), object: nil)
		} else {
//            print("not connected")
			NotificationCenter.default.post(name: Notification.Name(rawValue: "CanNotAccessInternet"), object: nil)
		}
	}
}

