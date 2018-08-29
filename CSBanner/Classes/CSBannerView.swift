//
//  CSCarouselView.swift
//  CSCarouselView
//
//  Created by Mr.s on 2018/8/29.
//  Copyright © 2018年 Mr.s. All rights reserved.
//

import UIKit
import Dispatch

@objc class CSBannerView: UIView,UIScrollViewDelegate {
    //MARK: View
    var scrollView : UIScrollView = UIScrollView()
    var titleLabel : UILabel  = UILabel()
    var titleBgView : UIView = UIView()
    var pageControl : UIPageControl = UIPageControl()
    //MARK: timer
    private var timer : DispatchSourceTimer?
    var timeInterval = 3;
    var secondTimeExecute : Bool = false
    //MARK: closure & datasource
    var fetchContentViewForIndex : ((NSInteger)->UIView)? = nil;
    var fetchTitleForIndex : ((NSInteger)->String)? = nil;
    
    //MARK: init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.viewInit()
    }
    
    init(_ count : NSInteger) {
        super.init(frame: CGRect.zero)
        self.viewInit(count: count)
    }
    
    init(_ count : NSInteger, fetchContentViewForIndex : ((NSInteger)->UIView)? , fetchTitleForIndex : ((NSInteger)->String)?) {
        super.init(frame: CGRect.zero)
        self.viewInit(count: count ,fetchContentViewForIndex: fetchContentViewForIndex ,fetchTitleForIndex: fetchTitleForIndex)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        self.viewInit()
    }
    //MARK: sys
    deinit {
        self.timer?.cancel()
        self.timer = nil
    }
    override func layoutSubviews() {
        let frame = self.frame;
        self.scrollView.setContentOffset(CGPoint.init(x: 1.0 * self.scrollView.frame.width, y: 0), animated: true)
        self.scrollView.frame = self.bounds;
        self.scrollView.contentSize = CGSize.init(width: frame.width * 3.0, height: frame.height)
        self.titleLabel.frame = CGRect(x: 8, y: frame.height - 30, width: frame.width - 8, height: 30)
        self.titleBgView.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
    }
    
    //MARK: Custom
    func timerInit(){
        if self.timer == nil{
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
            self.timer?.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(timeInterval), leeway: DispatchTimeInterval.milliseconds(1))
            self.timer?.setEventHandler(handler: {
                DispatchQueue.main.async {
                    if self.secondTimeExecute {
                        self.pageControl.currentPage = ((self.pageControl.currentPage + 1)%self.pageControl.numberOfPages);
                        self.scrollView.setContentOffset(CGPoint.init(x: 1.0 * self.scrollView.frame.width, y: 0), animated: true)
                        self.configContentView()
                        
                    }else{
                        self.secondTimeExecute = true
                    }
                }
            })
            self.timer?.resume()
        }
    }
    func viewInit(count : NSInteger = 0,fetchContentViewForIndex : ((NSInteger)->UIView)?=nil , fetchTitleForIndex : ((NSInteger)->String)?=nil){
        self.scrollView.delegate = self
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.setContentOffset(CGPoint.init(x: 1.0 * self.scrollView.frame.width, y: 0), animated: false)
        self.addSubview(self.scrollView)
        
        self.titleBgView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.addSubview(titleBgView)
        //label
        self.titleLabel.font = UIFont.systemFont(ofSize: 12)
        self.titleLabel.textColor = UIColor.white
        self.titleLabel.backgroundColor = UIColor.clear
        self.titleLabel.text = "载入中..."
        self.addSubview(self.titleLabel)
        //pageControl
        self.pageControl.currentPage = 0
        self.pageControl.numberOfPages = count
        self.pageControl.addTarget(self, action: #selector(updateBannerView), for: UIControlEvents.valueChanged)
        self.pageControl.tintColor = UIColor.white
        self.addSubview(self.pageControl)
        self.pageControl.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[pageControl(>=80)]-8-|", options: NSLayoutFormatOptions.alignAllTrailing, metrics: nil, views: ["pageControl":self.pageControl]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[pageControl(==30)]-0-|", options: NSLayoutFormatOptions.alignAllTrailing, metrics: nil, views: ["pageControl":self.pageControl]))
        
        self.fetchContentViewForIndex = fetchContentViewForIndex
        self.fetchTitleForIndex = fetchTitleForIndex
        
        self.timerInit()
    }
    
    @objc func updateBannerView(){
        self.configContentView()
        scrollView.setContentOffset(CGPoint(x: 1.0 * self.frame.width, y: 0), animated: false)
    }
    
    func configContentView(){
        self.scrollView.subviews.forEach { (subView) in
            subView.removeFromSuperview()
        }
        if let _ = self.fetchContentViewForIndex{
            let frame = self.scrollView.bounds
            //
            let preView = self.fetchContentViewForIndex!((self.pageControl.currentPage+self.pageControl.numberOfPages-1)%self.pageControl.numberOfPages)
            self.scrollView.addSubview(preView)
            preView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            //
            let currentView = self.fetchContentViewForIndex!(self.pageControl.currentPage)
            self.scrollView.addSubview(currentView)
            currentView.frame = CGRect(x: 1.0 * frame.width, y: 0, width: frame.width, height: frame.height)
            //
            let nextView = self.fetchContentViewForIndex!((self.pageControl.currentPage+1)%self.pageControl.numberOfPages)
            self.scrollView.addSubview(nextView)
            nextView.frame = CGRect(x: 2.0 * frame.width, y: 0, width: frame.width, height: frame.height)
        }
        
        if let _ = self.fetchTitleForIndex{
            self.titleLabel.text = self.fetchTitleForIndex!(self.pageControl.currentPage)
        }
    }
    //MARK: delegate
    //MARK: ScrollView
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let idx = (NSInteger(scrollView.contentOffset.x / self.frame.width) - 1 + self.pageControl.currentPage + self.pageControl.numberOfPages)%self.pageControl.numberOfPages
        self.pageControl.currentPage = idx
        self.updateBannerView()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.timer?.suspend()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.timer?.resume()
    }
    
}

