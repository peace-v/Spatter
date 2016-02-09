//
// BaseTableViewController.swift
// Spatter
//
// Created by Molay on 15/12/19.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class BaseTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
	
	let reuseIdentifier = "cell"
	var photosArray: [Dictionary<String, String>] = [Dictionary<String, String>]()
	var collcectionsArray: [Int] = []
	var successfullyGetJsonData = false
	var totalItems = 0
	var perItem = 1
	var page = 1
	var totalPages: Int {
		get {
			return Int(ceilf(Float(totalItems) / Float(perItem)))
		}
	}
	var footer = MJRefreshAutoNormalFooter()
	
	var somethingWentWrong = false
	var noData = false
	var exceedLimit = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.separatorStyle = .None
		
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.backgroundColor = UIColor.whiteColor()
		self.refreshControl!.tintColor = UIColor.blackColor()
		
		self.tableView.emptyDataSetSource = self;
		self.tableView.emptyDataSetDelegate = self;
        
        if !isConnectedInternet {
            self.tableView.reloadData()
        }
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
		SDImageCache.sharedImageCache().clearMemory()
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
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "noData:",
			name: "NoData",
			object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "CanAccessInternet", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "CanNotAccessInternet", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "ExceedRateLimit", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "ErrorOccur", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "NoData", object: nil)
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.successfullyGetJsonData {
			return self.photosArray.count
		}
		return 0
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
		
		// Configure the cell...
		cell.backgroundColor = UIColor.whiteColor()
		let imageView = cell.contentView.subviews[0] as! UIImageView
		imageView.contentMode = .ScaleAspectFill
		imageView.setIndicatorStyle(.Gray)
		imageView.setShowActivityIndicatorView(true)
		if self.successfullyGetJsonData {
			if (self.photosArray.count != 0) {
				imageView.sd_setImageWithURL(NSURL(string: self.photosArray[indexPath.row] ["small"]!))
			}
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return tableView.bounds.width / 1.5
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		// Remove separator inset
		if cell.respondsToSelector("setSeparatorInset:") {
			cell.separatorInset = UIEdgeInsetsZero
		}
		
		// Prevent the cell from inheriting the Table View's margin settings
		if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
			cell.preservesSuperviewLayoutMargins = false
		}
		
		// Explictly set your cell's layout margins
		if cell.respondsToSelector("setLayoutMargins:") {
			cell.layoutMargins = UIEdgeInsetsZero
		}
	}
	
	// MARK: DZEmptyDataSet Data Source
	func imageForEmptyDataSet(scrollView: UIScrollView) -> UIImage {
		if !isConnectedInternet {
			return UIImage(named: "wifi")!
		} else if somethingWentWrong {
			return UIImage(named: "error")!
		} else if exceedLimit {
			return UIImage(named: "coffee")!
		}
		return UIImage(named: "main-loading")!
	}
	
	func imageAnimationForEmptyDataSet(scrollView: UIScrollView) -> CAAnimation {
		let animation = CABasicAnimation(keyPath: "transform")
		animation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
		animation.toValue = NSValue(CATransform3D: CATransform3DMakeRotation(CGFloat(M_PI_2), 0.0, 0.0, 1.0))
		animation.duration = 0.25
		animation.cumulative = true
		animation.repeatCount = MAXFLOAT
		return animation
	}
	
	func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
		var text = ""
		if !isConnectedInternet {
			text = "Cannot connect to Internet"
		} else if somethingWentWrong {
			text = "Oops, something went wrong"
		} else if exceedLimit {
			text = "Sever has reached it's limit"
		} else {
			text = "Loading..."
		}
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
			NSForegroundColorAttributeName: UIColor.darkGrayColor()]
		return NSAttributedString(string: text, attributes: attributes)
	}
	
	func descriptionForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
		var text = ""
		if somethingWentWrong {
			text = "Please try agian"
		} else if exceedLimit {
			text = "Have a break and come back later"
		}
		let paragraph = NSMutableParagraphStyle()
		paragraph.lineBreakMode = .ByWordWrapping
		paragraph.alignment = .Center
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14.0),
			NSForegroundColorAttributeName: UIColor.lightGrayColor(),
			NSParagraphStyleAttributeName: paragraph]
		return NSAttributedString(string: text, attributes: attributes)
	}
	
	func buttonTitleForEmptyDataSet(scrollView: UIScrollView, forState state: UIControlState) -> NSAttributedString {
		var title = ""
		if (!isConnectedInternet || somethingWentWrong) {
			title = "Tap to refresh"
		}
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0)]
		return NSAttributedString(string: title, attributes: attributes)
	}
	
	func backgroundColorForEmptyDataSet(scrollView: UIScrollView) -> UIColor {
		return UIColor.whiteColor()
	}
	
	// MARK: DZEmptyDataSet Delegate
	func emptyDataSetShouldDisplay(scrollView: UIScrollView) -> Bool {
		return true
	}
	
	func emptyDataSetShouldAllowTouch(scrollView: UIScrollView) -> Bool {
		return true
	}
	
	func emptyDataSetShouldAllowScroll(scrollView: UIScrollView) -> Bool {
		return true
	}
	
	func emptyDataSetShouldAllowImageViewAnimate(scrollView: UIScrollView) -> Bool {
		return true
	}
	
	func emptyDataSetDidTapButton(scrollView: UIScrollView) {
	}
	
	// MARK: notification function
	func accessInternet(notification: NSNotification) {
		isConnectedInternet = true
	}
	
	func cannotAccessInternet(notification: NSNotification) {
		isConnectedInternet = false
		if (self.photosArray.count == 0) {
			self.tableView.reloadData()
		} else {
			let alert = UIAlertController(title: "Cannot connect to Internet", message: "Pull down to refresh", preferredStyle: .Alert)
			let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
			alert.addAction(ok)
            self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	func exceedLimit(notification: NSNotification) {
        exceedLimit = true
		if (self.photosArray.count == 0) {
			self.tableView.reloadData()
		} else {
            let alert = UIAlertController(title: "Server has reached it's limit", message: "Have a break and come back later", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alert.addAction(ok)
            self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	func somethingWentWrong(notification: NSNotification) {
        somethingWentWrong = true
        if (self.photosArray.count == 0) {
            self.tableView.reloadData()
        } else {
            let alert = UIAlertController(title: "Oops, something went wrong", message: "Pull down to refresh", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alert.addAction(ok)
            self.presentViewController(alert, animated: true, completion: nil)
        }
	}
	
	func noData(notification: NSNotification) {
		noData = true
        if (self.photosArray.count != 0){
            self.photosArray = []
        }
        self.tableView.reloadData()
	}
}

