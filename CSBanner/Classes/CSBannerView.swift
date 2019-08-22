//
//  CSBannerView.swift
//  CSBannerView
//
//  Created by Mr.s on 2018/8/29.
//  Copyright © 2018年 Mr.s. All rights reserved.
//

import UIKit

@objc enum CSBannerStyle : Int {
    case CSBannerStyleNormal
    case CSBannerStyleCarousel
}

@objc public protocol CSBannerViewDelegate {
    func didSelectItemForIndex(index : Int);
}

@objc public protocol CSBannerViewDatasource {
    func itemViewForIndex(index : Int) -> UIView;
}

@objc public class CSBannerItemView: UIView {
    @objc public var index : Int = 0
    
}

@objc public class CSBannerView: UIView {
    private let containView = UIView.init()
    /// number of item
    @objc public var itemCount : Int = 3
    @objc public var timeInterval : CGFloat = 5
    @objc public var itemWidth : CGFloat = UIScreen.main.bounds.size.width - 64.0
    @objc public var itemHeight : CGFloat = (UIScreen.main.bounds.size.width - 64.0) * 9.0 / 16.0 + 16.0
    @objc public var space : CGFloat = 8.0
    var itemMargin : CGFloat {
        get{
          return space + itemWidth * (maxScale-1.0) / 2.0
        }
    }
    
    var itemViewCount : Int = 4
    
    @objc var autoScroll : Bool = true
    
    @objc var pagingEnable : Bool = true
    
    private var dragging : Bool = false
    
    @objc var scrolling : Bool = false
    
    @objc public var delegate : CSBannerViewDelegate?
    
    @objc public var datasource : CSBannerViewDatasource?
    
    @objc var currentIndex : Int = 0
    
    
    var animationTimeInterval : CGFloat = 1.0
    
    var waitCount : Int = 0
    
    var timer : Timer?
    
    var offset : CGPoint = .zero
    let maxScale : CGFloat = 1.2
    let minScale : CGFloat = 1.0
    var upScale : CGFloat = 1.0
    var downScale : CGFloat = 1.2
    
    var dragOffset : CGPoint = .zero
    var lastDragOffset : CGPoint = .zero
    
    
    var bannerItemViews : [CSBannerItemView] = []
    
