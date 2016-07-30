//
// DetailViewController.swift
// Spatter
//
// Created by Molay on 15/12/9.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import CoreMotion
import SafariServices
import KeychainAccess
import Alamofire
import SwiftyJSON
import PKHUD

class DetailViewController: UIViewController, SFSafariViewControllerDelegate {
	var image = UIImage(named: "loading-black")
	var small = ""
	var regular = ""
	var full = ""
	var raw = ""
	var download = ""
	var creatorName = ""
	var photoID = ""
	var profileUrl = ""
	var imagePanViewController = SCImagePanViewController()
	lazy var infoBtnPopTipView: UIButton = {
		let button = UIButton()
		let image = UIImage.init(named: "bubble")
		let resizableImage = image!.resizableImageWithCapInsets(UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10), resizingMode: UIImageResizingMode.Stretch)
		button.setBackgroundImage(resizableImage, forState: .Normal)
		button.tag = 1111
		button.addTarget(self, action: #selector(self.openSafari), forControlEvents: .TouchUpInside)
		return button
	}()
	var safariVC: SFSafariViewController?
	var somethingWrong = false

	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var infoButton: UIBarButtonItem!
	@IBOutlet weak var likeButton: UIBarButtonItem!

	@IBAction func back(sender: AnyObject) {
		self.navigationController!.popViewControllerAnimated(true)
	}
	@IBAction func saveToAlbum(sender: AnyObject) {
		UIImageWriteToSavedPhotosAlbum(image!, self, #selector(DetailViewController.image(_: didFinishSavingWithError: contextInfo:)), nil)
	}
	@IBAction func likePhoto(sender: AnyObject) {
		if isConnectedInternet {
			if (NSUserDefaults.standardUserDefaults().boolForKey("isLogin")) {
				var photoDic = Dictionary<String, String>()
				photoDic["regular"] = regular
				photoDic["small"] = small
				photoDic["full"] = full
				photoDic["raw"] = raw
				photoDic["id"] = photoID
				photoDic["download"] = download
				photoDic["name"] = creatorName

				if (likedPhotoIDArray.containsObject(photoID)) {
					if (keychain["access_token"] != nil) {
						BaseNetworkRequest.unlikePhoto(self, id: photoID)
					}
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
					if (keychain["access_token"] != nil) {
						BaseNetworkRequest.likePhoto(self, id: photoID)
					}
					likeButton.image = UIImage(named: "like-after")
					likedPhotoIDArray.addObject(photoID)
					likedPhotosArray.insert(photoDic, atIndex: 0)
				}
			} else {
				let alert = UIAlertController(title: NSLocalizedString("Login", comment: ""), message: NSLocalizedString("Please login to like a photo", comment: ""), preferredStyle: .Alert)
				let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil)
				let login = UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .Default, handler: {
					(UIAlertAction) -> Void in
					self.openSafari(nil)
				})
				alert.addAction(cancel)
				alert.addAction(login)
				self.presentViewController(alert, animated: true, completion: nil)
			}
		} else {
			self.noNetwork()
		}
	}

	@IBAction func sharePhoto(sender: AnyObject) {
		let activityViewController = UIActivityViewController(activityItems: [image!], applicationActivities: nil)
		self.presentViewController(activityViewController, animated: true, completion: nil)
	}

	@IBAction func showPhotoInfo(sender: AnyObject) {
		if infoBtnPopTipView.isDescendantOfView(self.view) {
			self.removeInfoBtnPopTipView()
		} else {
			let attrs: [String: AnyObject] = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.systemFontOfSize(14), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
			infoBtnPopTipView.setAttributedTitle(NSAttributedString.init(string: "Photo by \(creatorName)", attributes: attrs), forState: .Normal)

			let size = infoBtnPopTipView.titleLabel?.attributedText?.size()
			infoBtnPopTipView.frame = CGRect(x: UIScreen.mainScreen().bounds.width - size!.width - 20, y: CGRectGetMinY(toolbar.frame) - 44, width: size!.width + 20, height: 44)
			infoBtnPopTipView.titleEdgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: 0, right: 0)

			self.addInfoBtnPopTipView()
		}
	}

	func configureData(data: [Dictionary<String, String>], withIndex index: Int) {
		regular = data[index]["regular"]!
		small = data[index]["small"]!
		full = data[index]["full"]!
		raw = data[index]["raw"]!
		download = data[index]["download"]!
		creatorName = data[index]["name"]!
		photoID = data[index]["id"]!
		profileUrl = data[index]["profileUrl"]!
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		self.loadImage()

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

		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(DetailViewController.screenEdgeSwiped(_:)))
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
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailViewController.oauthUser(_:)), name: "DismissSafariVC", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: #selector(DetailViewController.accessInternet(_:)),
			name: "CanAccessInternet",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: #selector(DetailViewController.cannotAccessInternet(_:)),
			name: "CanNotAccessInternet",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: #selector(DetailViewController.exceedLimit(_:)),
			name: "ExceedRateLimit",
			object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: #selector(DetailViewController.somethingWentWrong(_:)),
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
			JDStatusBarNotification.showWithStatus(NSLocalizedString("Image saved", comment: ""), dismissAfter: 1.5)
		} else {
			let alert = UIAlertController(title: NSLocalizedString("Failed to save image", comment: ""), message: NSLocalizedString("Please allow Spatter to access Photos in Settings app", comment: ""), preferredStyle: .Alert)
			let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil)
			let allow = UIAlertAction(title: NSLocalizedString("Allow", comment: ""), style: .Default, handler: {
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

	// MARK: swipe back
	func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .Recognized) {
			self.navigationController!.popViewControllerAnimated(true)
		}
	}

	// MARK: oauth
	func openSafari(sender: AnyObject?) {
		if sender?.tag == 1111 {
			safariVC = SFSafariViewController(URL: NSURL(string: self.profileUrl)!)
		} else {
			safariVC = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=\(clientID!)&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		}
		safariVC!.delegate = self
		self.presentViewController(safariVC!, animated: true, completion: nil)
	}

	func safariViewControllerDidFinish(controller: SFSafariViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

	func oauthUser(notification: NSNotification) {
		BaseNetworkRequest.oauth(notification, vc: self)
		if (self.safariVC != nil) {
			self.safariVC!.dismissViewControllerAnimated(true, completion: nil)
		}
	}

	// MARK: help function
	func loadImage() {
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
	}

	// MARK: notification function
	func accessInternet(notification: NSNotification) {
		isConnectedInternet = true
		if (self.image == UIImage(named: "loading-black") || self.image == UIImage(named: "noNetwork")) {
			self.loadImage()
		}
	}

	func cannotAccessInternet(notification: NSNotification) {
		isConnectedInternet = false
		if (self.image == UIImage(named: "loading-black")) {
			self.noNetwork()
		}
	}

	func exceedLimit(notification: NSNotification) {
		isConnectedInternet = true
		reachLimit = true
		somethingWrong = false

		PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Server has reached it's limit", comment: "") + "\n" + NSLocalizedString("Have a break and come back later", comment: "")))
		PKHUD.sharedHUD.show()
		PKHUD.sharedHUD.hide(afterDelay: 2.5)
	}

	func somethingWentWrong(notification: NSNotification) {
		isConnectedInternet = true
		somethingWrong = true
		reachLimit = false

		PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Oops, something went wrong", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
		PKHUD.sharedHUD.show()
		PKHUD.sharedHUD.hide(afterDelay: 2.5)
	}

	// MARK: help function
	func noNetwork() {
		PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Cannot connect to Internet", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
		PKHUD.sharedHUD.show()
		PKHUD.sharedHUD.hide(afterDelay: 2.5)

		if (self.image == UIImage(named: "loading-black")) {
			self.image = UIImage(named: "noNetwork")!
			self.imagePanViewController.configureWithImage(self.image!)
		}
	}

	func addInfoBtnPopTipView() {
		self.view.addSubview(infoBtnPopTipView)
		UIView.animateWithDuration(0.1, animations: {
			self.infoBtnPopTipView.alpha = 1.0
		}) { (finished) in
		}
	}

	func removeInfoBtnPopTipView() {
		infoBtnPopTipView.alpha = 1.0
		UIView.animateWithDuration(0.1, animations: {
			self.infoBtnPopTipView.alpha = 0.0
		}) { (finished) in
			self.infoBtnPopTipView.removeFromSuperview()
		}
	}
}