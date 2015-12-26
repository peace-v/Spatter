//
//  DetailViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/9.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import CoreMotion
import Whisper

class DetailViewController: UIViewController {
	let image = UIImage(named: "space")
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
        infoBtnPopTipView.message = "Creator Info"
        infoBtnPopTipView.presentPointingAtBarButtonItem(infoButton, animated: true)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		self.navigationController!.navigationBarHidden = true

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
		//        imagePanViewController.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height - 44.0)
		imagePanViewController.view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]

		imagePanViewController.didMoveToParentViewController(self)
		imagePanViewController.configureWithImage(UIImage(named: "space")!)

		// init poplabel
        infoBtnPopTipView.dismissTapAnywhere = true
        infoBtnPopTipView.backgroundColor = UIColor.blackColor()
        infoBtnPopTipView.textColor = UIColor.whiteColor()
        infoBtnPopTipView.has3DStyle = false
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
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
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        if error == nil {
            let murmur = Murmur(title: "Image Saved")
            Whistle(murmur)
        }else {
            let murmur = Murmur(title: "Failed to save image, please try again.")
            Whistle(murmur)
        }
    }
}
