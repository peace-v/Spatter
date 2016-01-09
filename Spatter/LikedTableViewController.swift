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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		self.tableView.separatorStyle = .None
		
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.backgroundColor = UIColor.whiteColor()
		self.refreshControl!.tintColor = UIColor.blackColor()
		self.refreshControl!.addTarget(self, action: "getCollections", forControlEvents: .ValueChanged)
        
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
		Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
            "client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d",
            "page": "1",
            "per_page": "30"
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
//						print("JSON:\(json)")
						for (_, subJson): (String, JSON) in json {
							var photoDic = Dictionary<String, String>()
							photoDic["regular"] = subJson["urls"] ["regular"].stringValue
							photoDic["small"] = subJson["urls"] ["small"].stringValue
							photoDic["id"] = subJson["id"].stringValue
							photoDic["download"] = subJson["links"] ["download"].stringValue
							photoDic["name"] = subJson["user"] ["name"].stringValue
							self.photosArray.append(photoDic)
						}
						self.successfullyGetJsonData = true
						self.tableView.reloadData()
					}
				case .Failure(let error):
					print(error)
				}
			})
	}
}
