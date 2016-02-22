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
import PKHUD

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
	var noData = false
    var somethingWrong = false

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
		} else if reachLimit {
			return UIImage(named: "coffee")!
		} else if somethingWrong {
			return UIImage(named: "error")!
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
			text = NSLocalizedString("Cannot connect to Internet", comment: "")
		} else if reachLimit {
			text = NSLocalizedString("Server has reached it's limit", comment: "")
		} else if somethingWrong {
			text = NSLocalizedString("Oops, something went wrong", comment: "")
		} else {
			text = NSLocalizedString("Loading...", comment: "")
		}
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
			NSForegroundColorAttributeName: UIColor.darkGrayColor()]
		return NSAttributedString(string: text, attributes: attributes)
	}

	func descriptionForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
		var text = ""
		if !isConnectedInternet {
			text = NSLocalizedString("Pull down to refresh", comment: "")
		} else if reachLimit {
			text = NSLocalizedString("Have a break and come back later", comment: "")
		} else if somethingWrong {
			text = NSLocalizedString("Please try again", comment: "")
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
		let title = ""
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0)]
		return NSAttributedString(string: title, attributes: attributes)
	}

	func backgroundColorForEmptyDataSet(scrollView: UIScrollView) -> UIColor {
		return UIColor.whiteColor()
	}

	func verticalOffsetForEmptyDataSet(scrollView: UIScrollView) -> CGFloat {
		let top = scrollView.contentInset.top
		return top - 66
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
		self.tableView.reloadData()
	}

	func cannotAccessInternet(notification: NSNotification) {
		isConnectedInternet = false
		if (self.photosArray.count == 0) {
			self.tableView.reloadData()
		} else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Cannot connect to Internet", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
		}
	}

	func exceedLimit(notification: NSNotification) {
		isConnectedInternet = true
		reachLimit = true
		somethingWrong = false
		if (self.photosArray.count == 0) {
			self.tableView.reloadData()
		} else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Server has reached it's limit", comment: "") + "\n" + NSLocalizedString("Have a break and come back later", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
		}
	}

	func somethingWentWrong(notification: NSNotification) {
		isConnectedInternet = true
		somethingWrong = true
		reachLimit = false
		if (self.photosArray.count == 0) {
			self.tableView.reloadData()
		} else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Oops, something went wrong", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
		}
	}

	func noData(notification: NSNotification) {
		isConnectedInternet = true
		noData = true
		somethingWrong = false
		reachLimit = false
		self.photosArray = []
		self.tableView.reloadData()
	}
}

