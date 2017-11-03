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
import PKHUD

class SearchTableViewController: BaseTableViewController, UISearchBarDelegate {

	var photoID: [String] = []
	var query = ""
	var searchPerItem = 10
	var searchTotalPages: Int {
		get {
			return Int(ceilf(Float(totalItems) / Float(searchPerItem)))
		}
	}
	var isSearching = false
    let searchBar = UISearchBar()

	override func viewDidLoad() {
		super.viewDidLoad()

        // configure navBar
        let cancel = UIButton()
        cancel.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        cancel.setTitleColor(UIColor.black, for: .normal)
        let size = cancel.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: 44))
        cancel.frame = CGRect(x: UIScreen.main.bounds.size.width - 10 - size.width, y: 0, width: size.width, height: 44)
        cancel.addTarget(self, action: #selector(back), for: .touchUpInside)
        self.navigationController?.navigationBar.addSubview(cancel)

        searchBar.frame = CGRect(x: 10, y: 0, width: cancel.frame.minX - 15, height: 44)
        searchBar.delegate = self
        self.navigationController?.navigationBar.addSubview(searchBar)

		// configure refreshController
        self.refreshControl = nil

		footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(SearchTableViewController.getSearchResults))
		footer.isRefreshingTitleHidden = true
		self.tableView.mj_footer = footer
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.tableView.contentOffset.y < 0 && self.tableView.isEmptyDataSetVisible) {
            self.tableView.contentOffset = CGPoint(x: 0, y: -64)
        }
    }

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "showSearchResults") {
            searchBar.resignFirstResponder()
			let detailViewController = segue.destination as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPath(for: cell!)
            detailViewController.configureData(self.photosArray, withIndex: indexPath!.row)
		}
	}

    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchItem()
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }

	// MARK: network notificaiton

	override func accessInternet(_ notification: Notification) {
		isConnectedInternet = true
		if (self.photosArray.count == 0) {
			let whiteSpace = CharacterSet.whitespacesAndNewlines
			let searchTerm = searchBar.text?.trimmingCharacters(in: whiteSpace)
			if (!searchTerm!.isEmpty) {
				self.searchItem()
			} else {
				self.tableView.reloadData()
			}
		}
	}

    // MARK: refresh function

    @objc func getSearchResults() {
        BaseNetworkRequest.getSearchResults(self)
    }

	// MARK: data request

	func searchItem() {
		let whiteSpace = CharacterSet.whitespacesAndNewlines
		let searchTerm = searchBar.text?.trimmingCharacters(in: whiteSpace)
		if (!searchTerm!.isEmpty) {
			isSearching = true
			if (self.photosArray.count != 0) {
				self.photosArray = []
				self.photoID = []
				self.page = 1
			}
            self.tableView.reloadData()
			self.query = searchBar.text!.lowercased()
			BaseNetworkRequest.getSearchResults(self)
		} else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Please enter the search term", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.0)
		}
	}

    // MARK: - button action

    @objc func back() {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
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
        let attributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 18.0),
                          NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
}
