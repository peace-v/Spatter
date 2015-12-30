//
// SearchTableViewController.swift
// Spatter
//
// Created by Molay on 15/12/19.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit

class SearchTableViewController: BaseTableViewController, UISearchBarDelegate, UISearchResultsUpdating {
	
	let searchController = UISearchController(searchResultsController: nil)
	
    @IBOutlet weak var backBtn: UIBarButtonItem!
    
    @IBAction func back(sender: AnyObject) {
        searchController.resignFirstResponder()
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // clear searchController warning
        if #available(iOS 9.0, *) {
            searchController.loadViewIfNeeded()
        } else {
            let _ = searchController.view
        }
		
        // configure searchController
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		definesPresentationContext = true
		tableView.tableHeaderView = searchController.searchBar
		searchController.searchBar.delegate = self
		searchController.searchBar.searchBarStyle = .Minimal
        // searchController.searchBar.showsScopeBar = true
//		searchController.searchBar.scopeButtonTitles = ["All", "Buildings", "Food", "Nature", "People", "Tech", "Objects"]
//		searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(10.0)], forState: .Normal)
//		searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(10.0)], forState: .Selected)
        
        // add screenEdgePanGesture
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: "screenEdgeSwiped:")
        edgePan.edges = .Left
        view.addGestureRecognizer(edgePan)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
//    override func viewWillAppear(animated: Bool) {
	// super.viewWillAppear(true)
	// self.navigationController!.navigationBarHidden = true
	// }
	
	// MARK: - Table view data source
	
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
	// // #warning Incomplete implementation, return the number of sections
	// return 0
	// }
	//
	// override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
	// // #warning Incomplete implementation, return the number of rows
	// return 0
	// }
	
	/*
	 override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
	 let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

	 // Configure the cell...

	 return cell
	 }
	 */
	
	/*
	 // Override to support conditional editing of the table view.
	 override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	 // Return false if you do not want the specified item to be editable.
	 return true
	 }
	 */
	
	/*
	 // Override to support editing the table view.
	 override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	 if editingStyle == .Delete {
	 // Delete the row from the data source
	 tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	 } else if editingStyle == .Insert {
	 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	 }
	 }
	 */
	
	/*
	 // Override to support rearranging the table view.
	 override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

	 }
	 */
	
	/*
	 // Override to support conditional rearranging of the table view.
	 override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	 // Return false if you do not want the item to be re-orderable.
	 return true
	 }
	 */
	
	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using segue.destinationViewController.
	 // Pass the selected object to the new view controller.
	 }
	 */
	
    func screenEdgeSwiped(recognizer:UIScreenEdgePanGestureRecognizer) {
        if (recognizer.state == .Recognized) {
            searchController.resignFirstResponder()
            self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
	// MARK: UISearchController
	func updateSearchResultsForSearchController(searchController: UISearchController) {
//		let scope = searchController.searchBar.scopeButtonTitles![searchController.searchBar.selectedScopeButtonIndex]
		
	}
	
//	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
	// searchController.resignFirstResponder()
	// self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
	// }
	
//	func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//		
//	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		
	}
	
}
