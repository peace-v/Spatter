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

	@IBAction func back(_ sender: AnyObject) {
		searchController.resignFirstResponder()
		self.navigationController!.dismiss(animated: true, completion: nil)
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
		searchController.searchBar.searchBarStyle = .minimal
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.tintColor = UIColor.black
        searchController.searchBar.backgroundColor = UIColor.white

		// configure refreshController
		self.refreshControl!.addTarget(self, action: #selector(SearchTableViewController.refreshSearchData), for: .valueChanged)

		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(SearchTableViewController.getSearchResults))
		footer.isRefreshingTitleHidden = true
		self.tableView.mj_footer = footer

		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SearchTableViewController.screenEdgeSwiped(_:)))
		edgePan.edges = .left
		view.addGestureRecognizer(edgePan)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let navigationController = self.navigationController as? ScrollingNavigationController {
			navigationController.followScrollView(self.tableView, delay: 50.0)
		}
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.tableView.contentOffset.y < 0 && self.tableView.isEmptyDataSetVisible) {
            self.tableView.contentOffset = CGPoint(x: 0, y: -64)
        }
    }

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if (segue.identifier == "showSearchResults") {
			let detailViewController = segue.destination as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPath(for: cell!)
            detailViewController.configureData(self.photosArray, withIndex: indexPath!.row)
		}
	}

	// MARK: swipe back

	func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .recognized) {
			searchController.resignFirstResponder()
			self.navigationController!.dismiss(animated: true, completion: nil)
		}
	}

	// MARK: UISearchController

	func updateSearchResults(for searchController: UISearchController) {
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		self.searchItem()
	}

	// MARK: scrollingNavBar

	override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
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
		let cache = URLCache.shared
		cache.removeAllCachedResponses()
		BaseNetworkRequest.getSearchResults(self)
	}

	// MARK: DZEmptyDataSet

	override func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage {
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

	override func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
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
		let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
			NSForegroundColorAttributeName: UIColor.darkGray]
		return NSAttributedString(string: text, attributes: attributes)
	}

	// MARK: network notificaiton

	override func accessInternet(_ notification: Notification) {
		isConnectedInternet = true
		if (self.photosArray.count == 0) {
			let whiteSpace = CharacterSet.whitespacesAndNewlines
			let searchTerm = searchController.searchBar.text?.trimmingCharacters(in: whiteSpace)
			if (!searchTerm!.isEmpty) {
				self.searchItem()
			} else {
				self.tableView.reloadData()
			}
		}
	}

	// MARK: help function

	func searchItem() {
		let whiteSpace = CharacterSet.whitespacesAndNewlines
		let searchTerm = searchController.searchBar.text?.trimmingCharacters(in: whiteSpace)
		if (!searchTerm!.isEmpty) {
			isSearching = true
			if (self.photosArray.count != 0) {
				self.photosArray = []
				self.photoID = []
				self.page = 1
			}
            self.tableView.reloadData()
			self.query = searchController.searchBar.text!.lowercased()
			BaseNetworkRequest.getSearchResults(self)
		} else {
			JDStatusBarNotification.show(withStatus: NSLocalizedString("Please enter the search term", comment: ""), dismissAfter: 2.5)
		}
	}
    
}
