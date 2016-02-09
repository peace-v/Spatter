//
// DetailViewController.swift
// Spatter
//
// Created by Molay on 15/12/9.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import CoreMotion
import Alamofire
import SwiftyJSON
import SafariServices

class DetailViewController: UIViewController, SFSafariViewControllerDelegate {
	var image = UIImage(named: "loading-black")
	var small = ""
	var regular = ""
	var download = ""
	var creatorName = ""
	var photoID = ""
	var imagePanViewController = SCImagePanViewController()
	var infoBtnPopTipView = CMPopTipView()
	var safariVC: SFSafariViewController?
//	var code = ""
//	var isConnectedInternet = true
	
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var infoButton: UIBarButtonItem!
	@IBOutlet weak var likeButton: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		self.navigationController!.popViewControllerAnimated(true)
	}
	@IBAction func saveToAlbum(sender: AnyObject) {
		UIImageWriteToSavedPhotosAlbum(image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
	}
	@IBAction func likePhoto(sender: AnyObject) {
		if (NSUserDefaults.standardUserDefaults().boolForKey("isLogin")) {
			var photoDic = Dictionary<String, String>()
			photoDic["regular"] = regular
			photoDic["small"] = small
			photoDic["id"] = photoID
			photoDic["download"] = download
			photoDic["name"] = creatorName
			
			if (likedPhotoIDArray.containsObject(photoID)) {
				BaseNetworkRequest.unlikePhoto(self, id: photoID)
				likeButton.image = UIImage(named: "like-before")
				if (likedPhotoIDArray.containsObject(photoID)) {
					likedPhotoIDArray.removeObject(photoID)
					for (index, value) in likedPhotosArray.enumerate() {
						if (value == photoDic) {
							likedPhotosArray.removeAtIndex(index)
						}
					}
				}
			} else {
				BaseNetworkRequest.likePhoto(self, id: photoID)
				likeButton.image = UIImage(named: "like-after")
				likedPhotoIDArray.addObject(photoID)
				likedPhotosArray.append(photoDic)
			}
		} else {
			let alert = UIAlertController(title: "Login", message: "Please login to like a photo.", preferredStyle: .Alert)
			let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			let login = UIAlertAction(title: "Login", style: .Default, handler: {
					(UIAlertAction) -> Void in
					self.openSafari()
				})
			alert.addAction(cancel)
			alert.addAction(login)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	@IBAction func sharePhoto(sender: AnyObject) {
		let activityViewController = UIActivityViewController(activityItems: [image!], applicationActivities: nil)
		self.presentViewController(activityViewController, animated: true, completion: nil)
	}
	@IBAction func showPhotoInfo(sender: AnyObject) {
		infoBtnPopTipView.message = "Photo By \(creatorName)"
		infoBtnPopTipView.presentPointingAtBarButtonItem(infoButton, animated: true)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		// download the photo
		let manager = SDWebImageManager.sharedManager()
		manager.downloadImageWithURL(NSURL(string: self.regular), options: SDWebImageOptions.AvoidAutoSetImage, progress: {
				receivedSize, expectedSize in
			}, completed: {
				image, error, cacheType, finished, imageURL in
				if (image != nil) {
					self.image = image
					self.imagePanViewController.configureWithImage(self.image!)
				}
			})
		
		// transparent toolbar
		self.toolbar.setBackgroundImage(UIImage(),
			forToolbarPosition: UIBarPosition.Any,
			barMetrics: UIBarMetrics.Default)
		self.toolbar.setShadowImage(UIImage(),
			forToolbarPosition: UIBarPosition.Any)
		
		// set likeButton image
		if (NSUserDefaults.standardUserDefaults().boolForKey("isLogin")) {
			if (likedPhotoIDArray.containsObject(photoID)) {
				likeButton.image = UIImage(named: "like-after")
			} else {
				likeButton.image = UIImage(named: "like-before")
			}
		} else {
			likeButton.image = UIImage(named: "like-before")
		}
		
		// add motionView
		let motionManager = CMMotionManager()
		imagePanViewController = SCImagePanViewController(motionManager: motionManager)
		imagePanViewController.willMoveToParentViewController(self)
		
		self.addChildViewController(imagePanViewController)
		self.view.addSubview(imagePanViewController.view)
		
		imagePanViewController.view.frame = self.view.bounds
		imagePanViewController.view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
		
		imagePanViewController.didMoveToParentViewController(self)
		imagePanViewController.configureWithImage(image!)
		
		// init poplabel
		infoBtnPopTipView.dismissTapAnywhere = true
		infoBtnPopTipView.backgroundColor = UIColor.blackColor()
		infoBtnPopTipView.textColor = UIColor.whiteColor()
		infoBtnPopTipView.has3DStyle = false
		
		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: "screenEdgeSwiped:")
		edgePan.edges = .Left
		view.addGestureRecognizer(edgePan)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		self.navigationController!.setNavigationBarHidden(true, animated: false)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "oauthUser:", name: "DismissSafariVC", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "accessInternet:",
			name: "CanAccessInternet",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "cannotAccessInternet:",
			name: "CanNotAccessInternet",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "exceedLimit:",
			name: "ExceedRateLimit",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "somethingWentWrong:",
			name: "ErrorOccur",
			object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		self.navigationController!.setNavigationBarHidden(false, animated: false)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "CanAccessInternet", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "CanNotAccessInternet", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "ExceedRateLimit", object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "ErrorOccur", object: nil)
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "DismissSafariVC", object: nil)
	}
	
	// MARK: StatusBar Notificaiton
	func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafePointer<Void>) {
		if error == nil {
			JDStatusBarNotification.showWithStatus("Image saved", dismissAfter: 1.5)
		} else {
			let alert = UIAlertController(title: "Failed to save image", message: "Please allow Spatter to access Photos in Settings app.", preferredStyle: .Alert)
			let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			let allow = UIAlertAction(title: "Allow", style: .Default, handler: {
					(UIAlertAction) -> Void in
					let url = NSURL(string: UIApplicationOpenSettingsURLString)
					if (UIApplication.sharedApplication().canOpenURL(url!)) {
						UIApplication.sharedApplication().openURL(url!)
					}
				})
			alert.addAction(cancel)
			alert.addAction(allow)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	// MARK: help function
	func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .Recognized) {
			self.navigationController!.popViewControllerAnimated(true)
		}
	}
	
	// MARK: oauth
	func openSafari() {
		safariVC = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=\(clientID!)&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		safariVC!.delegate = self
		self.presentViewController(safariVC!, animated: true, completion: nil)
	}
	
	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func oauthUser(notification: NSNotification) {
		BaseNetworkRequest.oauth(notification)
		if (self.safariVC != nil) {
			self.safariVC!.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	// MARK: notification function
	func accessInternet(notification: NSNotification) {
		isConnectedInternet = true
	}
	
	func cannotAccessInternet(notification: NSNotification) {
		isConnectedInternet = false
		let alert = UIAlertController(title: "Cannot connect to Internet", message: "Pull down to refresh", preferredStyle: .Alert)
		let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
		alert.addAction(ok)
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	func exceedLimit(notification: NSNotification) {
		let alert = UIAlertController(title: "Server has reached it's limit", message: "Have a break and come back later", preferredStyle: .Alert)
		let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
		alert.addAction(ok)
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	func somethingWentWrong(notification: NSNotification) {
		let alert = UIAlertController(title: "Oops, something went wrong", message: "Pull down to refresh", preferredStyle: .Alert)
		let ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
		alert.addAction(ok)
		self.presentViewController(alert, animated: true, completion: nil)
	}
}