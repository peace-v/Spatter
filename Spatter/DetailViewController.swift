//
// DetailViewController.swift
// Spatter
//
// Created by Molay on 15/12/9.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import CoreMotion
import Whisper
import Alamofire
import SwiftyJSON
import SafariServices

class DetailViewController: UIViewController, SFSafariViewControllerDelegate {
	var image = UIImage(named: "loading")
	var downloadURL = ""
	var creatorName = ""
	var photoID = ""
	var imagePanViewController = SCImagePanViewController()
	var infoBtnPopTipView = CMPopTipView()
	var safariVC: SFSafariViewController?
	var code = ""
	var isLiked = false
	
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var infoButton: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		self.navigationController!.popViewControllerAnimated(true)
	}
	@IBAction func saveToAlbum(sender: AnyObject) {
		UIImageWriteToSavedPhotosAlbum(image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
	}
	@IBAction func likePhoto(sender: AnyObject) {
		if (NSUserDefaults.standardUserDefaults().boolForKey("isLogin")) {
			if isLiked {
				Alamofire.request(.DELETE, "https://api.unsplash.com/photos/\(self.photoID)/like", headers: [
						"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
						"client_id": clientID!
					]).validate().responseJSON(completionHandler: {response in
						switch response.result {
						case .Success:
							if let value = response.result.value {
								let json = JSON(value)
								print("JSON:\(json)")
							}
						case .Failure(let error):
							print(error)
						}
					})
			} else {
				Alamofire.request(.POST, "https://api.unsplash.com/photos/\(self.photoID)/like", headers: [
						"Authorization": "Bearer \(keychain["access_token"]!)"], parameters: [
						"client_id": clientID!
					]).validate().responseJSON(completionHandler: {response in
						switch response.result {
						case .Success:
							if let value = response.result.value {
								let json = JSON(value)
								print("JSON:\(json)")
							}
						case .Failure(let error):
							print(error)
						}
					})
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
		manager.downloadImageWithURL(NSURL(string: self.downloadURL), options: SDWebImageOptions.AvoidAutoSetImage, progress: {
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
		
		// test
		if (photoIDArray.contains(self.photoID)) {
			isLiked = true
		}
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		self.navigationController!.setNavigationBarHidden(true, animated: false)
//		self.navigationController!.navigationBarHidden = true
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "oauthUser:", name: "DismissSafariVC", object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		self.navigationController!.setNavigationBarHidden(false, animated: false)
//		self.navigationController!.navigationBarHidden = false
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: "DismissSafariVC", object: nil)
	}
	
	// MARK: Whisper
	func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafePointer<Void>) {
		if error == nil {
			let murmur = Murmur(title: "Image Saved")
			Whistle(murmur)
		} else {
			let murmur = Murmur(title: "Failed to save image, please try again.")
			Whistle(murmur)
		}
	}
	
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
		let url = notification.object as! NSURL
		let urlString = url.absoluteString
		if (urlString.containsString("code")) {
			let urlArray = urlString.componentsSeparatedByString("=")
			code = urlArray[1]
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isLogin")
			NSUserDefaults.standardUserDefaults().synchronize()
			// isLogin = true
			
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
						}
					case .Failure(let error):
						print(error)
					}
				})
		}
		if (self.safariVC != nil) {
			self.safariVC!.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
}
