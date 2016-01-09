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

class DetailViewController: UIViewController {
	var image = UIImage(named: "loading")
	var downloadURL = ""
	var creatorName = ""
	var imagePanViewController = SCImagePanViewController()
	var infoBtnPopTipView = CMPopTipView()
	
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var infoButton: UIBarButtonItem!
	
	@IBAction func back(sender: AnyObject) {
		self.navigationController!.popViewControllerAnimated(true)
	}
	@IBAction func saveToAlbum(sender: AnyObject) {
		UIImageWriteToSavedPhotosAlbum(image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
	}
	@IBAction func likePhoto(sender: AnyObject) {
		
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
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		self.navigationController!.navigationBarHidden = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(true)
		self.navigationController!.navigationBarHidden = false
	}
	
	
	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using segue.destinationViewController.
	 // Pass the selected object to the new view controller.
	 }
	 */
	
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
}
