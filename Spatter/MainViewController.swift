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

let APPVERSION = "1.0"

class MainViewController: BaseTableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
	
	var viewControllers: [UIViewController] = []
	var isLogin: Bool = false
	var menuItemsAlreadyLogin: [RWDropdownMenuItem] = []
	var menuItemsWithoutLogin: [RWDropdownMenuItem] = []
	
	@IBAction func showMenu(sender: AnyObject) {
		if (isLogin) {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsAlreadyLogin, align: .Center, style: .Translucent, navBarImage: nil, completion: nil)
		} else {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsWithoutLogin, align: .Center, style: .Translucent, navBarImage: nil, completion: nil)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		// todo: tesing
		self.saveUserInfo()
		
		// init menuItem
		menuItemsAlreadyLogin = [
			RWDropdownMenuItem(text: "Profile", image: nil, action: {
					self.navigationController!.presentViewController(self.storyboard!.instantiateViewControllerWithIdentifier("profileNavController"), animated: true, completion: nil)
				}),
			RWDropdownMenuItem(text: "Logout", image: nil, action: nil),
			RWDropdownMenuItem(text: "Feedback", image: nil, action: {
					self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				})]
		
		menuItemsWithoutLogin = [
			
			// todo: used for testing
			RWDropdownMenuItem(text: "Profile", image: nil, action: {
					self.navigationController!.presentViewController(self.storyboard!.instantiateViewControllerWithIdentifier("profileNavController"), animated: true, completion: nil)
				}),
			RWDropdownMenuItem(text: "Login", image: nil, action: {
					self.openSafari()
				}),
			RWDropdownMenuItem(text: "Feedback", image: nil, action: {
					self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				})]
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
        
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(self.tableView,delay: 50.0)
        }
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: SFSafariViewControllerDelegate
	func openSafari() {
		if #available(iOS 9.0, *) {
			let svc = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user")!)
			svc.delegate = self
			self.presentViewController(svc, animated: true, completion: nil)
		} else {
			// Fallback on earlier versions
			UIApplication.sharedApplication().openURL(NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user")!)
		}
	}
	
	@available(iOS 9.0, *)
	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: PagingMenuControllerDelegate
	func willMoveToMenuPage(page: Int) {}
	
	func didMoveToMenuPage(page: Int) {
		let totalViewControllers = viewControllers.count - 1
		for num in 0...totalViewControllers {
			let currentViewController: UITableViewController = viewControllers[num] as! UITableViewController
			if num == page {
				currentViewController.tableView.scrollsToTop = true
			} else {
				currentViewController.tableView.scrollsToTop = false
			}
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
	
	// MARK: save userModel
	func saveUserInfo() {
		let avatarData = UIImageJPEGRepresentation(UIImage(named: "IMG_2184")!, 1.0)
		let userInfoArray: [AnyObject] = ["haru", avatarData!]
		NSKeyedArchiver.archiveRootObject(userInfoArray, toFile: UserModel.userModelFilePath)
	}
    
    // MARK: scrollingNavBar
    override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
        return true
    }
}
