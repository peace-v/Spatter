//
//  MainViewController.swift
//  Spatter
//
//  Created by Molay on 15/12/8.
//  Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import SafariServices
import PagingMenuController

class MainViewController: UIViewController, SFSafariViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let dailyTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("daily") as! DailyTableViewController
        dailyTableViewController.title = "Daily"
        let buildingsTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("buildings") as! BuildingsTableViewController
        buildingsTableViewController.title = "Buildings"
        let foodTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("food") as! FoodTableViewController
        foodTableViewController.title = "Food"
        let natureTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("nature") as! NatureTableViewController
        natureTableViewController.title = "Nature"
        let peopleTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("people") as! PeopleTableViewController
        peopleTableViewController.title = "People"
        let technologyTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("technology") as! TechnologyTableViewController
        technologyTableViewController.title = "Technology"
        let objectsTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("objects") as! ObjectsTableViewController
        objectsTableViewController.title = "Objects"
        let viewControllers = [dailyTableViewController,buildingsTableViewController,foodTableViewController,natureTableViewController,peopleTableViewController,technologyTableViewController,objectsTableViewController]
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        
        let options = PagingMenuOptions()
        options.menuHeight = 44
        options.menuDisplayMode = .Infinite(widthMode: .Flexible)
        options.defaultPage = 0
        options.scrollEnabled = true
        options.menuItemMode = .Underline(height: 3, color: UIColor.orangeColor(), horizontalPadding: 0, verticalPadding: 0)
        pagingMenuController.setup(viewControllers: viewControllers, options: options)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openSafari(sender: AnyObject) {
        if #available(iOS 9.0, *) {
            let svc = SFSafariViewController(URL: NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user")!)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.sharedApplication().openURL(NSURL(string: "https://unsplash.com/oauth/authorize?client_id=cfda40dc872056077a4baab01df44629708fb3434f2e15a565cef75cc2af105d&redirect_uri=spatter://com.yuying.spatter&response_type=code&scope=public+read_user")!)
        }
    }
    
    //MARK: SFSafariViewControllerDelegate
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
