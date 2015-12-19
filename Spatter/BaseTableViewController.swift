//
//  BaseTableViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/19.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {

	let reuseIdentifier = "cell"

	override func viewDidLoad() {
		super.viewDidLoad()

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()

		//        if (self.tableView.respondsToSelector("setCellLayoutMarginsFollowReadableWidth:")) {
		//            if #available(iOS 9.0, *) {
		//                self.tableView.cellLayoutMarginsFollowReadableWidth = false
		//            } else {
		//                // Fallback on earlier versions
		//            }
		//        }
        
        self.tableView.separatorStyle = .None
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return 300
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)

		// Configure the cell...
        let imageView = cell.contentView.subviews[0] as! UIImageView
        imageView.image = UIImage(named: "space")
        imageView.contentMode = .ScaleAspectFill

		return cell
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return tableView.bounds.width / 1.5
	}

	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		// Remove separator inset
		if cell.respondsToSelector("setSeparatorInset:") {
			cell.separatorInset = UIEdgeInsetsZero
		}

		// Prevent the cell from inheriting the Table View's margin settings
		if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
			cell.preservesSuperviewLayoutMargins = false
		}

		// Explictly set your cell's layout margins
		if cell.respondsToSelector("setLayoutMargins:") {
			cell.layoutMargins = UIEdgeInsetsZero
		}
	}

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
}
