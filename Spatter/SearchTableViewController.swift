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
		self.refreshControl!.addTarget(self, action: #selector(SearchTableViewController.refreshSearchData), forControlEvents: .ValueChanged)

		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(SearchTableViewController.getSearchResults))
		footer.refreshingTitleHidden = true
		self.tableView.mj_footer = footer

		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SearchTableViewController.screenEdgeSwiped(_:)))
		edgePan.edges = .Left
		view.addGestureRecognizer(edgePan)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.followScrollView(self.tableView, delay: 50.0)
		}
	}

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        if (self.tableView.contentOffset.y < 0 && self.tableView.emptyDataSetVisible) {
            self.tableView.contentOffset = CGPoint(x: 0, y: -64)
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
            detailViewController.full = self.photosArray[indexPath!.row] ["full"]!
            detailViewController.raw = self.photosArray[indexPath!.row] ["raw"]!
			detailViewController.download = self.photosArray[indexPath!.row] ["download"]!
			detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
			detailViewController.photoID = self.photosArray[indexPath!.row] ["id"]!
		}
	}

	// MARK: swipe back
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
		self.searchItem()
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
			return UIImage(named: "wifi")!
		} else if isSearching {
			return UIImage(named: "Searching")!
		} else if noData {
			return UIImage(named: "character")!
		} else if reachLimit {
			return UIImage(named: "coffee")!
		} else if somethingWrong {
			return UIImage(named: "error")!
		} else {
			return UIImage(named: "blank4")!
		}
	}

	override func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
		var text = ""
		if !isConnectedInternet {
			text = NSLocalizedString("Cannot connect to Internet", comment: "")
        } else if isSearching {
            text = NSLocalizedString("Searching...", comment: "")
        } else if noData {
			text = NSLocalizedString("We couldn't find anything that matched the item", comment: "")
		}  else if reachLimit {
			text = NSLocalizedString("Server has reached it's limit", comment: "")
		} else if somethingWrong {
			text = NSLocalizedString("Oops, something went wrong", comment: "")
		}
		let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
			NSForegroundColorAttributeName: UIColor.darkGrayColor()]
		return NSAttributedString(string: text, attributes: attributes)
	}

	// MARK: network notificaiton
	override func accessInternet(notification: NSNotification) {
		isConnectedInternet = true
		if (self.photosArray.count == 0) {
			let whiteSpace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
			let searchTerm = searchController.searchBar.text?.stringByTrimmingCharactersInSet(whiteSpace)
			if (!searchTerm!.isEmpty) {
				self.searchItem()
			} else {
				self.tableView.reloadData()
			}
		}
	}

	// MARK: help function
	func searchItem() {
		let whiteSpace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
		let searchTerm = searchController.searchBar.text?.stringByTrimmingCharactersInSet(whiteSpace)
		if (!searchTerm!.isEmpty) {
			isSearching = true
			if (self.photosArray.count != 0) {
				self.photosArray = []
				self.photoID = []
				self.page = 1
			}
            self.tableView.reloadData()
			self.query = searchController.searchBar.text!.lowercaseString
			BaseNetworkRequest.getSearchResults(self)
		} else {
			JDStatusBarNotification.showWithStatus(NSLocalizedString("Please enter the search term", comment: ""), dismissAfter: 2.5)
		}
	}
    
}
