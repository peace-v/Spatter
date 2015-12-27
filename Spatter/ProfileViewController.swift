//
// ProfileViewController.swift
// Spatter
//
// Created by Molay on 15/12/9.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import PagingMenuController

class ProfileViewController: UIViewController, PagingMenuControllerDelegate {
	
	var viewControllers: [UIViewController] = []
	
	@IBOutlet weak var avatar: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		avatar.image = UIImage(named: "placeholder")
		
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
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func back(sender: AnyObject) {
		self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
	}
	
	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using segue.destinationViewController.
	 // Pass the selected object to the new view controller.
	 }
	 */
	
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
