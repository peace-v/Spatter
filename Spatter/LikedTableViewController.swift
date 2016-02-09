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
		
		// configure refreshController
		self.refreshControl!.addTarget(self, action: "refreshLikedData", forControlEvents: .ValueChanged)
		
		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: "showNoMoreInfo")
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
			detailViewController.regular = self.photosArray[indexPath!.row] ["regular"]!
			detailViewController.small = self.photosArray[indexPath!.row] ["small"]!
			detailViewController.download = self.photosArray[indexPath!.row] ["download"]!
			detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
			detailViewController.photoID = self.photosArray[indexPath!.row] ["id"]!
		}
	}
	
    func getLikedPhotos(notification:NSNotification) {
		if (likedPhotosArray.count != 0) {
			self.photosArray = likedPhotosArray
			self.successfullyGetJsonData = true
			self.tableView.reloadData()
		} else {
			BaseNetworkRequest.getLikedPhoto(self)
		}
	}
	
	func showNoMoreInfo() {
		footer.endRefreshingWithNoMoreData()
	}
	
	func refreshLikedData() {
		self.photosArray = []
		likedPhotosArray = []
		likedPhotosArray = [Dictionary<String, String>]()
		likedPhotoIDArray = []
		likedTotalItems = 0
		BaseNetworkRequest.likedPage = 1
		let cache = NSURLCache.sharedURLCache()
		cache.removeAllCachedResponses()
		BaseNetworkRequest.getLikedPhoto(self)
	}
    
    // MARK: DZEmptyDataSet
    override func imageForEmptyDataSet(scrollView: UIScrollView) -> UIImage {
        if !isConnectedInternet {
            return UIImage(named: "wifi")!
        }else if somethingWentWrong {
            return UIImage(named: "coffee")!
        }else if noData {
            return UIImage(named: "photo")!
        }else {
            return UIImage(named: "main-loading")!
        }
    }
    
    override func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        var text = ""
        if !isConnectedInternet {
            text = "Cannot connect to Internet"
        } else if somethingWentWrong {
            text = "Oops, something went wrong"
        } else if noData{
            text = "You haven't like photo yet"
        }else {
            text = "Loading..."
        }
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    override func emptyDataSetDidTapButton(scrollView: UIScrollView) {
        if (!isConnectedInternet || somethingWentWrong){
            BaseNetworkRequest.getLikedPhoto(self)
        }
    }
}
