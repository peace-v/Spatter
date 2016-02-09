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

class SearchTableViewController: BaseTableViewController, UISearchBarDelegate, UISearchResultsUpdating {
	
	let searchController = UISearchController(searchResultsController: nil)
	var photoID: [String] = []
	var query = ""
	var searchPerItem = 10
	var searchTotalPages: Int {
		get {
			return Int(ceilf(Float(totalItems) / Float(searchPerItem)))
		}
	}
    var isSearching = false
	
	@IBOutlet weak var backBtn: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		searchController.resignFirstResponder()
		self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
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
//        self.refreshControl = UIRefreshControl()
//        self.refreshControl!.backgroundColor = UIColor.whiteColor()
//        self.refreshControl!.tintColor = UIColor.blackColor()
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
			detailViewController.regular = self.photosArray[indexPath!.row] ["regular"]!
			detailViewController.small = self.photosArray[indexPath!.row] ["small"]!
			detailViewController.download = self.photosArray[indexPath!.row] ["download"]!
			detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
			detailViewController.photoID = self.photosArray[indexPath!.row] ["id"]!
		}
	}
	
	// MARK: help function
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
            isSearching = true
            self.tableView.reloadData()
		} else {
			JDStatusBarNotification.showWithStatus("Please enter the search term", dismissAfter: 5.0)
		}
	}
	
	// MARK: scrollingNavBar
	override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.showNavbar(animated: true)
		}
		return true
	}
	
	// MARK: refresh function
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
	
	// MARK: DZEmptyDataSet
	override func imageForEmptyDataSet(scrollView: UIScrollView) -> UIImage {
		if !isConnectedInternet {
//			return UIImage(named: "wifi")!
            return UIImage(named: "error")!
		} else if somethingWentWrong {
			return UIImage(named: "coffee")!
		} else if noData {
			return UIImage(named: "character")!
        }else if isSearching {
            return UIImage(named: "Searching")!
        }else{
            return UIImage(named: "blank4")!
        }
	}
	
	override func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
		var text = ""
		if !isConnectedInternet {
			text = "Cannot connect to Internet"
		} else if somethingWentWrong {
			text = "Oops, something went wrong"
		} else if noData{
            text = "We couldn't find anything that matched the item"
        }else {
			text = "Searching..."
		}
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
			NSForegroundColorAttributeName: UIColor.darkGrayColor()]
		return NSAttributedString(string: text, attributes: attributes)
	}
	
	override func emptyDataSetDidTapButton(scrollView: UIScrollView) {
		if (!isConnectedInternet || somethingWentWrong) {
			BaseNetworkRequest.getSearchResults(self)
		}
	}
    
}
