//
// MainViewController.swift
// Spatter
//
// Created by Molay on 15/12/8.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI
import AMScrollingNavbar
import Alamofire
import SwiftyJSON
import SDWebImage

let APPVERSION:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

class MainViewController: BaseTableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    var isNavHidden = false {
        didSet {
            UIApplication.shared.isStatusBarHidden = isNavHidden
            self.navigationController!.setNavigationBarHidden(isNavHidden, animated: true)
        }
    }

	var menuItemsAlreadyLogin: [RWDropdownMenuItem] = []
	var menuItemsWithoutLogin: [RWDropdownMenuItem] = []
	var safariVC: SFSafariViewController?
	let aboutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "about")
	
	@IBAction func showMenu(_ sender: AnyObject) {
		if (UserDefaults.standard.bool(forKey: "isLogin")) {
			RWDropdownMenu.present(from: self, withItems: menuItemsAlreadyLogin, align: .center, style: .blackGradient, navBarImage: nil, completion: nil)
		} else {
			RWDropdownMenu.present(from: self, withItems: menuItemsWithoutLogin, align: .center, style: .blackGradient, navBarImage: nil, completion: nil)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

        // configure refreshControl
        self.refreshControl!.addTarget(self, action: #selector(MainViewController.refreshData), for: .valueChanged)
        footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(MainViewController.getCollections))
        footer.isRefreshingTitleHidden = true
        self.tableView.mj_footer = footer
        
		// init menuItem
		menuItemsAlreadyLogin = [
			RWDropdownMenuItem(text: NSLocalizedString("Profile",comment:""), image: nil, action: {
					self.navigationController!.present(self.storyboard!.instantiateViewController(withIdentifier: "profileNavController"), animated: true, completion: nil)
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Logout", comment: ""), image: nil, action: {
                MainViewController.logout()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Clear Cache", comment: ""), image: nil, action: {
					SDImageCache.shared().clearDisk()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Feedback", comment: ""), image: nil, action: {
					self.sendFeedback("Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				}),
			RWDropdownMenuItem(text: NSLocalizedString("About", comment: ""), image: nil, action: {
					self.present(self.aboutVC, animated: true, completion: nil)
				})]
		
		menuItemsWithoutLogin = [
			RWDropdownMenuItem(text: NSLocalizedString("Login", comment: ""), image: nil, action: {
					self.openSafari()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Clear Cache", comment: ""), image: nil, action: {
					SDImageCache.shared().clearDisk()
				}),
			RWDropdownMenuItem(text: NSLocalizedString("Feedback", comment: ""), image: nil, action: {
					self.sendFeedback("Spatter Feedback", recipients: ["molayyu@gmail.com"], appVersion: APPVERSION)
				}),
			RWDropdownMenuItem(text: NSLocalizedString("About", comment: ""), image: nil, action: {
					self.present(self.aboutVC, animated: true, completion: nil)
				})]
		
		BaseNetworkRequest.getCollections(self)
        
        // check the network condition when launch
        let reach = TMReachability.forInternetConnection()
        reach!.reachableOnWWAN = false
		reach!.startNotifier()
        if reach!.isReachableViaWiFi() || reach!.isReachableViaWWAN() {
            isConnectedInternet = true
        }else {
            isConnectedInternet = false
            if (self.photosArray.count == 0) {
                self.tableView.reloadData()
            }
        }
        reach!.stopNotifier()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        isNavHidden = false
		
		NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.oauthUser(_:)), name: NSNotification.Name(rawValue: "DismissSafariVC"), object: nil)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isNavHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isNavHidden = false
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "DismissSafariVC"), object: nil)
	}

	// MARK: tableView delegate

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "showFeaturedPhoto") {
			let detailViewController = segue.destination as! DetailViewController
			let cell = sender as? UITableViewCell
			let indexPath = self.tableView.indexPath(for: cell!)
			detailViewController.configureData(self.photosArray,withIndex: (indexPath?.row)!)
		}
	}
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
        if velocity.y > 0 {
            // 下拉
            isNavHidden = false
        } else if velocity.y < 0 {
            // 上拉
            isNavHidden = true
        }
    }
	
    // MARK: safari

	func openSafari() {
		safariVC = SFSafariViewController(url: URL(string: "https://unsplash.com/oauth/authorize?client_id=\(clientID!)&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		safariVC!.delegate = self
		self.present(safariVC!, animated: true, completion: nil)
	}
	
	func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		controller.dismiss(animated: true, completion: nil)
	}
	
	@objc func oauthUser(_ notification: Notification) {
		BaseNetworkRequest.oauth(notification, vc:self)
		if (self.safariVC != nil) {
			self.safariVC!.dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: MFMailComposeViewControllerDelegate

	func sendFeedback(_ subject: String, recipients: [String], appVersion: String) {
		if (MFMailComposeViewController.canSendMail()) {
			let picker = MFMailComposeViewController()
			picker.mailComposeDelegate = self
			picker.setSubject(subject)
			picker.setToRecipients(recipients)
			let iOSVersion = UIDevice.current.systemVersion
			let deviceModal = UIDevice.current.model
			let body = "App version: \(appVersion)\niOS version: \(iOSVersion)\nDevice modal: \(deviceModal)\n"
			picker.setMessageBody(body, isHTML: false)
			self.present(picker, animated: true, completion: nil)
		} else {
			let alert = UIAlertController(title: NSLocalizedString("Cannot sent email", comment: ""), message: NSLocalizedString("Please check the system email setting", comment: ""), preferredStyle: .alert)
			let ok = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
			alert.addAction(ok)
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		self.dismiss(animated: true, completion: nil)
	}
    
    // MARK: refresh methods

    @objc func getCollections() {
        BaseNetworkRequest.getCollections(self)
    }
    
    @objc func refreshData() {
        self.collcectionsArray = []
        self.photosArray = []
        self.page = 1
        let cache = URLCache.shared
        cache.removeAllCachedResponses()
        BaseNetworkRequest.getCollections(self)
    }
    
    // MARK: help function

    class func logout() {
        UserDefaults.standard.set(false, forKey: "isLogin")
        UserDefaults.standard.synchronize()
        keychain["access_token"] = nil
        keychain["refresh"] = nil
        likedPhotoIDArray = []
        likedPhotosArray = []
        likedTotalItems = 0
        BaseNetworkRequest.likedPage = 1
        username = ""
        avatarURL = ""
    }
    
    
    // MARK: network notificaiton
    
    override func accessInternet(_ notification: Notification) {
        isConnectedInternet = true
        self.tableView.reloadData()
        if (self.photosArray.count == 0){
        BaseNetworkRequest.getCollections(self)
        }
    }
}
