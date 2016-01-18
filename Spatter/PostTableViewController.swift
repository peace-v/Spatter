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
        self.tableView.separatorStyle = .None
        
        // configure refreshController
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.backgroundColor = UIColor.whiteColor()
        self.refreshControl!.tintColor = UIColor.blackColor()
        self.refreshControl!.addTarget(self, action: "refreshPostData", forControlEvents: .ValueChanged)
        
        footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: "showNoMoreInfo")
        footer.refreshingTitleHidden = true
        self.tableView.mj_footer = footer
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "getPostPhotos:", name: "LoadPostPhotos", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "LoadPostPhotos", object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "showPostPhoto") {
            let detailViewController = segue.destinationViewController as! DetailViewController
            let cell = sender as? UITableViewCell
            let indexPath = self.tableView.indexPathForCell(cell!)
            detailViewController.downloadURL = self.photosArray[indexPath!.row] ["regular"]!
            detailViewController.creatorName = self.photosArray[indexPath!.row] ["name"]!
        }
    }
    
    func getPostPhotos(notification: NSNotification) {
        Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/photos", parameters: [
            "client_id": "cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d"
            ]).validate().responseJSON(completionHandler: {response in
                switch response.result {
                case .Success:
                    self.refreshControl?.endRefreshing()
                    if let value = response.result.value {
                        let json = JSON(value)
                        //						print("JSON:\(json)")
                        if (json.count == 0){
                            if (self.totalItems == 0) {
                                print("You don't post photo yet.")
                            }
                        }
                        for (_, subJson): (String, JSON) in json {
                            var photoDic = Dictionary<String, String>()
                            photoDic["regular"] = subJson["urls"] ["regular"].stringValue
                            photoDic["small"] = subJson["urls"] ["small"].stringValue
                            photoDic["id"] = subJson["id"].stringValue
                            photoDic["download"] = subJson["links"] ["download"].stringValue
                            photoDic["name"] = subJson["user"] ["name"].stringValue
                                self.photosArray.append(photoDic)
                        }
                        self.successfullyGetJsonData = true
                        self.tableView.reloadData()
                    }
                case .Failure(let error):
                    print(error)
                }
            })
    }
    
    func showNoMoreInfo() {
        footer.endRefreshingWithNoMoreData()
    }
    
    func refreshPostData() {
        self.photosArray = []
        NSNotificationCenter.defaultCenter().postNotificationName("LoadPostPhotos", object: nil)
    }
}
