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
import SDWebImage

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

		self.tableView.separatorStyle = .none

		self.refreshControl = UIRefreshControl()
		self.refreshControl!.backgroundColor = UIColor.white
		self.refreshControl!.tintColor = UIColor.black

		self.tableView.emptyDataSetSource = self;
		self.tableView.emptyDataSetDelegate = self;

		if !isConnectedInternet {
			self.tableView.reloadData()
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
		SDImageCache.shared().clearMemory()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		NotificationCenter.default.addObserver(self,
			selector: #selector(BaseTableViewController.accessInternet(_:)),
			name: NSNotification.Name(rawValue: "CanAccessInternet"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(BaseTableViewController.cannotAccessInternet(_:)),
			name: NSNotification.Name(rawValue: "CanNotAccessInternet"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(BaseTableViewController.exceedLimit(_:)),
			name: NSNotification.Name(rawValue: "ExceedRateLimit"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(BaseTableViewController.somethingWentWrong(_:)),
			name: NSNotification.Name(rawValue: "ErrorOccur"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(BaseTableViewController.noData(_:)),
			name: NSNotification.Name(rawValue: "NoData"),
			object: nil)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(true)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CanAccessInternet"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "NoData"), object: nil)
	}

	// MARK: - Table view data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.successfullyGetJsonData {
			return self.photosArray.count
		}
		return 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

		// Configure the cell...
		cell.backgroundColor = UIColor.white
		let imageView = cell.contentView.subviews[0] as! UIImageView
		imageView.contentMode = .scaleAspectFill
        imageView.sd_setShowActivityIndicatorView(true)
        imageView.sd_setIndicatorStyle(.gray)
		if self.successfullyGetJsonData {
			if (self.photosArray.count != 0) {
				imageView.sd_setImage(with: URL(string: self.photosArray[indexPath.row] ["small"]!))
			}
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return tableView.bounds.width / 1.5
	}

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		// Remove separator inset
		if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
			cell.separatorInset = UIEdgeInsets.zero
		}

		// Prevent the cell from inheriting the Table View's margin settings
		if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
			cell.preservesSuperviewLayoutMargins = false
		}

		// Explictly set your cell's layout margins
		if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
			cell.layoutMargins = UIEdgeInsets.zero
		}
	}

	// MARK: DZEmptyDataSet Data Source
	func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage {
		if !isConnectedInternet {
			return UIImage(named: "wifi")!
		} else if reachLimit {
			return UIImage(named: "coffee")!
		} else if somethingWrong {
			return UIImage(named: "error")!
		}
		return UIImage(named: "main-loading")!
	}

	func imageAnimation(forEmptyDataSet scrollView: UIScrollView) -> CAAnimation {
		let animation = CABasicAnimation(keyPath: "transform")
		animation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
		animation.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(CGFloat(Double.pi / 2), 0.0, 0.0, 1.0))
		animation.duration = 0.25
		animation.isCumulative = true
		animation.repeatCount = MAXFLOAT
		return animation
	}

	func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
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
		let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
			NSForegroundColorAttributeName: UIColor.darkGray]
		return NSAttributedString(string: text, attributes: attributes)
	}

	func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
		var text = ""
		if !isConnectedInternet {
			text = NSLocalizedString("Pull down to refresh", comment: "")
		} else if reachLimit {
			text = NSLocalizedString("Have a break and come back later", comment: "")
		} else if somethingWrong {
			text = NSLocalizedString("Please try again", comment: "")
		}
		let paragraph = NSMutableParagraphStyle()
		paragraph.lineBreakMode = .byWordWrapping
		paragraph.alignment = .center
		let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0),
			NSForegroundColorAttributeName: UIColor.lightGray,
			NSParagraphStyleAttributeName: paragraph]
		return NSAttributedString(string: text, attributes: attributes)
	}

	func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString {
		let title = ""
		let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0)]
		return NSAttributedString(string: title, attributes: attributes)
	}

	func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor {
		return UIColor.white
	}

	func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
		let top = scrollView.contentInset.top
		return top - 66
	}

	// MARK: DZEmptyDataSet Delegate
	func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
		return true
	}

	func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
		return true
	}

	func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
		return true
	}

	func emptyDataSetShouldAllowImageViewAnimate(_ scrollView: UIScrollView) -> Bool {
		return true
	}

	func emptyDataSetDidTapButton(_ scrollView: UIScrollView) {
	}

	// MARK: notification function
	func accessInternet(_ notification: Notification) {
		isConnectedInternet = true
		self.tableView.reloadData()
	}

	func cannotAccessInternet(_ notification: Notification) {
		isConnectedInternet = false
		if (self.photosArray.count == 0) {
			self.tableView.reloadData()
		} else {
			PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Cannot connect to Internet", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
			PKHUD.sharedHUD.show()
			PKHUD.sharedHUD.hide(afterDelay: 2.5)
		}
	}

	func exceedLimit(_ notification: Notification) {
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

	func somethingWentWrong(_ notification: Notification) {
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

	func noData(_ notification: Notification) {
		isConnectedInternet = true
		noData = true
		somethingWrong = false
		reachLimit = false
		self.photosArray = []
		self.tableView.reloadData()
	}
}

