//
//  BaseCollectionViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/13.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import SnapKit

private let reuseIdentifier = "Cell"

class BaseCollectionViewController: UICollectionViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Register cell classes
		self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

		// Do any additional setup after loading the view.
		self.collectionView!.backgroundColor = UIColor.whiteColor()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using [segue destinationViewController].
	 // Pass the selected object to the new view controller.
	 }
	 */

	// MARK: UICollectionViewDataSource

	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}


	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of items
		return 300
	}

	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)

		// Configure the cell
		var imageView = cell.contentView.viewWithTag(100) as? UIImageView
		if imageView == nil {
			imageView = UIImageView(image: UIImage(named: "placeholder"))
			imageView!.snp_makeConstraints {(make) -> Void in
				make.width.equalTo(cell.bounds.width)
				make.height.equalTo(cell.bounds.height)
			}
			imageView!.tag = 100
			imageView!.contentMode = .ScaleAspectFit
			cell.contentView.addSubview(imageView!)
		}
		//		imageView!.image = UIImage(named: "placeholder")
		return cell
	}

	// MARK: UICollectionViewDelegate

	/*
	 // Uncomment this method to specify if the specified item should be highlighted during tracking
	 override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
	 return true
	 }
	 */

	/*
	 // Uncomment this method to specify if the specified item should be selected
	 override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
	 return true
	 }
	 */

	/*
	 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
	 override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
	 return false
	 }

	 override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
	 return false
	 }

	 override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {

	 }
	 */

	//MARK: FLowLayout Delegate
	func collectionView(collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return CGSizeMake(self.collectionView!.frame.width, self.collectionView!.frame.width / 1.5)
	}

	func collectionView(collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		insetForSectionAtIndex section: Int) -> UIEdgeInsets {
		return UIEdgeInsetsMake(10, 0, 0, 0)
	}

	func collectionView(collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}

	func collectionView(collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
}
