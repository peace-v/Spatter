//
//  AboutViewController.swift
//  Spatter
//
//  Created by Molay on 16/1/28.
//  Copyright © 2016年 yuying. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    @IBOutlet weak var versionLabel: UILabel!

    @IBAction func dismissVC(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = "V\(APPVERSION)"
    }
}
