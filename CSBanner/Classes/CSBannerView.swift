//
//  CSBannerView.swift
//  CSBannerView
//
//  Created by Mr.s on 2018/8/29.
//  Copyright © 2018年 Mr.s. All rights reserved.
//

import UIKit
import Dispatch

@objc public class CSBannerView: UIView,UIScrollViewDelegate {
    //MARK: View
    public var scrollView : UIScrollView = UIScrollView()
    public var titleLabel : UILabel  = UILabel()
    var titleBgView : UIView = UIView()
    public var bannerCount : Int {
        set{
            self.pageControl.numberOfPages = newValue
        }
        get{
            return self.pageControl.numberOfPages
        }
    }
    var pageControl : UIPageControl = UIPageControl()
    //MARK: timer
    private var timer : DispatchSourceTimer?
    var timeInterval = 5;
    var firstTimeExecute : Bool = true
    //MARK: closure & datasource
    
    ///  get banner view for every page
    public var fetchContentViewForIndex : ((NSInteger)->UIView)? = nil;
    
    /// get banner title for each page
    public var fetchTitleForIndex : ((NSInteger)->String)? = nil;
    
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
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        self.viewInit()
    }
    //MARK: sys
    deinit {
        self.timer?.cancel()
        self.timer = nil
    }
    override public func layoutSubviews() {
        let frame = self.frame;
        self.scrollView.setContentOffset(CGPoint.init(x: 1.0 * self.scrollView.frame.width, y: 0), animated: true)
        self.scrollView.frame = self.bounds;
        self.scrollView.contentSize = CGSize.init(width: frame.width * 3.0, height: frame.height)
        self.titleLabel.frame = CGRect(x: 8, y: frame.height - 30, width: frame.width - 8, height: 30)
        self.titleBgView.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
        if self.firstTimeExecute{
            self.scrollView.setContentOffset(CGPoint.init(x: 1.0 * self.scrollView.frame.width, y: 0), animated: false)
            self.configContentView()
        }
    }
    
    //MARK: Custom
    func timerInit(){
        if self.timer == nil{
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
            #if swift(>=4.0)
            self.timer?.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(timeInterval), leeway: DispatchTimeInterval.milliseconds(10))
            #else
            self.timer?.scheduleRepeating(deadline: DispatchTime.now(), interval: DispatchTimeInterval.seconds(timeInterval), leeway: DispatchTimeInterval.milliseconds(10))
            #endif
            self.timer?.setEventHandler(handler: {
                DispatchQueue.main.async {
                    if !self.firstTimeExecute {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.scrollView.setContentOffset(CGPoint.init(x: 2.0 * self.scrollView.frame.width, y: 0), animated: false)
                        }, completion: { (finished) in
                            //Caculate next page
                            self.pageControl.currentPage = ((self.pageControl.currentPage + 1)%self.pageControl.numberOfPages);
                            self.configContentView()
                        })
                        
                    }else{
                        self.firstTimeExecute = false
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
    
    //MARK: Public
    public func stopAutoScroll(){
        if let _ = self.timer{
            if let _ = self.timer?.isCancelled{
                
            }else{
                self.timer?.cancel()
            }
            self.timer = nil
        }
    }
    
    public func resumeAutoScroll(){
        if let _ = self.timer{
            
        }else{
            self.timerInit()
        }
    }
    
    //
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
            if(self.pageControl.numberOfPages == 0){
                let preView = self.fetchContentViewForIndex!(0)
                self.scrollView.addSubview(preView)
                preView.frame = CGRect(x: 0.0 * frame.width, y: 0, width: frame.width, height: frame.height)
                //
                let currentView = self.fetchContentViewForIndex!(self.pageControl.currentPage)
                self.scrollView.addSubview(currentView)
                currentView.frame = CGRect(x: 1.0 * frame.width, y: 0, width: frame.width, height: frame.height)
                //
                let nextView = self.fetchContentViewForIndex!(0)
                self.scrollView.addSubview(nextView)
                nextView.frame = CGRect(x: 2.0 * frame.width, y: 0, width: frame.width, height: frame.height)
            }else{
                let preView = self.fetchContentViewForIndex!((self.pageControl.currentPage+self.pageControl.numberOfPages-1)%self.pageControl.numberOfPages)
                self.scrollView.addSubview(preView)
                preView.frame = CGRect(x: 0.0 * frame.width, y: 0, width: frame.width, height: frame.height)
                //
                let currentView = self.fetchContentViewForIndex!(self.pageControl.currentPage)
                self.scrollView.addSubview(currentView)
                currentView.frame = CGRect(x: 1.0 * frame.width, y: 0, width: frame.width, height: frame.height)
                //
                let nextView = self.fetchContentViewForIndex!((self.pageControl.currentPage+1)%self.pageControl.numberOfPages)
                self.scrollView.addSubview(nextView)
                nextView.frame = CGRect(x: 2.0 * frame.width, y: 0, width: frame.width, height: frame.height)
            }
        }
        
        if let _ = self.fetchTitleForIndex{
            self.titleLabel.text = self.fetchTitleForIndex!(self.pageControl.currentPage)
        }
         self.scrollView.setContentOffset(CGPoint.init(x: 1.0 * self.scrollView.frame.width, y: 0), animated: false)
    }
    //MARK: delegate
    //MARK: ScrollView
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if(self.pageControl.numberOfPages == 0){
            self.pageControl.currentPage = 0;
        }else{
            let idx = (NSInteger(scrollView.contentOffset.x / self.frame.width) - 1 + self.pageControl.currentPage + self.pageControl.numberOfPages)%self.pageControl.numberOfPages
            self.pageControl.currentPage = idx
        }
        self.updateBannerView()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.timer?.suspend()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.timer?.resume()
    }
    
}

