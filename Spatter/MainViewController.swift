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

let APPVERSION:String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String

class MainViewController: BaseTableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
	
	var menuItemsAlreadyLogin: [RWDropdownMenuItem] = []
	var menuItemsWithoutLogin: [RWDropdownMenuItem] = []
	var safariVC: SFSafariViewController?
	let aboutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("about")
	
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
        // configure refreshControl
        self.refreshControl!.addTarget(self, action: #selector(MainViewController.refreshData), forControlEvents: .ValueChanged)
        footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(MainViewController.getCollections))
        footer.refreshingTitleHidden = true
        self.tableView.mj_footer = footer
        
		// init menuItem
		menuItemsAlreadyLogin = [
			RWDropdownMenuItem(text: NSLocalizedString("Profile",comment:""), image: nil, action: {
					self.navigationController!.presentViewController(self.storyboard!.instantiateViewControllerWithIdentifier("profileNavController"), animated: true, completion: nil)
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Logout", comment: ""), image: nil, action: {
                MainViewController.logout()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Clear Cache", comment: ""), image: nil, action: {
					SDImageCache.sharedImageCache().clearDisk()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Feedback", comment: ""), image: nil, action: {
					self.sendFeedback("Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				}),
			RWDropdownMenuItem(text: NSLocalizedString("About", comment: ""), image: nil, action: {
					self.presentViewController(self.aboutVC, animated: true, completion: nil)
				})]
		
		menuItemsWithoutLogin = [
			RWDropdownMenuItem(text: NSLocalizedString("Login", comment: ""), image: nil, action: {
					self.openSafari()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Clear Cache", comment: ""), image: nil, action: {
					SDImageCache.sharedImageCache().clearDisk()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Feedback", comment: ""), image: nil, action: {
					self.sendFeedback("Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				}),
			RWDropdownMenuItem(text: NSLocalizedString("About", comment: ""), image: nil, action: {
					self.presentViewController(self.aboutVC, animated: true, completion: nil)
				})]
		
		BaseNetworkRequest.getCollections(self)
        
        // check the network condition when launch
        let reach = TMReachability.reachabilityForInternetConnection()
        reach!.reachableOnWWAN = false
		reach!.startNotifier()
        if reach!.isReachableViaWiFi() || reach!.isReachableViaWWAN() {
            isConnectedInternet = true
        }else {
            isConnectedInternet = false
            if (self.photosArray.count == 0) {
                self.tableView.reloadData()
            }
        }
        reach!.stopNotifier()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.followScrollView(self.tableView, delay: 50.0)
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.oauthUser(_:)), name: "DismissSafariVC", object: nil)
        
        // configure the statusbar notification
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
			detailViewController.configureData(self.photosArray,withIndex: (indexPath?.row)!)
		}
	}
	
    // MARK: safari
	func openSafari() {
		safariVC = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=\(clientID!)&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		safariVC!.delegate = self
		self.presentViewController(safariVC!, animated: true, completion: nil)
	}
	
	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func oauthUser(notification: NSNotification) {
		BaseNetworkRequest.oauth(notification, vc:self)
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
			let alert = UIAlertController(title: NSLocalizedString("Cannot sent email", comment: ""), message: NSLocalizedString("Please check the system email setting", comment: ""), preferredStyle: .Alert)
			let ok = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: nil)
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
    
    // MARK: refresh methods    
    func getCollections() {
        BaseNetworkRequest.getCollections(self)
    }
    
    func refreshData() {
        self.collcectionsArray = []
        self.photosArray = []
        self.page = 1
        let cache = NSURLCache.sharedURLCache()
        cache.removeAllCachedResponses()
        BaseNetworkRequest.getCollections(self)
    }
    
    // MARK: DZEmptyDataSet
    override func verticalOffsetForEmptyDataSet(scrollView: UIScrollView) -> CGFloat {
        let top = scrollView.contentInset.top
        return top - 44
    }
    
    // MARK: help function
    class func logout() {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isLogin")
        NSUserDefaults.standardUserDefaults().synchronize()
        keychain["access_token"] = nil
        keychain["refresh"] = nil
        likedPhotoIDArray = []
        likedPhotosArray = []
        likedTotalItems = 0
        username = ""
        avatarURL = ""
    }
    
    
    // MARK: network notificaiton
    override func accessInternet(notification: NSNotification) {
        isConnectedInternet = true
        self.tableView.reloadData()
        if (self.photosArray.count == 0){
        BaseNetworkRequest.getCollections(self)
        }
    }
}
