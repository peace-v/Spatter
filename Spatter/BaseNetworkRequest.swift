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

class BaseNetworkRequest: NSObject {
	
//    static var likedTotalItems = 0
	static var likedPerItem = 30
	static var likedPage = 1
//	static var likedTotalPages: Int {
//		get {
//			return Int(ceilf(Float(likedTotalItems) / Float(likedPerItem)))
//		}
//	}
	
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
//						print("response is \(response.response?.allHeaderFields)")
						if (tableViewController.page == 1) {
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (tableViewController.totalItems == 0) {
								print("Some error occured.")
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
						print("response is \(response.response?.allHeaderFields)")
						print("result is \(response)")
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
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
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
							BaseNetworkRequest.getUsername()
						}
					case .Failure(let error):
						print("error is \(error)")
						print("response is \(response.response?.allHeaderFields)")
						print("result is \(response)")
					}
				})
		}
	}
	
	// MARK: refresh access token
	class func refreshAccessToken() {
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
						// refreshToken = json["refresh_token"].stringValue
						// accessToken = json["access_token"].stringValue
						keychain["refresh_token"] = json["refresh_token"].stringValue
						keychain["access_token"] = json["access_token"].stringValue
						
						BaseNetworkRequest.getUsername()
					}
				case .Failure(let error):
					print("error is \(error)")
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
				}
			})
	}
	
	// MARK: get liked photos
	class func getUsername() {
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
						BaseNetworkRequest.getLikedPhoto()
					}
				case .Failure(let error):
					print("error is \(error)")
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
				}
			})}
	
	class func getLikedPhoto(tableViewController: LikedTableViewController? = nil) {
		if (likedPhotoIDArray.count < likedTotalItems || likedPhotoIDArray.count == 0) {
			Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/likes", parameters: [
					"client_id": clientID!,
					"page": likedPage,
					"per_page": likedPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .Success:
//						tableViewController?.refreshControl?.endRefreshing()
						if (likedPage == 1) {
							likedTotalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (likedTotalItems == 0) {
								print("You haven't like photo yet")
								tableViewController?.refreshControl?.endRefreshing()
								tableViewController?.successfullyGetJsonData = true
								tableViewController?.tableView.reloadData()
								return
							}
						}
						likedPage += 1
						if let value = response.result.value {
							let json = JSON(value)
							// print("JSON:\(json)")
//							if (json.count == 0) {
//								likedPage -= 1
//								return
//							}
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
//                                    tableViewController?.photosArray.append(photoDic)
								}
							}
							BaseNetworkRequest.getLikedPhoto(tableViewController)
						}
					case .Failure(let error):
						print("error is \(error)")
						print("response is \(response.response?.allHeaderFields)")
						print("result is \(response)")
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
		Alamofire.request(.GET, "https://api.unsplash.com/users/\(username)/photos", parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
//                    print(response.response?.allHeaderFields)
					tableViewController.refreshControl?.endRefreshing()
					tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
					if (tableViewController.totalItems == 0) {
						print("You haven't post photo yet.")
					}
					if let value = response.result.value {
						let json = JSON(value)
						// print("JSON:\(json)")
//						if (json.count == 0) {
//							if (tableViewController.totalItems == 0) {
//								print("You haven't post photo yet.")
//							}
//						}
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
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
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
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
				}
			})
	}
	
	class func likePhoto(tableViewController: DetailViewController, id: String) {
		print("like a photo")
		Alamofire.request(.POST, "https://api.unsplash.com/photos/\(id)/like", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
//                        print("JSON:\(json)")
						likedPhotoIDArray.addObject(id)
					}
						dispatch_async(dispatch_get_main_queue()) {
							tableViewController.likeButton.image = UIImage(named: "like-after")
						}
				case .Failure(let error):
					print("error is \(error)")
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
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
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (tableViewController.totalItems == 0) {
								print("We couldn't find anything that matched that search.")
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
						print("response is \(response.response?.allHeaderFields)")
						print("result is \(response)")
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
	class func loadProfile(tableViewController: ProfileViewController) {
		Alamofire.request(.GET, "https://api.unsplash.com/me", headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .Success:
					if let value = response.result.value {
						let json = JSON(value)
						// print("JSON:\(json)")
						dispatch_async(dispatch_get_main_queue()) {
							tableViewController.avatar.sd_setImageWithURL(NSURL(string: json["profile_image"] ["medium"].stringValue))
							username = json["username"].stringValue
							tableViewController.userLabel.text = username
							if (!username.isEmpty) {
								NSNotificationCenter.defaultCenter().postNotificationName("LoadLikedPhotos", object: nil)
								NSNotificationCenter.defaultCenter().postNotificationName("LoadPostPhotos", object: nil)
							}
						}
					}
				case .Failure(let error):
					print("error is \(error)")
					print("response is \(response.response?.allHeaderFields)")
					print("result is \(response)")
				}
			})
	}
}
