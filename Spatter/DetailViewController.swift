//
//  DetailViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/9.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

	@IBOutlet weak var viewForMotionImage: UIView!
	@IBOutlet weak var toolbar: UIToolbar!

	@IBAction func back(sender: AnyObject) {
		self.navigationController!.popViewControllerAnimated(true)
	}
	@IBAction func saveToAlbum(sender: AnyObject) {
	}
	@IBAction func likePhoto(sender: AnyObject) {
	}
	@IBAction func sharePhoto(sender: AnyObject) {
	}
	@IBAction func showPhotoInfo(sender: AnyObject) {
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		// self.navigationController!.navigationBarHidden = true

//		let motionView = PanoramaView(frame: self.viewForMotionImage.bounds)
//		motionView.setImage(UIImage(named: "space")!)
//		self.viewForMotionImage.addSubview(motionView)
        
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

}
