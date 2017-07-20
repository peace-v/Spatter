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
		self.refreshControl!.addTarget(self, action: #selector(LikedTableViewController.refreshLikedData), for: .valueChanged)
		
		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(LikedTableViewController.showNoMoreInfo))
		footer.isRefreshingTitleHidden = true
		self.tableView.mj_footer = footer
		
		NotificationCenter.default.addObserver(self, selector: #selector(LikedTableViewController.getLikedPhotos(_:)), name: NSNotification.Name(rawValue: "LoadLikedPhotos"), object: nil)
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.photosArray = likedPhotosArray
        self.tableView.reloadData()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LoadLikedPhotos"), object: nil)
        
	}
    
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if (segue.identifier == "showLikedPhoto") {
			let detailViewController = segue.destination as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPath(for: cell!)
			detailViewController.configureData(self.photosArray, withIndex: indexPath!.row)
		}
	}
	
    func getLikedPhotos(_ notification:Notification) {
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
		let cache = URLCache.shared
		cache.removeAllCachedResponses()
		BaseNetworkRequest.getLikedPhoto(self)
	}
    
    // MARK: DZEmptyDataSet
    
    override func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage {
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
    
    override func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
        var text = ""
        if !isConnectedInternet {
            text = NSLocalizedString("Cannot connect to Internet", comment: "")
        } else if noData{
            text = NSLocalizedString("You haven't like photo yet", comment: "")
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
}
