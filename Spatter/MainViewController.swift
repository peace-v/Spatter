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
var code = ""
var refreshToken = ""
var accessToken = ""
var isLogin = false

class MainViewController: BaseTableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
	
	var viewControllers: [UIViewController] = []
	var menuItemsAlreadyLogin: [RWDropdownMenuItem] = []
	var menuItemsWithoutLogin: [RWDropdownMenuItem] = []
	var safariVC: SFSafariViewController?
	
	@IBAction func showMenu(sender: AnyObject) {
		if (isLogin) {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsAlreadyLogin, align: .Center, style: .White, navBarImage: nil, completion: nil)
		} else {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsWithoutLogin, align: .Center, style: .White, navBarImage: nil, completion: nil)
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
					isLogin = false
					accessToken = ""
				}),
			RWDropdownMenuItem(text: "Clear Cache", image: nil, action: {
					SDImageCache.sharedImageCache().clearDisk()
				}),
			RWDropdownMenuItem(text: "Feedback", image: nil, action: {
					self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
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
				})]
		
		// configure tableView
		// self.getCollections()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.followScrollView(self.tableView, delay: 50.0)
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "oauthUser:", name: "DismissSafariVC", object: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	deinit {
        print("destory the observer")
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
		safariVC = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		safariVC!.delegate = self
		self.presentViewController(safariVC!, animated: true, completion: nil)
	}
	
	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: handle callback after oauth
	func oauthUser(notification: NSNotification) {
		print("received notification")
		let url = notification.object as! NSURL
		let urlString = url.absoluteString
		if (urlString.containsString("code")) {
			let urlArray = urlString.componentsSeparatedByString("=")
			code = urlArray[1]
			isLogin = true
			
			Alamofire.request(.POST, "https://unsplash.com/oauth/token", parameters: [
					"client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d",
					"client_secret": "915698939466b067ec1655727d1af0ce40ba717258f366200473969033a2ab5f",
					"redirect_uri": "spatter://com.yuying.spatter",
					"code": code,
					"grant_type": "authorization_code"
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						if let value = response.result.value {
							let json = JSON(value)
							refreshToken = json["refresh_token"].stringValue
							accessToken = json["access_token"].stringValue
						}
					case .Failure(let error):
						print(error)
					}
				})
		}
		
		self.safariVC!.dismissViewControllerAnimated(true, completion: nil)
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
}
