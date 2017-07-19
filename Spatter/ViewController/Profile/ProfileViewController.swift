//
// ProfileViewController.swift
// Spatter
//
// Created by Molay on 15/12/9.
// Copyright © 2015年 yuying. All rights reserved.
//

import UIKit
import PagingMenuController
import Alamofire
import SwiftyJSON
import KeychainAccess

class ProfileViewController: UIViewController {
	
	var viewControllers: [UIViewController] = []
    var somethingWrong = false
	
	@IBOutlet weak var userLabel: UILabel!
	@IBOutlet weak var avatar: UIImageView!
	@IBOutlet weak var backBtn: UIBarButtonItem!
	
	@IBAction func back(_ sender: AnyObject) {
		self.navigationController!.dismiss(animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
        if (keychain["access_token"] != nil) {
		BaseNetworkRequest.loadProfile(self)
        }
		
		avatar.layer.masksToBounds = true
		let avatarWidth = CGFloat(44.0)
		avatar.layer.cornerRadius = avatarWidth / 2
		
		// add pagingMenu
		let likedTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "liked") as! LikedTableViewController
		likedTableViewController.title = NSLocalizedString("Like", comment: "")
		let postTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "post") as! PostTableViewController
		postTableViewController.title = NSLocalizedString("Post", comment: "")
		viewControllers = [likedTableViewController, postTableViewController]

        struct MenuItem1: MenuItemViewCustomizable {
            var displayMode: MenuItemDisplayMode {
                let title = MenuItemText(text: "Like")
                let description = MenuItemText(text: String(describing: self))
                return .multilineText(title: title, description: description)
            }
        }
        struct MenuItem2: MenuItemViewCustomizable {
            var displayMode: MenuItemDisplayMode {
                let title = MenuItemText(text: "Post")
                let description = MenuItemText(text: String(describing: self))
                return .multilineText(title: title, description: description)
            }
        }

        struct MenuOptions: MenuViewCustomizable {
            var itemsOptions: [MenuItemViewCustomizable] {
                return [MenuItem1(), MenuItem2()]
            }
            var height: CGFloat = 44
//            var displayMode: MenuDisplayMode = MenuDisplayMode.infinite(widthMode: .fixed(width: UIScreen.main.bounds.size.width/2), scrollingMode: .scrollEnabled)
            var displayMode: MenuDisplayMode = MenuDisplayMode.segmentedControl
            var focusMode: MenuFocusMode = MenuFocusMode.underline(height: 2, color: UIColor.black, horizontalPadding: 0, verticalPadding: 5)
            var menuPosition: MenuPosition = .top
        }

        struct PagingMenuOptions: PagingMenuControllerCustomizable {
            var componentType: ComponentType {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                return .all(menuOptions: MenuOptions(), pagingControllers: [storyboard.instantiateViewController(withIdentifier: "liked") as! LikedTableViewController, storyboard.instantiateViewController(withIdentifier: "post") as! PostTableViewController])
            }
            var defaultPage: Int = 0
        }
        
        let options = PagingMenuOptions()
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.setup(options)
        pagingMenuController.onMove = { [weak self, weak pagingMenuController] (state) in
            switch state {
            case .willMoveController(_, _):
                break
            case .didMoveController(_, _):
                guard let strongSelf = self else {return}
                if pagingMenuController != nil {
                    let totalViewControllers = strongSelf.viewControllers.count - 1
                    for num in 0...totalViewControllers {
                        let currentViewController: UITableViewController = strongSelf.viewControllers[num] as! UITableViewController
                        if num == pagingMenuController?.currentPage {
                            currentViewController.tableView.scrollsToTop = true
                        } else {
                            currentViewController.tableView.scrollsToTop = false
                        }
                    }
                }
            case .willMoveItem(_, _):
                break
            case .didMoveItem(_, _):
                break
            case .didScrollStart:
                break
            case .didScrollEnd:
                break
            }
        }
		
		// add screenEdgePanGesture
		let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ProfileViewController.screenEdgeSwiped(_:)))
		edgePan.edges = .left
		view.addGestureRecognizer(edgePan)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		NotificationCenter.default.addObserver(self,
			selector: #selector(ProfileViewController.accessInternet(_:)),
			name: NSNotification.Name(rawValue: "CanAccessInternet"),
			object: nil)
		NotificationCenter.default.addObserver(self,
			selector: #selector(ProfileViewController.cannotAccessInternet(_:)),
			name: NSNotification.Name(rawValue: "CanNotAccessInternet"),
			object: nil)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(true)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CanAccessInternet"), object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CanNotAccessInternet"), object: nil)
	}
	
    // MARK: swipe back
	func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
		if (recognizer.state == .recognized) {
			self.navigationController!.dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: notification function
	func accessInternet(_ notification: Notification) {
		isConnectedInternet = true
		BaseNetworkRequest.loadProfile(self)
	}
	
	func cannotAccessInternet(_ notification: Notification) {
		isConnectedInternet = false
	}
}