    var lastTime : Double = 0
    var readyToLoadNewItemView : Bool = false
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        viewInit()
    }
    
    func viewInit(){
        timer = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(updateItemViews), userInfo: nil, repeats: true)
        defer {
            RunLoop.main.add(timer!, forMode: .default)
            RunLoop.main.add(timer!, forMode: .tracking)
        }
        
        addSubview(containView)
        containView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions.alignAllCenterY, metrics: nil, views: ["view":containView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions.alignAllCenterX, metrics: nil, views: ["view":containView]))
        
        let panGes = UIPanGestureRecognizer.init(target: self, action: #selector(didPan(pan:)))
        containView.addGestureRecognizer(panGes)
        
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(didTap(tap:)))
        containView.addGestureRecognizer(tapGes)
        
        if let _ = self.datasource{
            reloadData()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        var i = 0
        while i < itemViewCount {
            let frame = CGRect.init(x: 0, y: 0, width: itemWidth, height: itemHeight)
            let view = loadViewForIndex(index: i)
            let bannerView = CSBannerItemView()
            bannerView.index = i;
            bannerView.addSubview(view)
            bannerView.frame = frame
//            bannerView.clipsToBounds = true
//            bannerView.backgroundColor = .clear
//            bannerView.layer.cornerRadius = 6.0
//            bannerView.layer.shadowColor = UIColor.lightGray.cgColor
//            bannerView.layer.shadowOpacity = 0.7
//            bannerView.layer.shadowRadius = 6.0
//            bannerView.layer.borderWidth = 2;
//            bannerView.layer.shadowOffset = CGSize.init(width: 1.0, height: 1.0)
//            bannerView.layer.borderWidth = 1.0
            containView.addSubview(bannerView)
            let pageWidth = itemWidth + itemMargin
            if(itemViewCount - 1 == i){
                bannerView.center = CGPoint.init(x: self.frame.size.width/2.0 - pageWidth, y: self.frame.size.height/2.0)
                bannerItemViews.insert(bannerView, at: 0)
            }else{
                bannerView.center = CGPoint.init(x: (self.frame.size.width/2.0 + CGFloat(i) * pageWidth), y: self.frame.size.height/2.0)
                if(i == 0){
                    bannerView.layer.transform = CATransform3DScale(CATransform3DIdentity, maxScale, maxScale, 1)
                    containView.bringSubviewToFront(bannerView)
                }
                bannerItemViews.append(bannerView)
            }
            i += 1
        }
    }
    
    func easeInOut(time:Double) -> Double{
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0) : 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0;
    }
    
    @objc func updateItemViews(){
        CATransaction.begin()
        ///
        let currentTime = CACurrentMediaTime()
        //        let delta = easeInOut(time: (currentTime - lastTime))
        lastTime = currentTime
        
        
        var pageWidth = itemWidth + itemMargin
        
        if(dragging){
            //
            let delta = dragOffset.x - lastDragOffset.x
            offset.x = offset.x + delta
            var transform = CATransform3DIdentity
            
            pageWidth = offset.x <= 0 ? pageWidth : -pageWidth
            
            if fabsf(Float(offset.x)) > Float(pageWidth){
                
                //load next
                waitCount = -1;
                upScale = minScale
                downScale = maxScale
                
                let item0 = bannerItemViews[0]
                let item1 = bannerItemViews[1]
                let item2 = bannerItemViews[2]
                let item3 = bannerItemViews[3]
                
                let transform = item3.layer.transform
                item0.center = CGPoint.init(x: item3.center.x + pageWidth, y: item3.center.y)
                item0.layer.transform = CATransform3DTranslate(transform, transform.m11 + pageWidth, 0, 0)
                bannerItemViews = [item1,item2,item3,item0]
                
                
                offset.x += pageWidth
                dragOffset.x += pageWidth
                lastDragOffset.x += pageWidth
                
                var i = 0
                while i < bannerItemViews.count {
                    let view = bannerItemViews[i]
                    view.center = CGPoint.init(x: self.frame.size.width/2.0 + CGFloat(i-1) * pageWidth, y: self.frame.size.height/2.0)
//                    if(i == 1){
//                        view.layer.transform = CATransform3DScale(CATransform3DIdentity, maxScale, maxScale, 1)
//                    }else{
                        view.layer.transform = CATransform3DIdentity//CATransform3DTranslate(CATransform3DIdentity, view.layer.transform.m11 + pageWidth, 0, 0)
//                    }
                    i=i+1
                }
//                dragOffset = .zero
//                lastDragOffset = .zero
                
                var nextIndex = 0
                if offset.x < 0{
                    currentIndex = (currentIndex + 1)%itemCount
                    nextIndex = (currentIndex + 2)%itemCount
                }else{
                    currentIndex = (itemCount + currentIndex - 1)%itemCount
                    nextIndex = (itemCount + currentIndex - 2)%itemCount
                }
                //load 4th item view
                //载入时机有问题 只有三张时，会造成左侧图，即第1消失----预先移动到了第四
//                if(fabs(offset.x) > Float(itemWidth/2.0 + space)){
                    bannerItemViews.last!.subviews.forEach{$0.removeFromSuperview()}
                    let newIndex = nextIndex;
                    let newView = loadViewForIndex(index: newIndex)
                    newView.frame = bannerItemViews.last!.bounds
                    bannerItemViews.last!.addSubview(newView)
                    bannerItemViews.last!.index = newIndex
//                }
                
            }else{
                transform = CATransform3DTranslate(transform, offset.x, 0, 0)
                bannerItemViews[0].layer.transform = transform
                bannerItemViews[1].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                bannerItemViews[2].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                bannerItemViews[3].layer.transform = transform                
            }
            
            lastDragOffset = dragOffset
        }else{
            if(waitCount <= Int(timeInterval * 60.0)){
                //no animation
            }else if(waitCount > Int(timeInterval * 60.0)
                && waitCount <= (Int(timeInterval + animationTimeInterval) * 60)){
                containView.bringSubviewToFront(bannerItemViews[1])
                //animation
                offset.x = offset.x - pageWidth/(animationTimeInterval * 60.0)
                //min(2.0 , 1.0 + CGFloat(delta) * (itemWidth + space)/60.0)
                upScale = min(maxScale,upScale + maxScale/(animationTimeInterval * 60.0))
                downScale = max(minScale,downScale - (maxScale - minScale)/(animationTimeInterval * 60.0))
                
                var transform = CATransform3DIdentity
                transform = CATransform3DTranslate(transform, offset.x, 0, 0)
                bannerItemViews[0].layer.transform = transform
                bannerItemViews[1].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                bannerItemViews[2].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                bannerItemViews[3].layer.transform = transform
                
                if(readyToLoadNewItemView && (fabsf(Float(offset.x)) > Float(itemWidth))){
                    bannerItemViews.last!.subviews.forEach{$0.removeFromSuperview()}
                    let newIndex = (currentIndex+2)%itemCount;
                    let newView = loadViewForIndex(index: newIndex)
                    newView.frame = bannerItemViews.last!.bounds
                    bannerItemViews.last!.addSubview(newView)
                    bannerItemViews.last!.index = newIndex
                    readyToLoadNewItemView = false
                }
            }else{
                //change Index
                waitCount = -1;
                upScale = minScale
                downScale = maxScale
                
                let item0 = bannerItemViews[0]
                let item1 = bannerItemViews[1]
                let item2 = bannerItemViews[2]
                let item3 = bannerItemViews[3]
                //
                
                let transform = item3.layer.transform
                item0.center = CGPoint.init(x: item3.center.x + pageWidth, y: item3.center.y)
                item0.layer.transform = CATransform3DTranslate(transform, transform.m11 + pageWidth, 0, 0)
                bannerItemViews = [item1,item2,item3,item0]
                
                var i = 0
                while i < bannerItemViews.count {
                    let view = bannerItemViews[i]
                    view.center = CGPoint.init(x: self.frame.size.width/2.0 + CGFloat(i-1) * pageWidth, y: self.frame.size.height/2.0)
                    if(i == 1){
                        view.layer.transform = CATransform3DScale(CATransform3DIdentity, maxScale, maxScale, 1)
                    }else{
                        view.layer.transform = CATransform3DIdentity
                    }
                    i=i+1
                }
                offset = .zero
                
                //load 4th item view
                currentIndex = (currentIndex + 1)%itemCount
                readyToLoadNewItemView = true
//                item0.subviews.forEach{$0.removeFromSuperview()}
//                let newIndex = (currentIndex + 2)%itemCount;
//                let newView = loadViewForIndex(index: newIndex)
//                newView.frame = item0.bounds
//                item0.addSubview(newView)
//                item0.index = newIndex
            }
            
            waitCount = waitCount + 1
        }
        //
        CATransaction.commit()
    }
    
    @objc func didPan(pan : UIPanGestureRecognizer){
        switch pan.state {
        case .began:
//            dragging = true
            break;
        case .changed:
            let x = pan.translation(in: self).x
            dragOffset.x = x
            break;
        case .failed:fallthrough
        case .cancelled:fallthrough
        case .ended:
            //TODO: pagingenable？？
            
            dragOffset = .zero
            lastDragOffset = .zero
            dragging = false
            break;
        default:
            break;
        }
    }
    
    @objc func didTap(tap : UITapGestureRecognizer){
        if let _ = delegate{
            //TODO:确定 index
            let pt = tap.location(in: containView)
            if let itemView = itemViewAtPoint(pt: pt){
                delegate?.didSelectItemForIndex(index: itemView.index)
            }
        }
    }
    
    func itemViewAtPoint(pt:CGPoint) -> CSBannerItemView?{
        var i = 0
        while i < bannerItemViews.count{
            if let _ = bannerItemViews[i].layer.hitTest(pt){
                return bannerItemViews[i]
            }
            i += 1
        }
        return nil
    }
    
    @objc public func reloadData(){
        offset = .zero
        /// reset item count
        
        //        containView.subviews.forEach {$0.removeFromSuperview()}
        ///load view
        // 6 7 8 9 0 1 2 3 4 5
        ///
        //
        //        view0.frame = bannerView0.bounds
        
        /// reload view
    }
    
    func loadViewForIndex(index:Int)->UIView{
        var view : UIView?
        if let _ = datasource{
            view = datasource!.itemViewForIndex(index: index)
        }
        if view == nil {
            view = UIView.init()
        }
        view!.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        return view!
    }
    
    deinit {
        if let _ = timer{
            timer!.invalidate()
            timer = nil
        }
    }
}

