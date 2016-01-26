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

class BaseTableViewController: UITableViewController {
	
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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.separatorStyle = .None
		
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.backgroundColor = UIColor.whiteColor()
		self.refreshControl!.tintColor = UIColor.blackColor()
		self.refreshControl!.addTarget(self, action: "refreshData", forControlEvents: .ValueChanged)
		
		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: "getCollections")
		footer.refreshingTitleHidden = true
		self.tableView.mj_footer = footer
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
		SDImageCache.sharedImageCache().clearMemory()
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
	
//	func getCollections() {
//		if (self.page <= self.totalPages || self.page == 1) {
//			Alamofire.request(.GET, "https://api.unsplash.com/curated_batches", parameters: [
//					"client_id": clientID!,
//					"page": self.page,
//					"per_page": self.perItem
//				]).validate().responseJSON(completionHandler: {response in
//					switch response.result {
//					case .Success:
//						self.refreshControl?.endRefreshing()
////                    print("response is \(response.response?.allHeaderFields)")
//						if (self.page == 1) {
//							self.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
//						}
//						self.page += 1
//						if let value = response.result.value {
//							let json = JSON(value)
////						print("JSON:\(json)")
//							for (_, subJson): (String, JSON) in json {
//								let collectionID = subJson["id"].intValue
//								if (!self.collcectionsArray.contains(collectionID)) {
//									self.collcectionsArray.append(collectionID)
//									self.getPhotos(collectionID)
//								}
//							}
//						}
//					case .Failure(let error):
//						print(error)
//					}
//				})
//		} else {
//			footer.endRefreshingWithNoMoreData()
//		}
//		if (footer.isRefreshing()) {
//			footer.endRefreshing()
//		}
//	}
//	
//	func getPhotos(id: Int) {
//		Alamofire.request(.GET, "https://api.unsplash.com/curated_batches/\(id)/photos", parameters: [
//				"client_id": clientID!
//			]).validate().responseJSON(completionHandler: {response in
//				switch response.result {
//				case .Success:
//					if let value = response.result.value {
//						let json = JSON(value)
////						print("JSON:\(json)")
//						for (_, subJson): (String, JSON) in json {
//							var photoDic = Dictionary<String, String>()
//							photoDic["regular"] = subJson["urls"] ["regular"].stringValue
//							photoDic["small"] = subJson["urls"] ["small"].stringValue
//							photoDic["id"] = subJson["id"].stringValue
//							photoDic["download"] = subJson["links"] ["download"].stringValue
//							photoDic["name"] = subJson["user"] ["name"].stringValue
//							self.photosArray.append(photoDic)
//						}
//						self.successfullyGetJsonData = true
//						self.tableView.reloadData()
//					}
//				case .Failure(let error):
//					print(error)
//				}
//			})
//	}
    
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
}

