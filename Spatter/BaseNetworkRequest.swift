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
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (tableViewController.totalItems == 0) {
								print("Some error occured.")
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
						print("error is \(error)")
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
							} else if (statusCode == 408) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
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
					if let value = response.result.value {
						let json = JSON(value)
						// print("JSON:\(json)")
						for (_, subJson): (String, JSON) in json {
							var photoDic = Dictionary<String, String>()
							photoDic["regular"] = subJson["urls"] ["regular"].stringValue
							photoDic["small"] = subJson["urls"] ["small"].stringValue
							photoDic["id"] = subJson["id"].stringValue
							photoDic["download"] = subJson["links"] ["download"].stringValue
							photoDic["name"] = subJson["user"] ["name"].stringValue
							tableViewController.photosArray.append(photoDic)
						}
						tableViewController.successfullyGetJsonData = true
						tableViewController.tableView.reloadData()
					}
				case .Failure(let error):
					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 408) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
					}
				}
			})
	}
	
	// MARK: oauth callback
	class func oauth(notification: NSNotification) {
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
						if let value = response.result.value {
							let json = JSON(value)
							keychain["refresh_token"] = json["refresh_token"].stringValue
							keychain["access_token"] = json["access_token"].stringValue
							BaseNetworkRequest.loadProfile()
						}
					case .Failure(let error):
						print("error is \(error)")
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
							} else if (statusCode == 408) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
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
					if let value = response.result.value {
						let json = JSON(value)
						keychain["refresh_token"] = json["refresh_token"].stringValue
						keychain["access_token"] = json["access_token"].stringValue
						
						BaseNetworkRequest.loadProfile()
					}
				case .Failure(let error):
					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 408) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else {
							MainViewController.logout()
							let alert = UIAlertController(title: "Failed to login", message: "Please login to proceed with the operation", preferredStyle: .Alert)
							let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
							alert.addAction(ok)
							viewController.presentViewController(alert, animated: true, completion: nil)
						}
					} else {
						MainViewController.logout()
						let alert = UIAlertController(title: "Failed to login", message: "Please login to proceed with the operation", preferredStyle: .Alert)
						let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
						alert.addAction(ok)
						viewController.presentViewController(alert, animated: true, completion: nil)
					}
				}
			})
	}
	
	// MARK: get liked photos
	class func getLikedPhoto(tableViewController: LikedTableViewController? = nil) {
		print("calling get like photo")
		if (likedPhotoIDArray.count < likedTotalItems || likedPhotoIDArray.count == 0) {
			Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
					"client_id": clientID!,
					"page": likedPage,
					"per_page": likedPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						if (likedPage == 1) {
							likedTotalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (likedTotalItems == 0) {
								print("You haven't like photo yet")
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
						print("error is \(error)")
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
							} else if (statusCode == 401) {
								if (tableViewController != nil) {
									BaseNetworkRequest.refreshAccessToken(tableViewController!)
								}
							} else if (statusCode == 408) {
								NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
							} else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					}
				})
		} else {
			tableViewController?.refreshControl?.endRefreshing()
			tableViewController?.photosArray = likedPhotosArray
			tableViewController?.successfullyGetJsonData = true
			tableViewController?.tableView.reloadData()
            print("liked photos are \(likedPhotoIDArray.count)")
			return
		}
	}
	
	// MARK: get post photos
	class func getPostPhoto(tableViewController: PostTableViewController) {
		print("calling post photos")
		Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/photos", parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					tableViewController.refreshControl?.endRefreshing()
					tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
					if (tableViewController.totalItems == 0) {
						print("You haven't post photo yet.")
						NSNotificationCenter.defaultCenter().postNotificationName("NoData", object: nil)
					}
					if let value = response.result.value {
						let json = JSON(value)
						for (_, subJson): (String, JSON) in json {
							var photoDic = Dictionary<String, String>()
							photoDic["regular"] = subJson["urls"] ["regular"].stringValue
							photoDic["small"] = subJson["urls"] ["small"].stringValue
							photoDic["id"] = subJson["id"].stringValue
							photoDic["download"] = subJson["links"] ["download"].stringValue
							photoDic["name"] = subJson["user"] ["name"].stringValue
							tableViewController.photosArray.append(photoDic)
						}
						tableViewController.successfullyGetJsonData = true
						tableViewController.tableView.reloadData()
					}
				case .Failure(let error):
					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 408) {
							NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(tableViewController)
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
					}
				}
			})
	}
	
	// MARK: like or unlike a photo
	class func unlikePhoto(tableViewController: DetailViewController, id: String) {
		print("unlike a photo")
		Alamofire.request(.DELETE, "https://api.unsplash.com/photos/\(id)/like", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
						print("JSON:\(json)")
						likedPhotoIDArray.removeObject(id)
					}
					dispatch_async(dispatch_get_main_queue()) {
						tableViewController.likeButton.image = UIImage(named: "like-before")
					}
				case .Failure(let error):
					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(tableViewController)
                        }else if(statusCode == 408){
                            NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                        } else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
					}
				}
			})
	}
	
	class func likePhoto(viewController: DetailViewController, id: String) {
		print("like a photo")
		Alamofire.request(.POST, "https://api.unsplash.com/photos/\(id)/like", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
//					if let value = response.result.value {
//						let json = JSON(value)
////                        print("JSON:\(json)")
//						likedPhotoIDArray.addObject(id)
//					}
					likedPhotoIDArray.addObject(id)
					dispatch_async(dispatch_get_main_queue()) {
						viewController.likeButton.image = UIImage(named: "like-after")
					}
				case .Failure(let error):
					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(viewController)
                        }else if(statusCode == 408){
                            NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                        } else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
					}
				}
			})
	}
	
	// MARK: get search results
	class func getSearchResults(tableViewController: SearchTableViewController) {
		if (tableViewController.page <= tableViewController.searchTotalPages || tableViewController.page == 1) {
			Alamofire.request(.GET, "https://api.unsplash.com/photos/search/", parameters: [
					"client_id": clientID!,
					"query": tableViewController.query,
					"category": 0,
					"page": tableViewController.page,
					"per_page": tableViewController.searchPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
						print("response is \(response.response)")
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (tableViewController.totalItems == 0) {
								print("We couldn't find anything that matched that search.")
								NSNotificationCenter.defaultCenter().postNotificationName("NoData", object: nil)
								
								tableViewController.successfullyGetJsonData = true
								tableViewController.tableView.reloadData()
								return
							}
						}
						tableViewController.page += 1
						if let value = response.result.value {
							let json = JSON(value)
							// print("JSON:\(json)")
//							if (json.count == 0) {
//								tableViewController.page -= 1
//							}
							for (_, subJson): (String, JSON) in json {
								var photoDic = Dictionary<String, String>()
								photoDic["regular"] = subJson["urls"] ["regular"].stringValue
								photoDic["small"] = subJson["urls"] ["small"].stringValue
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
						print("error is \(error)")
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
								NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
                            }else if(statusCode == 408){
                                NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                            } else {
								NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
							}
						} else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
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
        print("load profile")
		Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
						// print("JSON:\(json)")
						username = json["username"].stringValue
						avatarURL = json["profile_image"] ["medium"].stringValue
						if (viewController != nil) {
							dispatch_async(dispatch_get_main_queue()) {
								viewController!.avatar.sd_setImageWithURL(NSURL(string: avatarURL))
								viewController!.userLabel.text = username
                                print("name is \(username)")
                                print("avatar is \(avatarURL)")
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
					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
							NSNotificationCenter.defaultCenter().postNotificationName("ExceedRateLimit", object: nil)
						} else if (statusCode == 401) {
							if (viewController != nil) {
								BaseNetworkRequest.refreshAccessToken(viewController!)
							}
                        }else if(statusCode == 408){
                            NSNotificationCenter.defaultCenter().postNotificationName("CanNotAccessInternet", object: nil)
                        } else {
							NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
						}
					} else {
						NSNotificationCenter.defaultCenter().postNotificationName("ErrorOccur", object: nil)
					}
				}
			})}
	
//	class func getUser(tableViewController: ProfileViewController) {
//		Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
//				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
//				"client_id": clientID!
//			]).validate().responseJSON(completionHandler: {response in
//				switch response.result {
//				case .Success:
//                    print("response is \(response.response?.allHeaderFields)")
//					if let value = response.result.value {
//						let json = JSON(value)
//						// print("JSON:\(json)")
//						dispatch_async(dispatch_get_main_queue()) {
//							tableViewController.avatar.sd_setImageWithURL(NSURL(string: json["profile_image"] ["medium"].stringValue))
//							username = json["username"].stringValue
//							tableViewController.userLabel.text = username
//							if (!username.isEmpty) {
//								NSNotificationCenter.defaultCenter().postNotificationName("LoadLikedPhotos", object: nil)
//								NSNotificationCenter.defaultCenter().postNotificationName("LoadPostPhotos", object: nil)
//							}
//						}
//					}
//				case .Failure(let error):
//					print("error is \(error)")
////					print("response is \(response.response?.allHeaderFields)")
////					print("result is \(response)")
//				}
//			})
//	}
	
}
