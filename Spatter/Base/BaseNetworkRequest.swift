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
	class func getCollections(_ tableViewController: BaseTableViewController) {
		if (tableViewController.page <= tableViewController.totalPages || tableViewController.page == 1) {
			Alamofire.request("https://api.unsplash.com/curated_batches/get", parameters: [
					"client_id": clientID!,
					"page": tableViewController.page,
					"per_page": tableViewController.perItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .success:
						reachLimit = false
						tableViewController.somethingWrong = false
                        isConnectedInternet = true
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
                            if (response.response?.allHeaderFields["X-Total"] != nil){
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
                            }
							if (tableViewController.totalItems == 0) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
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
					case .failure(let error):
//						print("error is \(error)")
                        tableViewController.refreshControl?.endRefreshing()
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
							} else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
							}
						} else {
							if (error.localizedDescription.contains("-1009") ||
                                error.localizedDescription.contains("-1001") ||
                                error.localizedDescription.contains("-1005")) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
                            } else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
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
	
	class func getPhotos(_ tableViewController: BaseTableViewController, id: Int) {
		Alamofire.request("https://api.unsplash.com/curated_batches/\(id)/photos/get", parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .success:
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
                            photoDic["profileUrl"] = subJson["user"] ["links"]["html"].stringValue
							tableViewController.photosArray.append(photoDic)
						}
						tableViewController.successfullyGetJsonData = true
						tableViewController.tableView.reloadData()
					}
				case .failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					} else {
						if (error.localizedDescription.contains("-1009") ||
                            error.localizedDescription.contains("-1001") ||
                            error.localizedDescription.contains("-1005")) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					}
				}
			})
	}
	
	// MARK: oauth callback
    class func oauth(_ notification: Notification, vc:UIViewController) {
		let url = notification.object as! URL
		let urlString = url.absoluteString
		if (urlString.contains("code")) {
			let urlArray = urlString.components(separatedBy: "=")
			let code = urlArray[1]
			UserDefaults.standard.set(true, forKey: "isLogin")
			UserDefaults.standard.synchronize()
            Alamofire.request("https://unsplash.com/oauth/token/post", method: .post,  parameters: [
					"client_id": clientID!,
					"client_secret": clientSecret!,
					"redirect_uri": "spatter://com.yuying.spatter",
					"code": code,
					"grant_type": "authorization_code"
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .success:
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
					case .failure(let error):
//						print("error is \(error)")
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
							}else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
							}
						} else {
							if (error.localizedDescription.contains("-1009") ||
                                error.localizedDescription.contains("-1001") ||
                                error.localizedDescription.contains("-1005")) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
							} else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
							}
						}
					}
				})
		}
	}
	
	// MARK: refresh access token
	class func refreshAccessToken(_ viewController: UIViewController) {
        Alamofire.request("https://unsplash.com/oauth/token/post", method:.post, parameters: [
				"client_id": clientID!,
				"client_secret": clientSecret!,
				"refresh_token": keychain["refresh_token"]!,
				"grant_type": "refresh_token"
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .success:
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
				case .failure(let error):
//					print("error is \(error)")
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
						} else {
							MainViewController.logout()
							let alert = UIAlertController(title: NSLocalizedString("Failed to login", comment: ""), message: NSLocalizedString("Please login to proceed with the operation", comment: ""), preferredStyle: .alert)
							let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
							alert.addAction(ok)
							viewController.present(alert, animated: true, completion: nil)
						}
					} else {
						if (error.localizedDescription.contains("-1009") ||
                            error.localizedDescription.contains("-1001") ||
                            error.localizedDescription.contains("-1005")) {

                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
						} else {
							MainViewController.logout()
							let alert = UIAlertController(title: NSLocalizedString("Failed to login", comment: ""), message: NSLocalizedString("Please login to proceed with the operation", comment: ""), preferredStyle: .alert)
							let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
							alert.addAction(ok)
							viewController.present(alert, animated: true, completion: nil)
						}
					}
				}
			})
	}
	
	// MARK: get liked photos
	class func getLikedPhoto(_ tableViewController: LikedTableViewController? = nil) {
        tableViewController?.noData = false
		if (likedPhotoIDArray.count < likedTotalItems || likedPhotoIDArray.count == 0) {
			Alamofire.request("https://api.unsplash.com/users/\(username)/likes/get", parameters: [
					"client_id": clientID!,
					"page": likedPage,
					"per_page": likedPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .success:
						reachLimit = false
						tableViewController?.somethingWrong = false
                        isConnectedInternet = true
						if (likedPage == 1) {
							likedTotalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (likedTotalItems == 0) {
                                tableViewController?.noData = true
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NoData"), object: nil)
								
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
                                photoDic["profileUrl"] = subJson["user"] ["links"]["html"].stringValue
								if (!likedPhotoIDArray.contains(subJson["id"].stringValue)) {
									likedPhotoIDArray.add(subJson["id"].stringValue)
									likedPhotosArray.append(photoDic)
								}
							}
							BaseNetworkRequest.getLikedPhoto(tableViewController)
						}
					case .failure(let error):
                        tableViewController?.refreshControl?.endRefreshing()
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.reachLimitNotification(tableViewController!)
                                }
							} else if (statusCode == 401) {
								if (tableViewController != nil) {
									BaseNetworkRequest.refreshAccessToken(tableViewController!)
								}
							}  else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.somethingWrongNotification(tableViewController!)
                                }
							}
						} else {
							if (error.localizedDescription.contains("-1009") ||
                                error.localizedDescription.contains("-1001") ||
                                error.localizedDescription.contains("-1005")) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
                                
                                if (tableViewController != nil){
                                    BaseNetworkRequest.noNetworkNotification(tableViewController!)
                                }
							} else {

                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
                                
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
	class func getPostPhoto(_ tableViewController: PostTableViewController) {
        tableViewController.noData = false
		Alamofire.request("https://api.unsplash.com/users/\(username)/photos/get", parameters: [
				"client_id": clientID!
			]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .success:
					reachLimit = false
					tableViewController.somethingWrong = false
                    isConnectedInternet = true
					tableViewController.refreshControl?.endRefreshing()
					tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
					if (tableViewController.totalItems == 0) {
                        tableViewController.noData = true
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NoData"), object: nil)
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
                            photoDic["profileUrl"] = subJson["user"] ["links"]["html"].stringValue
							tableViewController.photosArray.append(photoDic)
						}
						tableViewController.successfullyGetJsonData = true
						tableViewController.tableView.reloadData()
					}
				case .failure(let error):
                    tableViewController.refreshControl?.endRefreshing()
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {

                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
                            
                            BaseNetworkRequest.reachLimitNotification(tableViewController)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(tableViewController)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
                            
                            BaseNetworkRequest.somethingWrongNotification(tableViewController)
						}
					} else {
						if (error.localizedDescription.contains("-1009") ||
                            error.localizedDescription.contains("-1001") ||
                            error.localizedDescription.contains("-1005")) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
                            
                            BaseNetworkRequest.noNetworkNotification(tableViewController)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
                            BaseNetworkRequest.somethingWrongNotification(tableViewController)
						}
					}
				}
			})
	}
	
	// MARK: like or unlike a photo
	class func unlikePhoto(_ tableViewController: DetailViewController, id: String) {
        Alamofire.request("https://api.unsplash.com/photos/\(id)/like/delete", method: .delete, parameters: [
            "client_id": clientID!
            ], headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .success:
					reachLimit = false
					tableViewController.somethingWrong = false
                    isConnectedInternet = true
                    likedPhotoIDArray.remove(id)
					DispatchQueue.main.async() {
						tableViewController.likeButton.image = UIImage(named: "like-before")
					}
				case .failure(let error):
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(tableViewController)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					} else {
						if (error.localizedDescription.contains("-1009") ||
                            error.localizedDescription.contains("-1001") ||
                            error.localizedDescription.contains("-1005")) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					}
				}
			})
	}
	
	class func likePhoto(_ viewController: DetailViewController, id: String) {
        Alamofire.request("https://api.unsplash.com/photos/\(id)/like/post", method: .post, parameters: [
            "client_id": clientID!
            ], headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .success:
					reachLimit = false
					viewController.somethingWrong = false
                    isConnectedInternet = true
					likedPhotoIDArray.add(id)
					DispatchQueue.main.async() {
						viewController.likeButton.image = UIImage(named: "like-after")
					}
				case .failure(let error):
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
						} else if (statusCode == 401) {
							BaseNetworkRequest.refreshAccessToken(viewController)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					} else {
						if (error.localizedDescription.contains("-1009") ||
                            error.localizedDescription.contains("-1001") ||
                            error.localizedDescription.contains("-1005")) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					}
				}
			})
	}
	
	// MARK: get search results
	class func getSearchResults(_ tableViewController: SearchTableViewController) {
        tableViewController.isSearching = false
        tableViewController.noData = false
		if (tableViewController.page <= tableViewController.searchTotalPages || tableViewController.page == 1) {
			Alamofire.request("https://api.unsplash.com/photos/search/get", parameters: [
					"client_id": clientID!,
					"query": tableViewController.query,
					"category": "",
					"page": tableViewController.page,
					"per_page": tableViewController.searchPerItem
				]).validate().responseJSON(completionHandler: {response in
					switch response.result {
					case .success:
						reachLimit = false
						tableViewController.somethingWrong = false
                        isConnectedInternet = true
						tableViewController.refreshControl?.endRefreshing()
						if (tableViewController.page == 1) {
							tableViewController.totalItems = Int(response.response?.allHeaderFields["X-Total"] as! String)!
							if (tableViewController.totalItems == 0) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NoData"), object: nil)
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
                                photoDic["profileUrl"] = subJson["user"] ["links"]["html"].stringValue
								if (!tableViewController.photoID.contains(subJson["id"].stringValue)) {
									tableViewController.photoID.append(subJson["id"].stringValue)
									tableViewController.photosArray.append(photoDic)
								}
							}
							tableViewController.successfullyGetJsonData = true
							tableViewController.tableView.reloadData()
						}
					case .failure(let error):
                        tableViewController.refreshControl?.endRefreshing()
						if let statusCode = response.response?.statusCode {
							if statusCode == 403 {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
							} else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
							}
						} else {
							if (error.localizedDescription.contains("-1009") ||
                                error.localizedDescription.contains("-1001") ||
                                error.localizedDescription.contains("-1005")) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
							} else {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
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
	class func loadProfile(_ viewController: ProfileViewController? = nil) {
        Alamofire.request("https://api.unsplash.com/me/get", parameters: [
            "client_id": clientID!
            ], headers: [
				"Authorization": "Bearer \(keychain["access_token"]!)"]).validate().responseJSON(completionHandler: {response in
				switch response.result {
				case .success:
					reachLimit = false
                    isConnectedInternet = true
					if let value = response.result.value {
						let json = JSON(value)
						username = json["username"].stringValue
						avatarURL = json["profile_image"] ["medium"].stringValue
						if (viewController != nil) {
							DispatchQueue.main.async() {
								viewController!.avatar.sd_setImage(with: URL.init(string: avatarURL))
								viewController!.userLabel.text = username
							}
							if (!username.isEmpty) {
								NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoadLikedPhotos"), object: nil)
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoadPostPhotos"), object: nil)
							}
						} else {
							BaseNetworkRequest.getLikedPhoto()
						}
					}
				case .failure(let error):
					if let statusCode = response.response?.statusCode {
						if statusCode == 403 {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
						} else if (statusCode == 401) {
							if (viewController != nil) {
								BaseNetworkRequest.refreshAccessToken(viewController!)
							}
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					} else {
						if (error.localizedDescription.contains("-1009") ||
                            error.localizedDescription.contains("-1001") ||
                            error.localizedDescription.contains("-1005")) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
						} else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
						}
					}
				}
			})
    }
    
    // MARK: help function
    class func reachLimitNotification(_ vc:BaseTableViewController) {
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
    
    class func noNetworkNotification(_ vc:BaseTableViewController) {
        isConnectedInternet = false
        if (vc.photosArray.count == 0) {
            vc.tableView.reloadData()
        }else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Cannot connect to Internet", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 2.5)
        }
    }
    
    class func somethingWrongNotification(_ vc:BaseTableViewController) {
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
