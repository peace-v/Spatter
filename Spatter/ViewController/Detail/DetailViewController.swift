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
import SDWebImage

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
		let resizableImage = image!.resizableImage(withCapInsets: UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10), resizingMode: UIImageResizingMode.stretch)
		button.setBackgroundImage(resizableImage, for: UIControlState())
		button.tag = 1111
		button.addTarget(self, action: #selector(self.openSafari), for: .touchUpInside)
		return button
	}()
	var safariVC: SFSafariViewController?
	var somethingWrong = false

	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var infoButton: UIBarButtonItem!
	@IBOutlet weak var likeButton: UIBarButtonItem!

	@IBAction func back(_ sender: AnyObject) {
		self.navigationController!.popViewController(animated: true)
	}

	@IBAction func saveToAlbum(_ sender: AnyObject) {
		UIImageWriteToSavedPhotosAlbum(image!, self, #selector(DetailViewController.image(_: didFinishSavingWithError: contextInfo:)), nil)
	}

	@IBAction func likePhoto(_ sender: AnyObject) {
		if isConnectedInternet {
			if (UserDefaults.standard.bool(forKey: "isLogin")) {
				var photoDic = Dictionary<String, String>()
				photoDic["regular"] = regular
				photoDic["small"] = small
				photoDic["full"] = full
				photoDic["raw"] = raw
				photoDic["id"] = photoID
				photoDic["download"] = download
				photoDic["name"] = creatorName

				if (likedPhotoIDArray.contains(photoID)) {
					if (keychain["access_token"] != nil) {
						BaseNetworkRequest.unlikePhoto(self, id: photoID)
					}
					likeButton.image = UIImage(named: "like-before")
					if (likedPhotoIDArray.contains(photoID)) {
						likedPhotoIDArray.remove(photoID)
						for (index, value) in likedPhotosArray.enumerated() {
							if (value == photoDic) {
								likedPhotosArray.remove(at: index)
							}
						}
					}
				} else {
					if (keychain["access_token"] != nil) {
						BaseNetworkRequest.likePhoto(self, id: photoID)
					}
					likeButton.image = UIImage(named: "like-after")
					likedPhotoIDArray.add(photoID)
					likedPhotosArray.insert(photoDic, at: 0)
				}
			} else {
				let alert = UIAlertController(title: NSLocalizedString("Login", comment: ""), message: NSLocalizedString("Please login to like a photo", comment: ""), preferredStyle: .alert)
				let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
				let login = UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default, handler: {
					(UIAlertAction) -> Void in
					self.openSafari(nil)
				})
				alert.addAction(cancel)
				alert.addAction(login)
				self.present(alert, animated: true, completion: nil)
			}
		} else {
			self.noNetwork()
		}
	}

	@IBAction func sharePhoto(_ sender: AnyObject) {
		let activityViewController = UIActivityViewController(activityItems: [image!], applicationActivities: nil)
		self.present(activityViewController, animated: true, completion: nil)
	}

	@IBAction func showPhotoInfo(_ sender: AnyObject) {
		if infoBtnPopTipView.isDescendant(of: self.view) {
			self.removeInfoBtnPopTipView()
		} else {
			let attrs: [String: AnyObject] = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue as AnyObject]
			infoBtnPopTipView.setAttributedTitle(NSAttributedString.init(string: "Photo by \(creatorName)", attributes: attrs), for: UIControlState())

			let size = infoBtnPopTipView.titleLabel?.attributedText?.size()
			infoBtnPopTipView.frame = CGRect(x: UIScreen.main.bounds.width - size!.width - 20, y: toolbar.frame.minY - 44, width: size!.width + 20, height: 44)
			infoBtnPopTipView.titleEdgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: 0, right: 0)

			self.addInfoBtnPopTipView()
		}
	}

	func configureData(_ data: [Dictionary<String, String>], withIndex index: Int) {
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
		self.loadImage()

		// transparent toolbar
		self.toolbar.setBackgroundImage(UIImage(),
			forToolbarPosition: UIBarPosition.any,
			barMetrics: UIBarMetrics.default)
		self.toolbar.setShadowImage(UIImage(),
			forToolbarPosition: UIBarPosition.any)

		// set likeButton image
		if (UserDefaults.standard.bool(forKey: "isLogin")) {
			if (likedPhotoIDArray.contains(photoID)) {
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
		imagePanViewController.willMove(toParentViewController: self)

		self.addChildViewController(imagePanViewController)
		self.view.addSubview(imagePanViewController.view)
        
		imagePanViewController.view.frame = self.view.bounds
		imagePanViewController.view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]

		imagePanViewController.didMove(toParentViewController: self)
		imagePanViewController.configure(with: image!)

		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(DetailViewController.screenEdgeSwiped(_:)))
		edgePan.edges = .left
		view.addGestureRecognizer(edgePan)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: true)
        
		NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.oauthUser(_:)), name: NSNotification.Name(rawValue: "DismissSafariVC"), object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(DetailViewController.accessInternet(_:)),
			name: NSNotification.Name(rawValue: "CanAccessInternet"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(DetailViewController.cannotAccessInternet(_:)),
			name: NSNotification.Name(rawValue: "CanNotAccessInternet"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(DetailViewController.exceedLimit(_:)),
			name: NSNotification.Name(rawValue: "ExceedRateLimit"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(DetailViewController.somethingWentWrong(_:)),
			name: NSNotification.Name(rawValue: "ErrorOccur"),
			object: nil)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: true)
        
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CanAccessInternet"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ExceedRateLimit"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ErrorOccur"), object: nil)
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "DismissSafariVC"), object: nil)
	}

	// MARK: StatusBar Notificaiton

	func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
		if error == nil {
			JDStatusBarNotification.show(withStatus: NSLocalizedString("Image saved", comment: ""), dismissAfter: 1.5)
		} else {
			let alert = UIAlertController(title: NSLocalizedString("Failed to save image", comment: ""), message: NSLocalizedString("Please allow Spatter to access Photos in Settings app", comment: ""), preferredStyle: .alert)
			let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
			let allow = UIAlertAction(title: NSLocalizedString("Allow", comment: ""), style: .default, handler: {
				(UIAlertAction) -> Void in
				let url = URL(string: UIApplicationOpenSettingsURLString)
				if (UIApplication.shared.canOpenURL(url!)) {
					UIApplication.shared.openURL(url!)
				}
			})
			alert.addAction(cancel)
			alert.addAction(allow)
			self.present(alert, animated: true, completion: nil)
		}
	}

	// MARK: swipe back

	func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .recognized) {
			self.navigationController!.popViewController(animated: true)
		}
	}

	// MARK: oauth

	func openSafari(_ sender: AnyObject?) {
		if sender?.tag == 1111 {
			safariVC = SFSafariViewController(url: URL(string: self.profileUrl)!)
		} else {
			safariVC = SFSafariViewController(url: URL(string: "https://unsplash.com/oauth/authorize?client_id=\(clientID!)&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user+write_user+read_photos+write_photos+write_likes")!)
		}
		safariVC!.delegate = self
		self.present(safariVC!, animated: true, completion: nil)
	}

	func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		controller.dismiss(animated: true, completion: nil)
	}

	func oauthUser(_ notification: Notification) {
		BaseNetworkRequest.oauth(notification, vc: self)
		if (self.safariVC != nil) {
			self.safariVC!.dismiss(animated: true, completion: nil)
		}
	}

	// MARK: notification function

	func accessInternet(_ notification: Notification) {
		isConnectedInternet = true
		if (self.image == UIImage(named: "loading-black") || self.image == UIImage(named: "noNetwork")) {
			self.loadImage()
		}
	}

	func cannotAccessInternet(_ notification: Notification) {
		isConnectedInternet = false
		if (self.image == UIImage(named: "loading-black")) {
			self.noNetwork()
		}
	}

	func exceedLimit(_ notification: Notification) {
		isConnectedInternet = true
		reachLimit = true
		somethingWrong = false

		PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Server has reached it's limit", comment: "") + "\n" + NSLocalizedString("Have a break and come back later", comment: "")))
		PKHUD.sharedHUD.show()
		PKHUD.sharedHUD.hide(afterDelay: 2.5)
	}

	func somethingWentWrong(_ notification: Notification) {
		isConnectedInternet = true
		somethingWrong = true
		reachLimit = false

		PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Oops, something went wrong", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
		PKHUD.sharedHUD.show()
		PKHUD.sharedHUD.hide(afterDelay: 2.5)
	}

	// MARK: help function

    func loadImage() {
        SDWebImageManager.shared().loadImage(with: URL(string: self.regular), options: [SDWebImageOptions.avoidAutoSetImage,], progress: nil) { (image, data, error, _, _, _) in
            if image != nil {
                self.image = image
                self.imagePanViewController.configure(with: self.image!)
            }
        }
    }

	func noNetwork() {
		PKHUD.sharedHUD.contentView = PKHUDTextView(text: (NSLocalizedString("Cannot connect to Internet", comment: "") + "\n" + NSLocalizedString("Please try again", comment: "")))
		PKHUD.sharedHUD.show()
		PKHUD.sharedHUD.hide(afterDelay: 2.5)

		if (self.image == UIImage(named: "loading-black")) {
			self.image = UIImage(named: "noNetwork")!
			self.imagePanViewController.configure(with: self.image!)
		}
	}

	func addInfoBtnPopTipView() {
		self.view.addSubview(infoBtnPopTipView)
		UIView.animate(withDuration: 0.1, animations: {
			self.infoBtnPopTipView.alpha = 1.0
		}, completion: { (finished) in
		}) 
	}

	func removeInfoBtnPopTipView() {
		infoBtnPopTipView.alpha = 1.0
		UIView.animate(withDuration: 0.1, animations: {
			self.infoBtnPopTipView.alpha = 0.0
		}, completion: { (finished) in
			self.infoBtnPopTipView.removeFromSuperview()
		}) 
	}
}
