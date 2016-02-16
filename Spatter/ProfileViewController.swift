//
// ProfileViewController.swift
// Spatter
//
// Created by Molay on 15/12/9.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import PagingMenuController
import Alamofire
import SwiftyJSON
import KeychainAccess

class ProfileViewController: UIViewController, PagingMenuControllerDelegate {
	
	var viewControllers: [UIViewController] = []
    var somethingWrong = false
	
	@IBOutlet weak var userLabel: UILabel!
	@IBOutlet weak var avatar: UIImageView!
	@IBOutlet weak var backBtn: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
        if (keychain["access_token"] != nil) {
		BaseNetworkRequest.loadProfile(self)
        }
		
		avatar.layer.masksToBounds = true
		let avatarWidth = CGFloat(44.0)
		avatar.layer.cornerRadius = avatarWidth / 2
		
		// add pagingMenu
		let likedTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("liked") as! LikedTableViewController
		likedTableViewController.title = NSLocalizedString("Like", comment: "")
		let postTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("post") as! PostTableViewController
		postTableViewController.title = NSLocalizedString("Post", comment: "")
		viewControllers = [likedTableViewController, postTableViewController]
		
		let pagingMenuController = self.childViewControllers.first as! PagingMenuController
		
		let options = PagingMenuOptions()
		options.menuHeight = 44
		options.menuDisplayMode = .SegmentedControl
		options.defaultPage = 0
		options.menuItemMode = .Underline(height: 3, color: UIColor.blackColor(), horizontalPadding: 0, verticalPadding: 5)
		pagingMenuController.setup(viewControllers: viewControllers, options: options)
		
		pagingMenuController.delegate = self
		
		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: "screenEdgeSwiped:")
		edgePan.edges = .Left
		view.addGestureRecognizer(edgePan)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "accessInternet:",
			name: "CanAccessInternet",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "cannotAccessInternet:",
			name: "CanNotAccessInternet",
			object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "exceedLimit:",
            name: "ExceedRateLimit",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "somethingWentWrong:",
            name: "ErrorOccur",
            object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "CanAccessInternet", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "CanNotAccessInternet", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ExceedRateLimit", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ErrorOccur", object: nil)
	}
	
// MARK: swipe back
	func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .Recognized) {
			self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
// MARK: PagingMenuControllerDelegate
	func willMoveToMenuPage(page: Int) {
		
	}
	
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
	
	// MARK: notification function
	func accessInternet(notification: NSNotification) {
		isConnectedInternet = true
		BaseNetworkRequest.loadProfile(self)
	}
	
	func cannotAccessInternet(notification: NSNotification) {
		isConnectedInternet = false
	}
    
    func exceedLimit(notification: NSNotification) {
        isConnectedInternet = true
        reachLimit = true
        somethingWrong = false
            let alert = UIAlertController(title: NSLocalizedString("Server has reached it's limit", comment: ""), message: NSLocalizedString("Have a break and come back later", comment: ""), preferredStyle: .Alert)
            let ok = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .Default, handler: nil)
            alert.addAction(ok)
            self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func somethingWentWrong(notification: NSNotification) {
        isConnectedInternet = true
        somethingWrong = true
        reachLimit = false
            let alert = UIAlertController(title: NSLocalizedString("Oops, something went wrong", comment: ""), message: NSLocalizedString("Please try again", comment: ""), preferredStyle: .Alert)
            let ok = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .Default, handler: nil)
            alert.addAction(ok)
            self.presentViewController(alert, animated: true, completion: nil)
        }
}
