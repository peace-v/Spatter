//
//  PostTableViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/27.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class PostTableViewController: BaseTableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// configure refreshController
		self.refreshControl!.addTarget(self, action: #selector(PostTableViewController.refreshPostData), forControlEvents: .ValueChanged)
		
		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(PostTableViewController.showNoMoreInfo))
		footer.refreshingTitleHidden = true
		self.tableView.mj_footer = footer
        
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PostTableViewController.getPostPhoto(_:)), name: "LoadPostPhotos", object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "LoadPostPhotos", object: nil)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if (segue.identifier == "showPostPhoto") {
			let detailViewController = segue.destinationViewController as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPathForCell(cell!)
            detailViewController.regular = self.photosArray[indexPath!.row] ["regular"]!
            detailViewController.small = self.photosArray[indexPath!.row] ["small"]!
            detailViewController.full = self.photosArray[indexPath!.row] ["full"]!
            detailViewController.raw = self.photosArray[indexPath!.row] ["raw"]!
            detailViewController.download = self.photosArray[indexPath!.row] ["download"]!
            detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
            detailViewController.photoID = self.photosArray[indexPath!.row] ["id"]!
		}
	}
	
	func getPostPhoto(notification: NSNotification) {
        if (self.photosArray.count != 0) {
            self.successfullyGetJsonData = true
            self.tableView.reloadData()
        } else {
            BaseNetworkRequest.getPostPhoto(self)
        }
	}
	
	func showNoMoreInfo() {
		footer.endRefreshingWithNoMoreData()
	}
	
	func refreshPostData() {
		self.photosArray = []
		let cache = NSURLCache.sharedURLCache()
		cache.removeAllCachedResponses()
		BaseNetworkRequest.getPostPhoto(self)
	}
    
    // MARK: DZEmptyDataSet
    override func imageForEmptyDataSet(scrollView: UIScrollView) -> UIImage {
        if !isConnectedInternet {
            return UIImage(named: "wifi")!
        }else if noData {
            return UIImage(named: "photo")!
        } else if reachLimit {
            return UIImage(named: "coffee")!
        } else if somethingWrong {
            return UIImage(named: "error")!
        }else {
            return UIImage(named: "main-loading")!
        }
    }
    
    override func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        var text = ""
        if !isConnectedInternet {
            text = NSLocalizedString("Cannot connect to Internet", comment: "")
        } else if noData{
            text = NSLocalizedString("You haven't post photo yet", comment: "")
        }  else if reachLimit {
            text = NSLocalizedString("Server has reached it's limit", comment: "")
        } else if somethingWrong {
            text = NSLocalizedString("Oops, something went wrong", comment: "")
        }else {
            text = NSLocalizedString("Loading...", comment: "")
        }
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
