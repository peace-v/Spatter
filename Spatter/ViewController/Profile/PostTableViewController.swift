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
		self.refreshControl!.addTarget(self, action: #selector(PostTableViewController.refreshPostData), for: .valueChanged)
		
		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(PostTableViewController.showNoMoreInfo))
		footer.isRefreshingTitleHidden = true
		self.tableView.mj_footer = footer
        
		NotificationCenter.default.addObserver(self, selector: #selector(PostTableViewController.getPostPhoto(_:)), name: NSNotification.Name(rawValue: "LoadPostPhotos"), object: nil)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "LoadPostPhotos"), object: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "showPostPhoto") {
			let detailViewController = segue.destination as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPath(for: cell!)
            detailViewController.configureData(self.photosArray, withIndex: indexPath!.row)
		}
	}
	
	@objc func getPostPhoto(_ notification: Notification) {
        if (self.photosArray.count != 0) {
            self.successfullyGetJsonData = true
            self.tableView.reloadData()
        } else {
            BaseNetworkRequest.getPostPhoto(self)
        }
	}
	
	@objc func showNoMoreInfo() {
		footer.endRefreshingWithNoMoreData()
	}
	
	@objc func refreshPostData() {
		self.photosArray = []
		let cache = URLCache.shared
		cache.removeAllCachedResponses()
		BaseNetworkRequest.getPostPhoto(self)
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
            text = NSLocalizedString("You haven't post photo yet", comment: "")
        }  else if reachLimit {
            text = NSLocalizedString("Server has reached it's limit", comment: "")
        } else if somethingWrong {
            text = NSLocalizedString("Oops, something went wrong", comment: "")
        }else {
            text = NSLocalizedString("Loading...", comment: "")
        }
        let attributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 18.0),
            NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
