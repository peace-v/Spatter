//
// SearchTableViewController.swift
// Spatter
//
// Created by Molay on 15/12/19.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import Alamofire
import SwiftyJSON
import Whisper

class SearchTableViewController: BaseTableViewController, UISearchBarDelegate, UISearchResultsUpdating {
	
	let searchController = UISearchController(searchResultsController: nil)
	var photoID: [String] = []
    var query = ""
    var searchPerItem = 30
    var searchTotalPages: Int {
        get {
            return Int(ceilf(Float(totalItems) / Float(searchPerItem)))
        }
    }
	
	@IBOutlet weak var backBtn: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		searchController.resignFirstResponder()
		self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
        self.tableView.separatorStyle = .None
        
		// clear searchController warning
//		if #available(iOS 9.0, *) {
//			searchController.loadViewIfNeeded()
//		} else {
//			let _ = searchController.view
//		}
        
            searchController.loadViewIfNeeded()

		// configure searchController
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		definesPresentationContext = true
		tableView.tableHeaderView = searchController.searchBar
		searchController.searchBar.delegate = self
		searchController.searchBar.searchBarStyle = .Minimal
		searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.tintColor = UIColor.blackColor()
        
        // configure refreshController
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.backgroundColor = UIColor.whiteColor()
        self.refreshControl!.tintColor = UIColor.blackColor()
        self.refreshControl!.addTarget(self, action: "refreshSearchData", forControlEvents: .ValueChanged)
        
        footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: "getSearchResults")
        footer.refreshingTitleHidden = true
        self.tableView.mj_footer = footer
		
		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: "screenEdgeSwiped:")
		edgePan.edges = .Left
		view.addGestureRecognizer(edgePan)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.followScrollView(self.tableView, delay: 50.0)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if (segue.identifier == "showSearchResults") {
			let detailViewController = segue.destinationViewController as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPathForCell(cell!)
			detailViewController.downloadURL = self.photosArray[indexPath!.row] ["regular"]!
			detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
            detailViewController.photoID = self.photosArray[indexPath!.row] ["id"]!
		}
	}
	
	func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .Recognized) {
			searchController.resignFirstResponder()
			self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	// MARK: UISearchController
    func updateSearchResultsForSearchController(searchController: UISearchController) {
    }
    
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		let whiteSpace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
		let searchTerm = searchController.searchBar.text?.stringByTrimmingCharactersInSet(whiteSpace)
		if (!searchTerm!.isEmpty) {
            if (self.photosArray.count != 0) {
                self.photosArray = []
                self.photoID = []
                self.page = 1
            }
            self.query = searchController.searchBar.text!.lowercaseString
			BaseNetworkRequest.getSearchResults(self)
		} else {
//			print("Please enter the search term")
            let murmur = Murmur(title: "Please enter the search term.")
            Whistle(murmur)
		}
	}
	
	// MARK: scrollingNavBar
	override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.showNavbar(animated: true)
		}
		return true
	}
	
	// MARK: fetch search results
//	func getSearchResults() {
//		if (self.page <= self.totalPages || self.page == 1) {
//			Alamofire.request(.GET, "https://api.unsplash.com/photos/search/", parameters: [
//					"client_id": clientID!,
//					"query": self.query,
//					"category": 0,
//					"page": self.page,
//					"per_page": searchPerItem
//				]).validate().responseJSON(completionHandler: {response in
//					switch response.result {
//					case .Success:
//                        self.refreshControl?.endRefreshing()
//						if (self.page == 1) {
//							self.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
//						}
//						self.page += 1
//						if let value = response.result.value {
//							let json = JSON(value)
////						print("JSON:\(json)")
//                            if (json.count == 0){                             
//                                self.page -= 1
//                                if (self.totalItems == 0) {
//                                    print("We couldn't find anything that matched that search.")
//                                }
//                            }
//							for (_, subJson): (String, JSON) in json {
//								var photoDic = Dictionary<String, String>()
//								photoDic["regular"] = subJson["urls"] ["regular"].stringValue
//								photoDic["small"] = subJson["urls"] ["small"].stringValue
//								photoDic["id"] = subJson["id"].stringValue
//								photoDic["download"] = subJson["links"] ["download"].stringValue
//								photoDic["name"] = subJson["user"] ["name"].stringValue
//								if (!self.photoID.contains(subJson["id"].stringValue)) {
//									self.photoID.append(subJson["id"].stringValue)
//									self.photosArray.append(photoDic)
//								}
//							}
//							self.successfullyGetJsonData = true
//							self.tableView.reloadData()
//						}
//					case .Failure(let error):
//						print(error)
//					}
//				})
//		} else {
//			footer.endRefreshingWithNoMoreData()
//		}
//        if (footer.isRefreshing()) {
//            footer.endRefreshing()
//        }
//	}
    
    func getSearchResults() {
        BaseNetworkRequest.getSearchResults(self)
    }
	
    func refreshSearchData() {
        self.photosArray = []
        self.photoID = []
        self.page = 1
        let cache = NSURLCache.sharedURLCache()
        cache.removeAllCachedResponses()
        BaseNetworkRequest.getSearchResults(self)
    }
}
