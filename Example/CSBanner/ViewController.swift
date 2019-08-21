//
//  ViewController.swift
//  CSBanner
//
//  Created by stqemail@163.com on 08/29/2018.
//  Copyright (c) 2018 stqemail@163.com. All rights reserved.
//

import UIKit
import CSBanner
class ViewController: UIViewController,CSBannerViewDatasource,CSBannerViewDelegate {
    @IBOutlet weak var bannerView: CSBannerView!
    
    let testView = UIView(frame: CGRect.init(x: 0, y: 300, width: 20, height: 20))
    let delta = 1
    var timer : Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.itemCount = 10
        bannerView.datasource = self
        bannerView.delegate = self
        bannerView.itemWidth = UIScreen.main.bounds.size.width - 64.0 * 2.0;
        bannerView.itemHeight = min(160.0,UIScreen.main.bounds.size.width * 0.5);
        bannerView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func stopScroll(_ sender: Any) {

    }
    
    @IBAction func restartScroll(_ sender: Any) {
        
    }
    
    //
    func itemViewForIndex(index: Int) -> UIView {
        let lb = UILabel.init()
        lb.text = "\(index)"
        lb.font = .systemFont(ofSize: 40)
        lb.textAlignment = .center
        lb.backgroundColor = .purple
        return lb
    }
    
    func didSelectItemForIndex(index: Int) {
        print("select \(index)")
    }
}

