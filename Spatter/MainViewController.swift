//
//  MainViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/8.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import SafariServices
import PagingMenuController
import MessageUI

let APPVERSION = "1.0"

class MainViewController: UIViewController, SFSafariViewControllerDelegate, PagingMenuControllerDelegate, MFMailComposeViewControllerDelegate {

	var viewControllers: [UIViewController] = []
	var isLogin: Bool = false
	var menuItemsAlreadyLogin: [RWDropdownMenuItem] = []
	var menuItemsWithoutLogin: [RWDropdownMenuItem] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		// init paging menu
		let dailyTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("daily") as! DailyTableViewController
		dailyTableViewController.title = "Daily"
		let buildingsTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("buildings") as! BuildingsTableViewController
		buildingsTableViewController.title = "Buildings"
		let foodTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("food") as! FoodTableViewController
		foodTableViewController.title = "Food"
		let natureTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("nature") as! NatureTableViewController
		natureTableViewController.title = "Nature"
		let peopleTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("people") as! PeopleTableViewController
		peopleTableViewController.title = "People"
		let technologyTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("technology") as! TechnologyTableViewController
		technologyTableViewController.title = "Technology"
		let objectsTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("objects") as! ObjectsTableViewController
		objectsTableViewController.title = "Objects"
		//        let viewControllers = [dailyTableViewController,buildingsTableViewController,foodTableViewController,natureTableViewController,peopleTableViewController,technologyTableViewController,objectsTableViewController]
		viewControllers = [dailyTableViewController, buildingsTableViewController, foodTableViewController, natureTableViewController, peopleTableViewController, technologyTableViewController, objectsTableViewController]

		let pagingMenuController = self.childViewControllers.first as! PagingMenuController

		let options = PagingMenuOptions()
		options.menuHeight = 44
		options.menuDisplayMode = .Infinite(widthMode: .Flexible)
		options.defaultPage = 0
		options.scrollEnabled = true
		options.menuItemMode = .Underline(height: 3, color: UIColor.orangeColor(), horizontalPadding: 0, verticalPadding: 0)
		pagingMenuController.setup(viewControllers: viewControllers, options: options)

		pagingMenuController.delegate = self

        // init menuItem
        menuItemsAlreadyLogin = [
        RWDropdownMenuItem(text: "Profile", image: nil, action: nil),
        RWDropdownMenuItem(text: "Logout", image: nil, action: nil),
        RWDropdownMenuItem(text: "Feedback", image: nil, action:{
        self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
        })]
        
        menuItemsWithoutLogin = [
        RWDropdownMenuItem(text: "Login", image: nil, action: nil),
        RWDropdownMenuItem(text: "Feedback", image: nil, action: {
        self.sendFeedback("【反馈】Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
        })]
	}

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController!.navigationBarHidden = false
    }
    
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func showMenu(sender: AnyObject) {
		if (isLogin) {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsAlreadyLogin, align: .Center, style: .Translucent, navBarImage: nil, completion: nil)
		} else {
			RWDropdownMenu.presentFromViewController(self, withItems: menuItemsWithoutLogin, align: .Center, style: .Translucent, navBarImage: nil, completion: nil)
		}
	}

	@IBAction func openSafari(sender: AnyObject) {
		if #available(iOS 9.0, *) {
			let svc = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user")!)
			svc.delegate = self
			self.presentViewController(svc, animated: true, completion: nil)
		} else {
			// Fallback on earlier versions
			UIApplication.sharedApplication().openURL(NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user")!)
		}
	}

	//MARK: SFSafariViewControllerDelegate
	@available(iOS 9.0, *)
	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

	//MARK: PagingMenuControllerDelegate
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

	//MARK: MFMailComposeViewControllerDelegate
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
}
