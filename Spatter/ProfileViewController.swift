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

var username = ""

class ProfileViewController: UIViewController, PagingMenuControllerDelegate {
	
	var viewControllers: [UIViewController] = []
	
    @IBOutlet weak var userLabel: UILabel!
	@IBOutlet weak var avatar: UIImageView!
	@IBOutlet weak var backBtn: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
//						print("JSON:\(json)")
						dispatch_async(dispatch_get_main_queue()) {
							self.avatar.sd_setImageWithURL(NSURL(string: json["profile_image"] ["medium"].stringValue))
                            username = json["username"].stringValue
                            self.userLabel.text = username
                            if (!username.isEmpty) {
                                NSNotificationCenter.defaultCenter().postNotificationName("LoadLikedPhotos", object: nil)
                                NSNotificationCenter.defaultCenter().postNotificationName("LoadPostPhotos", object: nil)
                            }
						}
					}
				case .Failure(let error):
					print(error)
				}
			})
		
		avatar.layer.masksToBounds = true
		let avatarWidth = CGFloat(44.0)
		avatar.layer.cornerRadius = avatarWidth / 2
		
		// add pagingMenu
		let likedTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("liked") as! LikedTableViewController
		likedTableViewController.title = "Like"
		let postTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("post") as! PostTableViewController
		postTableViewController.title = "Post"
		viewControllers = [likedTableViewController, postTableViewController]
		
		let pagingMenuController = self.childViewControllers.first as! PagingMenuController
		
		let options = PagingMenuOptions()
		options.menuHeight = 44
		options.menuDisplayMode = .SegmentedControl
		options.defaultPage = 0
		options.menuItemMode = .Underline(height: 3, color: UIColor.orangeColor(), horizontalPadding: 0, verticalPadding: 5)
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
	
}
