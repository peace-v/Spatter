//
// MainViewController.swift
// Spatter
//
// Created by Molay on 15/12/8.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI
import AMScrollingNavbar
import Alamofire
import SwiftyJSON

let APPVERSION = "1.0"

class MainViewController: BaseTableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
	
	var viewControllers: [UIViewController] = []
	var menuItemsAlreadyLogin: [RWDropdownMenuItem] = []
	var menuItemsWithoutLogin: [RWDropdownMenuItem] = []
	var safariVC: SFSafariViewController?
	let aboutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("about")
//    var code = ""
//    var likedTotalItems = 0
//    var likedPerItem = 30
//    var likedPage = 1
//    var likedTotalPages: Int {
//        get {
//            return Int(ceilf(Float(totalItems) / Float(perItem)))
//        }
//    }
	
	@IBAction func showMenu(sender: AnyObject) {
		if (NSUserDefaults.standardUserDefaults().boolForKey("isLogin")) {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsAlreadyLogin, align: .Center, style: .BlackGradient, navBarImage: nil, completion: nil)
		} else {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsWithoutLogin, align: .Center, style: .BlackGradient, navBarImage: nil, completion: nil)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.tableView.separatorStyle = .None
		
		// init menuItem
		menuItemsAlreadyLogin = [
			RWDropdownMenuItem(text: "Profile", image: nil, action: {
					self.navigationController!.presentViewController(self.storyboard!.instantiateViewControllerWithIdentifier("profileNavController"), animated: true, completion: nil)
				}),
			RWDropdownMenuItem(text: "Logout", image: nil, action: {
					NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isLogin")
					NSUserDefaults.standardUserDefaults().synchronize()
//					isLogin = false
					keychain["access_token"] = nil
					keychain["refresh"] = nil
					likedPhotoIDArray = []
					likedPhotosArray = []
					likedTotalItems = 0
					username = ""
				}),
			RWDropdownMenuItem(text: "Clear Cache", image: nil, action: {
					SDImageCache.sharedImageCache().clearDisk()
				}),
			RWDropdownMenuItem(text: "Feedback", image: nil, action: {
					self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				}),
			RWDropdownMenuItem(text: "About", image: nil, action: {
					self.presentViewController(self.aboutVC, animated: true, completion: nil)
				})]
		
		menuItemsWithoutLogin = [
			RWDropdownMenuItem(text: "Login", image: nil, action: {
					self.openSafari()
				}),
			RWDropdownMenuItem(text: "Clear Cache", image: nil, action: {
					SDImageCache.sharedImageCache().clearDisk()
				}),
			RWDropdownMenuItem(text: "Feedback", image: nil, action: {
					self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				}),
			RWDropdownMenuItem(text: "About", image: nil, action: {
					self.presentViewController(self.aboutVC, animated: true, completion: nil)
				})]
		
		// configure tableView
