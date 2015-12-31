//
// BaseTableViewController.swift
// Spatter
//
// Created by Molay on 15/12/19.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class BaseTableViewController: UITableViewController {
	
	let reuseIdentifier = "cell"
	var photosArray: [Dictionary<String, String>] = [Dictionary<String, String>]()
	var collcectionsArray: [Int] = []
	var successfullyGetJsonData = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		self.tableView.separatorStyle = .None
		
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.backgroundColor = UIColor.whiteColor()
		self.refreshControl!.tintColor = UIColor.blackColor()
		self.refreshControl!.addTarget(self, action: "getCollections", forControlEvents: .ValueChanged)
		
		self.getCollections()
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
		if self.successfullyGetJsonData {
			return self.photosArray.count
		}
		return 1000
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
		
		// Configure the cell...
		cell.backgroundColor = UIColor.whiteColor()
		let imageView = cell.contentView.subviews[0] as! UIImageView
		imageView.contentMode = .ScaleAspectFill
		if self.successfullyGetJsonData {
			imageView.sd_setImageWithURL(NSURL(string: self.photosArray[indexPath.row]["small"]!))
		}
		
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
	
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
	// }
	
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
	
	func getCollections() {
		Alamofire.request(.GET, "https://api.unsplash.com/curated_batches", parameters: [
				"client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d",
				"page": "1",
				"per_page": "30"
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
//						print("JSON:\(json)")
						for (_, subJson): (String, JSON) in json {
							self.collcectionsArray.append(subJson["id"].intValue)
						}
//						print(self.collcectionsArray)
						for index in 0...(self.collcectionsArray.count - 1) {
							self.getPhotos(self.collcectionsArray[index])
						}
					}
				case .Failure(let error):
					print(error)
				}
			})
	}
	
	func getPhotos(id: Int) {
		Alamofire.request(.GET, "https://api.unsplash.com/curated_batches/\(id)/photos", parameters: [
				"client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d"
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
//						print("JSON:\(json)")
                        for (_, subJson): (String, JSON) in json {
                            var photoDic = Dictionary<String, String>()
                            photoDic["regular"] = subJson["urls"]["regular"].stringValue
                            photoDic["small"] = subJson["urls"]["small"].stringValue
                            photoDic["id"] = subJson["id"].stringValue
                            photoDic["download"] = subJson["links"]["download"].stringValue
                            photoDic["name"] = subJson["user"]["name"].stringValue
                            self.photosArray.append(photoDic)
						 }
//						 print(self.photosArray)
                        self.successfullyGetJsonData = true
                        self.tableView.reloadData()
					}
				case .Failure(let error):
					print(error)
				}
			})
	}
}
