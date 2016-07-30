//
//  BaseNetworkRequest.swift
//  Spatter
//
//  Created by Molay on 16/1/22.
//  Copyright © 2016年 yuying. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess
import PKHUD

class BaseNetworkRequest: NSObject {
	
	static var likedPerItem = 30
	static var likedPage = 1
	
	// MARK: get collection photos
	class func getCollections(tableViewController: BaseTableViewController) {
		if (tableViewController.page <= tableViewController.totalPages || tableViewController.page == 1) {
			Alamofire.request(.GET, "https://api.unsplash.com/curated_batches", parameters: [
					"client_id": clientID!,
					"page": tableViewController.page,
					"per_page": tableViewController.perItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						reachLimit = false
						tableViewController.somethingWrong = false
                        isConnectedInternet = true
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
                            if (response.response?.allHeaderFields["X-Total"] != nil){
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
                            }
							if (tableViewController.totalItems == 0) {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						}
						tableViewController.page += 1
						if let value = response.result.value {
							let json = JSON(value)
							for (_, subJson): (String, JSON) in json {
								let collectionID = subJson["id"].intValue
								if (!tableViewController.collcectionsArray.contains(collectionID)) {
									tableViewController.collcectionsArray.append(collectionID)
									BaseNetworkRequest.getPhotos(tableViewController, id: collectionID)
								}
							}
						}
					case .Failure(let error):
//						print("error is \(error)")
                        tableViewController.refreshControl?.endRefreshing()
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                            } else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						}
					}
				})
		} else {
			tableViewController.footer.endRefreshingWithNoMoreData()
		}
		if (tableViewController.footer.isRefreshing()) {
			tableViewController.footer.endRefreshing()
		}
	}
	
	class func getPhotos(tableViewController: BaseTableViewController, id: Int) {
		Alamofire.request(.GET, "https://api.unsplash.com/curated_batches/\(id)/photos", parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					reachLimit = false
					tableViewController.somethingWrong = false
                    isConnectedInternet = true
					if let value = response.result.value {
						let json = JSON(value)
						for (_, subJson): (String, JSON) in json {
							var photoDic = Dictionary<String, String>()
							photoDic["regular"] = subJson["urls"] ["regular"].stringValue
							photoDic["small"] = subJson["urls"] ["small"].stringValue
                            photoDic["full"] = subJson["urls"] ["full"].stringValue
                            photoDic["raw"] = subJson["urls"] ["raw"].stringValue
							photoDic["id"] = subJson["id"].stringValue
							photoDic["download"] = subJson["links"] ["download"].stringValue
							photoDic["name"] = subJson["user"] ["name"].stringValue
							tableViewController.photosArray.append(photoDic)
						}
						tableViewController.successfullyGetJsonData = true
						tableViewController.tableView.reloadData()
					}
				case .Failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					}
				}
			})
	}
	
	// MARK: oauth callback
    class func oauth(notification: NSNotification, vc:UIViewController) {
		let url = notification.object as! NSURL
		let urlString = url.absoluteString
		if (urlString.containsString("code")) {
			let urlArray = urlString.componentsSeparatedByString("=")
			let code = urlArray[1]
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isLogin")
			NSUserDefaults.standardUserDefaults().synchronize()
			Alamofire.request(.POST, "https://unsplash.com/oauth/token", parameters: [
					"client_id": clientID!,
					"client_secret": clientSecret!,
					"redirect_uri": "spatter://com.yuying.spatter",
					"code": code,
					"grant_type": "authorization_code"
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						reachLimit = false
                        isConnectedInternet = true
                        if((vc as? DetailViewController) != nil){
                            (vc as! DetailViewController).somethingWrong = false
                        }else if((vc as? ProfileViewController) != nil){
                            (vc as! ProfileViewController).somethingWrong = false
                        }
						if let value = response.result.value {
							let json = JSON(value)
							keychain["refresh_token"] = nil
							keychain["access_token"] = nil
							keychain["refresh_token"] = json["refresh_token"].stringValue
							keychain["access_token"] = json["access_token"].stringValue
							BaseNetworkRequest.loadProfile()
						}
					case .Failure(let error):
//						print("error is \(error)")
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
							}else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						}
					}
				})
		}
	}
	
	// MARK: refresh access token
	class func refreshAccessToken(viewController: UIViewController) {
		Alamofire.request(.POST, "https://unsplash.com/oauth/token", parameters: [
				"client_id": clientID!,
				"client_secret": clientSecret!,
				"refresh_token": keychain["refresh_token"]!,
				"grant_type": "refresh_token"
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					reachLimit = false
                    isConnectedInternet = true
                    if ((viewController as? BaseTableViewController) != nil){
                        (viewController as! BaseTableViewController).somethingWrong = false
                    }else if((viewController as? DetailViewController) != nil){
                    (viewController as! DetailViewController).somethingWrong = false
                    }else if((viewController as? ProfileViewController) != nil){
                        (viewController as! ProfileViewController).somethingWrong = false
                    }
					if let value = response.result.value {
						let json = JSON(value)
						keychain["refresh_token"] = nil
						keychain["access_token"] = nil
						keychain["refresh_token"] = json["refresh_token"].stringValue
						keychain["access_token"] = json["access_token"].stringValue
						
						BaseNetworkRequest.loadProfile()
					}
				case .Failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else {
							MainViewController.logout()
							let alert = UIAlertController(title: NSLocalizedString("Failed to login", comment: ""), message: NSLocalizedString("Please login to proceed with the operation", comment: ""), preferredStyle: .Alert)
							let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
							alert.addAction(ok)
							viewController.presentViewController(alert, animated: true, completion: nil)
						}
					} else {
						if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							MainViewController.logout()
							let alert = UIAlertController(title: NSLocalizedString("Failed to login", comment: ""), message: NSLocalizedString("Please login to proceed with the operation", comment: ""), preferredStyle: .Alert)
							let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
							alert.addAction(ok)
							viewController.presentViewController(alert, animated: true, completion: nil)
						}
					}
				}
			})
	}
	
	// MARK: get liked photos
	class func getLikedPhoto(tableViewController: LikedTableViewController? = nil) {
        tableViewController?.noData = false
		if (likedPhotoIDArray.count < likedTotalItems || likedPhotoIDArray.count == 0) {
			Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
					"client_id": clientID!,
					"page": likedPage,
					"per_page": likedPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						reachLimit = false
						tableViewController?.somethingWrong = false
                        isConnectedInternet = true
						if (likedPage == 1) {
							likedTotalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (likedTotalItems == 0) {
                                tableViewController?.noData = true
								NSNotificationCenter.defaultCenter().postNotificationName("NoData", object: nil)
								
								tableViewController?.refreshControl?.endRefreshing()
								tableViewController?.successfullyGetJsonData = true
								tableViewController?.tableView.reloadData()
								return
							}
						}
						likedPage += 1
						if let value = response.result.value {
							let json = JSON(value)
							for (_, subJson): (String, JSON) in json {
								var photoDic = Dictionary<String, String>()
								photoDic["regular"] = subJson["urls"] ["regular"].stringValue
								photoDic["small"] = subJson["urls"] ["small"].stringValue
                                photoDic["full"] = subJson["urls"] ["full"].stringValue
                                photoDic["raw"] = subJson["urls"] ["raw"].stringValue
								photoDic["id"] = subJson["id"].stringValue
								photoDic["download"] = subJson["links"] ["download"].stringValue
								photoDic["name"] = subJson["user"] ["name"].stringValue
								if (!likedPhotoIDArray.containsObject(subJson["id"].stringValue)) {
									likedPhotoIDArray.addObject(subJson["id"].stringValue)
									likedPhotosArray.append(photoDic)
								}
							}
							BaseNetworkRequest.getLikedPhoto(tableViewController)
						}
					case .Failure(let error):
//						print("error is \(error)")
                        tableViewController?.refreshControl?.endRefreshing()
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.reachLimitNotification(tableViewController!)
                                }
							} else if (statusCode == 401) {
								if (tableViewController != nil) {
									BaseNetworkRequest.refreshAccessToken(tableViewController!)
								}
							}  else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.somethingWrongNotification(tableViewController!)
                                }
							}
						} else {
							if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.noNetworkNotification(tableViewController!)
                                }
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.somethingWrongNotification(tableViewController!)
                                }
							}
						}
					}
				})
		} else {
			tableViewController?.refreshControl?.endRefreshing()
			tableViewController?.photosArray = likedPhotosArray
			tableViewController?.successfullyGetJsonData = true
			tableViewController?.tableView.reloadData()
			return
		}
	}
	
	// MARK: get post photos
	class func getPostPhoto(tableViewController: PostTableViewController) {
        tableViewController.noData = false
		Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/photos", parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					reachLimit = false
					tableViewController.somethingWrong = false
                    isConnectedInternet = true
					tableViewController.refreshControl?.endRefreshing()
					tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
					if (tableViewController.totalItems == 0) {
                        tableViewController.noData = true
						NSNotificationCenter.defaultCenter().postNotificationName("NoData", object: nil)
					}
					if let value = response.result.value {
						let json = JSON(value)
						for (_, subJson): (String, JSON) in json {
							var photoDic = Dictionary<String, String>()
							photoDic["regular"] = subJson["urls"] ["regular"].stringValue
							photoDic["small"] = subJson["urls"] ["small"].stringValue
                            photoDic["full"] = subJson["urls"] ["full"].stringValue
                            photoDic["raw"] = subJson["urls"] ["raw"].stringValue
							photoDic["id"] = subJson["id"].stringValue
							photoDic["download"] = subJson["links"] ["download"].stringValue
							photoDic["name"] = subJson["user"] ["name"].stringValue
							tableViewController.photosArray.append(photoDic)
						}
						tableViewController.successfullyGetJsonData = true
						tableViewController.tableView.reloadData()
					}
				case .Failure(let error):
//					print("error is \(error)")
                    tableViewController.refreshControl?.endRefreshing()
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
                            
                            BaseNetworkRequest.reachLimitNotification(tableViewController)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(tableViewController)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
                            
                            BaseNetworkRequest.somethingWrongNotification(tableViewController)
						}
					} else {
						if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                            
                            BaseNetworkRequest.noNetworkNotification(tableViewController)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
                            
                            BaseNetworkRequest.somethingWrongNotification(tableViewController)
						}
					}
				}
			})
	}
	
	// MARK: like or unlike a photo
	class func unlikePhoto(tableViewController: DetailViewController, id: String) {
		Alamofire.request(.DELETE, "https://api.unsplash.com/photos/\(id)/like", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					reachLimit = false
					tableViewController.somethingWrong = false
                    isConnectedInternet = true
                    likedPhotoIDArray.removeObject(id)
					dispatch_async(dispatch_get_main_queue()) {
						tableViewController.likeButton.image = UIImage(named: "like-before")
					}
				case .Failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(tableViewController)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					}
				}
			})
	}
	
	class func likePhoto(viewController: DetailViewController, id: String) {
		Alamofire.request(.POST, "https://api.unsplash.com/photos/\(id)/like", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					reachLimit = false
					viewController.somethingWrong = false
                    isConnectedInternet = true
					likedPhotoIDArray.addObject(id)
					dispatch_async(dispatch_get_main_queue()) {
						viewController.likeButton.image = UIImage(named: "like-after")
					}
				case .Failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(viewController)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					}
				}
			})
	}
	
	// MARK: get search results
	class func getSearchResults(tableViewController: SearchTableViewController) {
        tableViewController.isSearching = false
        tableViewController.noData = false
		if (tableViewController.page <= tableViewController.searchTotalPages || tableViewController.page == 1) {
			Alamofire.request(.GET, "https://api.unsplash.com/photos/search/", parameters: [
					"client_id": clientID!,
					"query": tableViewController.query,
					"category": "",
					"page": tableViewController.page,
					"per_page": tableViewController.searchPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						reachLimit = false
						tableViewController.somethingWrong = false
                        isConnectedInternet = true
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (tableViewController.totalItems == 0) {
								NSNotificationCenter.defaultCenter().postNotificationName("NoData", object: nil)
								
								tableViewController.successfullyGetJsonData = true
								tableViewController.tableView.reloadData()
								return
							}
						}
						tableViewController.page += 1
						if let value = response.result.value {
							let json = JSON(value)
//							if (json.count == 0) {
//								tableViewController.page -= 1
//							}
							for (_, subJson): (String, JSON) in json {
								var photoDic = Dictionary<String, String>()
								photoDic["regular"] = subJson["urls"] ["regular"].stringValue
								photoDic["small"] = subJson["urls"] ["small"].stringValue
                                photoDic["full"] = subJson["urls"] ["full"].stringValue
                                photoDic["raw"] = subJson["urls"] ["raw"].stringValue
								photoDic["id"] = subJson["id"].stringValue
								photoDic["download"] = subJson["links"] ["download"].stringValue
								photoDic["name"] = subJson["user"] ["name"].stringValue
								if (!tableViewController.photoID.contains(subJson["id"].stringValue)) {
									tableViewController.photoID.append(subJson["id"].stringValue)
									tableViewController.photosArray.append(photoDic)
								}
							}
							tableViewController.successfullyGetJsonData = true
							tableViewController.tableView.reloadData()
						}
					case .Failure(let error):
//						print("error is \(error)")
                        tableViewController.refreshControl?.endRefreshing()
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						}
					}
				})
		} else {
			tableViewController.footer.endRefreshingWithNoMoreData()
		}
		if (tableViewController.footer.isRefreshing()) {
			tableViewController.footer.endRefreshing()
		}
	}
	
	// MARK: load user profile
	class func loadProfile(viewController: ProfileViewController? = nil) {
		Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					reachLimit = false
                    isConnectedInternet = true
					if let value = response.result.value {
						let json = JSON(value)
						username = json["username"].stringValue
						avatarURL = json["profile_image"] ["medium"].stringValue
						if (viewController != nil) {
							dispatch_async(dispatch_get_main_queue()) {
								viewController!.avatar.sd_setImageWithURL(NSURL(string: avatarURL))
								viewController!.userLabel.text = username
							}
							if (!username.isEmpty) {
								NSNotificationCenter.defaultCenter().postNotificationName("LoadLikedPhotos", object: nil)
								NSNotificationCenter.defaultCenter().postNotificationName("LoadPostPhotos", object: nil)
							}
						} else {
							BaseNetworkRequest.getLikedPhoto()
						}
					}
				case .Failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 401) {
							if (viewController != nil) {
								BaseNetworkRequest.refreshAccessToken(viewController!)
							}
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						if (String(error).containsString("-1009") || String(error).containsString("-1001") || String(error).containsString("-1005")) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					}
				}
			})
    }
    
    // MARK: help function
    class func reachLimitNotification(vc:BaseTableViewController) {
        isConnectedInternet = true
        reachLimit = true
        vc.somethingWrong = false
        if (vc.photosArray.count == 0) {
            vc.tableView.reloadData()
        } else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Server has reached it's limit", comment: "") + "\n" + NSLocalizedString("Have a break and come back later", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
        }
    }
    
    class func noNetworkNotification(vc:BaseTableViewController) {
        isConnectedInternet = false
        if (vc.photosArray.count == 0) {
            vc.tableView.reloadData()
        }else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Cannot connect to Internet", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
        }
    }
    
    class func somethingWrongNotification(vc:BaseTableViewController) {
        isConnectedInternet = true
        vc.somethingWrong = true
        reachLimit = false
        if (vc.photosArray.count == 0) {
            vc.tableView.reloadData()
        } else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Oops, something went wrong", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
        }
    }
}
