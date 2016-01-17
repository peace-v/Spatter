//
// LikedTableViewController.swift
// Spatter
//
// Created by Molay on 15/12/27.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class LikedTableViewController: BaseTableViewController {
	
//	var searchPage = 1
	var photoID: [String] = []
	var likedPerItem = 30
	var likedTotalPages: Int {
		get {
			return Int(ceilf(Float(totalItems) / Float(likedPerItem)))
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		self.tableView.separatorStyle = .None
		
		// configure refreshController
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.backgroundColor = UIColor.whiteColor()
		self.refreshControl!.tintColor = UIColor.blackColor()
		self.refreshControl!.addTarget(self, action: "refreshLikedData", forControlEvents: .ValueChanged)
		
//		header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: "getLikedPhotos:")
		// header.lastUpdatedTimeLabel?.hidden = true
		// header.stateLabel?.hidden = true
		// self.tableView.mj_header = header
		
		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: "getLikedPhotos:")
		footer.refreshingTitleHidden = true
		self.tableView.mj_footer = footer
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "getLikedPhotos:", name: "LoadLikedPhotos", object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "LoadLikedPhotos", object: nil)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if (segue.identifier == "showLikedPhoto") {
			let detailViewController = segue.destinationViewController as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPathForCell(cell!)
			detailViewController.downloadURL = self.photosArray[indexPath!.row] ["regular"]!
			detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
		}
	}
	
	func getLikedPhotos(notification: NSNotification) {
		if (self.page <= self.totalPages || self.page == 1) {
			Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
					"client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d",
					"page": self.page,
					"per_page": self.likedPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
                        self.refreshControl?.endRefreshing()
						if (self.page == 1) {
							self.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
						}
						self.page += 1
						if let value = response.result.value {
							let json = JSON(value)
//						print("JSON:\(json)")
							if (json.count == 0) {
								self.page -= 1
								if (self.totalItems == 0) {
                                    print("You don't like photo yet")
                                }
//                                else {
//                                    self.footer.endRefreshingWithNoMoreData()
//                                }
							}
							for (_, subJson): (String, JSON) in json {
								var photoDic = Dictionary<String, String>()
								photoDic["regular"] = subJson["urls"] ["regular"].stringValue
								photoDic["small"] = subJson["urls"] ["small"].stringValue
								photoDic["id"] = subJson["id"].stringValue
								photoDic["download"] = subJson["links"] ["download"].stringValue
								photoDic["name"] = subJson["user"] ["name"].stringValue
								if (!self.photoID.contains(subJson["id"].stringValue)) {
									self.photoID.append(subJson["id"].stringValue)
									self.photosArray.append(photoDic)
								}
							}
							self.successfullyGetJsonData = true
							self.tableView.reloadData()
						}
					case .Failure(let error):
						print(error)
					}
				})
		} else {
			footer.endRefreshingWithNoMoreData()
		}
		if (footer.isRefreshing()) {
			footer.endRefreshing()
		}
	}
	
	func refreshLikedData() {
		self.photosArray = []
		self.photoID = []
		self.page = 1
		NSNotificationCenter.defaultCenter().postNotificationName("LoadLikedPhotos", object: nil)
//		self.refreshControl?.endRefreshing()
	}
}