//		 self.getCollections()
		BaseNetworkRequest.getCollections(self)
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.followScrollView(self.tableView, delay: 50.0)
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "oauthUser:", name: "DismissSafariVC", object: nil)
        
        JDStatusBarNotification.setDefaultStyle { (JDStatusBarStyle) -> JDStatusBarStyle! in
            JDStatusBarStyle.barColor = UIColor.whiteColor()
            JDStatusBarStyle.textColor = UIColor.blackColor()
            return JDStatusBarStyle
        }
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.stopFollowingScrollView()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "DismissSafariVC", object: nil)
	}
	
	// MARK: tableView delegate
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if (segue.identifier == "showFeaturedPhoto") {
			let detailViewController = segue.destinationViewController as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPathForCell(cell!)
			detailViewController.downloadURL = self.photosArray[indexPath!.row] ["regular"]!
			detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
			detailViewController.photoID = self.photosArray[indexPath!.row] ["id"]!
		}
	}
	
	// MARK: SFSafariViewControllerDelegate
	// func openSafari() {
	// if #available(iOS 9.0, *) {
	// let svc = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
	// svc.delegate = self
	// self.presentViewController(svc, animated: true, completion: nil)
	// } else {
	// // Fallback on earlier versions
	// UIApplication.sharedApplication().openURL(NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
	// }
	// }
	//
	// @available(iOS 9.0, *)
	// func safariViewControllerDidFinish(controller: SFSafariViewController) {
	// controller.dismissViewControllerAnimated(true, completion: nil)
	// }
	
	func openSafari() {
		safariVC = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=\(clientID!)&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		safariVC!.delegate = self
		self.presentViewController(safariVC!, animated: true, completion: nil)
	}
	
	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: handle callback after oauth
	func oauthUser(notification: NSNotification) {
//		let url = notification.object as! NSURL
//		let urlString = url.absoluteString
//		if (urlString.containsString("code")) {
//			let urlArray = urlString.componentsSeparatedByString("=")
//			code = urlArray[1]
//            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isLogin")
//            NSUserDefaults.standardUserDefaults().synchronize()
////			isLogin = true
//
////			Alamofire.request(.POST, "https://unsplash.com/oauth/token", parameters: [
////					"client_id": clientID!,
////					"client_secret": clientSecret!,
////					"redirect_uri": "spatter://com.yuying.spatter",
////					"code": code,
////					"grant_type": "authorization_code"
////				]).validate().responseJSON(completionHandler: {response in
////					switch response.result {
////					case .Success:
////						if let value = response.result.value {
////							let json = JSON(value)
////							keychain["refresh_token"] = json["refresh_token"].stringValue
////							keychain["access_token"] = json["access_token"].stringValue
////                            self.getLikedPhotoArray()
////						}
////					case .Failure(let error):
////						print(error)
////					}
////				})
//
//		}
		BaseNetworkRequest.oauth(notification)
		if (self.safariVC != nil) {
			self.safariVC!.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	// MARK: MFMailComposeViewControllerDelegate
	func sendFeedback(subject: String, recipients: [String], appVersion: String) {
		if (MFMailComposeViewController.canSendMail()) {
			let picker = MFMailComposeViewController()
			picker.mailComposeDelegate = self
			picker.setSubject(subject)
			picker.setToRecipients(recipients)
			let iOSVersion = UIDevice.currentDevice().systemVersion
			let deviceModal = UIDevice.currentDevice().model
			let body = "App version: \(appVersion)\niOS version: \(iOSVersion)\nDevice modal: \(deviceModal)\n"
			picker.setMessageBody(body, isHTML: false)
			self.presentViewController(picker, animated: true, completion: nil)
		} else {
			let alert = UIAlertController(title: "Cannot sent email", message: "Please check the system email setting", preferredStyle: .Alert)
			let ok = UIAlertAction(title: "OK", style: .Default, handler: nil)
			alert.addAction(ok)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: scrollingNavBar
	override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.showNavbar(animated: true)
		}
		return true
	}
	
	// MARK: getLikedPhotoArray
//    func getLikedPhotoArray() {
//        print("get username")
//        Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
//            "Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
//                "client_id": clientID!
//            ]).validate().responseJSON(completionHandler: {response in
//                switch response.result {
//                case .Success:
//                    if let value = response.result.value {
//                        let json = JSON(value)
//                        // print("JSON:\(json)")
//                        username = json["username"].stringValue
//                        self.getLikedPhoto()
//                    }
//                case .Failure(let error):
//                    print(error)
//                }
//            })}
//
//    func getLikedPhoto() {
//        print("get liked photos")
//        if (photoIDArray.count < self.likedTotalItems || photoIDArray.count == 0) {
//            Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
//                "client_id": clientID!,
//                "page": self.likedPage,
//                "per_page": self.likedPerItem
//                ]).validate().responseJSON(completionHandler: {response in
//                    switch response.result {
//                    case .Success:
//                        if (self.likedPage == 1) {
//                            self.likedTotalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
//                        }
//                        self.likedPage += 1
//                        if let value = response.result.value {
//                            let json = JSON(value)
//                            // print("JSON:\(json)")
//                            if (json.count == 0) {
//                                self.likedPage -= 1
//                                return
//                            }
//                            for (_, subJson): (String, JSON) in json {
//                                var photoDic = Dictionary<String, String>()
//                                photoDic["regular"] = subJson["urls"] ["regular"].stringValue
//                                photoDic["small"] = subJson["urls"] ["small"].stringValue
//                                photoDic["id"] = subJson["id"].stringValue
//                                photoDic["download"] = subJson["links"] ["download"].stringValue
//                                photoDic["name"] = subJson["user"] ["name"].stringValue
//                                if (!photoIDArray.contains(subJson["id"].stringValue)) {
//                                    photoIDArray.append(subJson["id"].stringValue)
//                                    likedPhotosArray.append(photoDic)
//                                }
//                            }
//                            self.getLikedPhoto()
//                        }
//                    case .Failure(let error):
//                        print(error)
//                    }
//                })
//        } else {
//            print(photoIDArray)
//            return
//        }
//    }
}
