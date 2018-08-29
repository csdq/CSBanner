//
//  ViewController.swift
//  CSBanner
//
//  Created by stqemail@163.com on 08/29/2018.
//  Copyright (c) 2018 stqemail@163.com. All rights reserved.
//

import UIKit
import CSBanner
class ViewController: UIViewController {
    @IBOutlet weak var bannerView: CSBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bannerView.bannerCount = 3;
        self.bannerView.fetchContentViewForIndex = {(pageIndex)->UIView in
            let imgView = UIImageView()
            imgView.image = nil
            imgView.tag = pageIndex
            imgView.backgroundColor = [UIColor.red,UIColor.green,UIColor.blue][pageIndex]
            return imgView
        }
        
        self.bannerView.fetchTitleForIndex = {(pageIndex)->String in
            return ["ここは　example","It is an example","这是一个测试例子"][pageIndex]
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

