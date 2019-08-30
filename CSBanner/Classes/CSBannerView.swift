//
//  CSBannerView.swift
//  CSBannerView
//
//  Created by Mr.s on 2018/8/29.
//  Copyright © 2018 Mr.s. All rights reserved.
//

import UIKit

@objc enum CSBannerStyle : Int {
    case Normal
    case Carousel
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
    @objc public var timeInterval : TimeInterval = 5
    @objc public var itemWidth : CGFloat = UIScreen.main.bounds.size.width - 64.0
    @objc public var itemHeight : CGFloat = (UIScreen.main.bounds.size.width - 64.0) * 9.0 / 16.0 + 16.0
    @objc public var space : CGFloat = 8.0
    var itemMargin : CGFloat {
        get{
            return space + itemWidth * (maxScale-1.0) / 2.0
        }
    }
    
    var itemViewCount : Int = 3
    
    @objc var autoScroll : Bool = true
    
    @objc var pagingEnable : Bool = true
    
    private var dragging : Bool = false
    
    @objc var scrolling : Bool = false
    
    @objc public var delegate : CSBannerViewDelegate?
    
    @objc public var datasource : CSBannerViewDatasource?
    
    @objc var currentIndex : Int = 0
    
    @objc var animationTimeInterval : TimeInterval = 0.7
    
    var waitCount : Int = 0
    
    var timer : Timer?
    
    var offset : CGPoint = .zero
    let maxScale : CGFloat = 1.2
    let minScale : CGFloat = 1.0
    var upScale : CGFloat = 1.0
    var downScale : CGFloat = 1.2
    
    var dragOffset : CGPoint = .zero
    var lastDragOffset : CGPoint = .zero
    
    var itemViews : [CSBannerItemView] = []
    
    var itemPreMoved : Bool = false
    
    var itemViewHasMoved : Bool = false
    
    var itemAdjusting : Bool = false
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        viewInit()
    }
    
    func viewInit(){
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
        loadItemViews()
    }
    
    func removeItemViews(){
        itemViews.forEach{$0.removeFromSuperview()}
        itemViews.removeAll()
    }
    
    func loadItemViews(){
        if itemViews.count == 0 {
            var i = 0
            let pageWidth = itemWidth + itemMargin
            let frame = CGRect.init(x: 0, y: 0, width: itemWidth, height: itemHeight)
            while i < itemViewCount {
                let view = loadViewForIndex(index: (i == itemViewCount - 1) ? (itemCount - 1) : i)
                let bannerView = CSBannerItemView()
                bannerView.index = i;
                bannerView.addSubview(view)
                bannerView.frame = frame
                containView.addSubview(bannerView)
                if(itemViewCount - 1 == i){
                    bannerView.center = CGPoint.init(x: self.frame.size.width/2.0 - pageWidth, y: self.frame.size.height/2.0)
                    itemViews.insert(bannerView, at: 0)
                }else{
                    bannerView.center = CGPoint.init(x: (self.frame.size.width/2.0 + CGFloat(i) * pageWidth), y: self.frame.size.height/2.0)
                    if(i == 0){
                        bannerView.layer.transform = CATransform3DScale(CATransform3DIdentity, maxScale, maxScale, 1)
                    }
                    itemViews.append(bannerView)
                }
                i += 1
            }
            containView.bringSubview(toFront: itemViews[2])
            containView.bringSubview(toFront: itemViews[1])
        }
    }
    
    @objc func updateItemViews(){
        CATransaction.begin()
        
        let pageWidth = itemWidth + itemMargin
        if dragging {
            //
            let delta = dragOffset.x - lastDragOffset.x
            offset.x = offset.x + delta
            let toLeft = offset.x < 0;
            downScale = max(minScale,(toLeft ? 1.0 : -1.0) * (maxScale - minScale) / pageWidth * offset.x + maxScale)
            upScale = min(maxScale, (toLeft ? -1.0 : 1.0) * (maxScale - minScale) / pageWidth * offset.x + minScale)
            
            if fabsf(Float(offset.x)) + Float(pageWidth) > Float(self.frame.size.width){
                if !itemPreMoved {//pre move
                    if toLeft {//left 1st --> right
                        itemViews.append(itemViews.removeFirst())
                        containView.bringSubview(toFront: itemViews[1])
                        itemViews.last!.center = CGPoint.init(x: self.frame.size.width/2.0 + pageWidth, y: self.frame.size.height/2.0)
                        itemViews.last!.subviews.forEach{$0.removeFromSuperview()}
                        let newIndex = (currentIndex+2)%itemCount;
                        let newView = loadViewForIndex(index: newIndex)
                        newView.frame = itemViews.last!.bounds
                        itemViews.last!.addSubview(newView)
                        itemViews.last!.index = newIndex
                        itemViews.last!.layer.transform =  CATransform3DTranslate(CATransform3DIdentity, offset.x + pageWidth , 0, 0)
                        itemViews[0].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        
                        
                    }else{//right --> left
                        itemViews.insert(itemViews.removeLast(), at: 0)
                        containView.bringSubview(toFront: itemViews[1])
                        itemViews.first!.center = CGPoint.init(x: self.frame.size.width/2.0 - pageWidth, y: self.frame.size.height/2.0)
                        itemViews.first!.subviews.forEach{$0.removeFromSuperview()}
                        let newIndex = (itemCount + currentIndex-2)%itemCount;
                        let newView = loadViewForIndex(index: newIndex)
                        newView.frame = itemViews.first!.bounds
                        itemViews.first!.addSubview(newView)
                        itemViews.first!.index = newIndex
                        itemViews.first!.layer.transform =  CATransform3DTranslate(CATransform3DIdentity, offset.x - pageWidth , 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        itemViews[2].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                    }
                    itemPreMoved = true
                }else{
                    //move
                    if toLeft {
                        itemViews[0].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        itemViews[2].layer.transform = CATransform3DTranslate(CATransform3DIdentity,(itemPreMoved ? pageWidth : 0) + offset.x, 0, 0)
                    }else{
                        itemViews[0].layer.transform = CATransform3DTranslate(CATransform3DIdentity, -(itemPreMoved ? pageWidth : 0) + offset.x, 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        itemViews[2].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                    }
                }
            }else{
                containView.bringSubview(toFront: itemViews[1])
                // normal
                if itemPreMoved{
                    //back to origin
                    if toLeft {
                        itemViews.insert(itemViews.removeLast(), at: 0)
                        itemViews.first!.center = CGPoint.init(x: self.frame.size.width/2.0 - pageWidth, y: self.frame.size.height/2.0)
                        itemViews.first!.subviews.forEach{$0.removeFromSuperview()}
                        let newIndex = (itemCount + currentIndex-1)%itemCount;
                        let newView = loadViewForIndex(index: newIndex)
                        newView.frame = itemViews.first!.bounds
                        itemViews.first!.addSubview(newView)
                        itemViews.first!.index = newIndex
                        itemViews.first!.layer.transform =  CATransform3DTranslate(CATransform3DIdentity, offset.x - pageWidth , 0, 0)
                        itemViews[2].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                        
                    }else{
                        itemViews.append(itemViews.removeFirst())
                        itemViews.last!.center = CGPoint.init(x: self.frame.size.width/2.0 + pageWidth, y: self.frame.size.height/2.0)
                        itemViews.last!.subviews.forEach{$0.removeFromSuperview()}
                        let newIndex = (currentIndex+1)%itemCount;
                        let newView = loadViewForIndex(index: newIndex)
                        newView.frame = itemViews.last!.bounds
                        itemViews.last!.addSubview(newView)
                        itemViews.last!.index = newIndex
                        itemViews.last!.layer.transform =  CATransform3DTranslate(CATransform3DIdentity, offset.x + pageWidth , 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                        itemViews[0].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        
                    }
                    itemPreMoved = false
                }else{
                    //move
                    if toLeft {
                        itemViews[0].layer.transform = CATransform3DTranslate(CATransform3DIdentity, offset.x, 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                        itemViews[2].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                    }else{
                        itemViews[0].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                        itemViews[1].layer.transform =
                            CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                        itemViews[2].layer.transform = CATransform3DTranslate(CATransform3DIdentity, offset.x, 0, 0)
                    }
                }
            }
            
            lastDragOffset = dragOffset
        }
        else{
            //auto scroll
            if(waitCount <= Int(timeInterval * 60.0)){
                //do nothing
            }else if(waitCount > Int(timeInterval * 60.0)
                && waitCount <= Int((timeInterval + animationTimeInterval) * 60.0)){
                isUserInteractionEnabled = false
                //animation
                offset.x = offset.x - pageWidth/CGFloat(animationTimeInterval * 60.0)
                upScale = min(maxScale,upScale + maxScale/CGFloat(animationTimeInterval * 60.0))
                downScale = max(minScale,downScale - (maxScale - minScale)/CGFloat(animationTimeInterval * 60.0))
                //left --> right
                if(fabsf(Float(offset.x)) + Float(itemWidth) > Float(self.frame.size.width)){
                    if !itemViewHasMoved {
                        // currentIndex = (currentIndex+1)%itemCount
                        itemViews.append(itemViews.removeFirst())
                        itemViews.last!.subviews.forEach{$0.removeFromSuperview()}
                        let newIndex = (currentIndex+2)%itemCount;
                        let newView = loadViewForIndex(index: newIndex)
                        newView.frame = itemViews.last!.bounds
                        itemViews.last!.addSubview(newView)
                        itemViews.last!.index = newIndex
                        itemViews.last!.center = CGPoint.init(x: self.frame.size.width/2.0 + pageWidth, y: self.frame.size.height/2.0)
                        itemViewHasMoved = true
                        containView.bringSubview(toFront: itemViews[1])
                    }
                    itemViews[0].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                    itemViews[1].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                    itemViews[2].layer.transform = CATransform3DTranslate(CATransform3DIdentity, offset.x + pageWidth , 0, 0)
                    
                }else{
                    itemViews[0].layer.transform = CATransform3DTranslate(CATransform3DIdentity, offset.x, 0, 0)
                    itemViews[1].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, downScale, downScale, 1) , offset.x / downScale, 0, 0)
                    itemViews[2].layer.transform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, upScale, upScale, 1), offset.x/upScale, 0, 0)
                }
            }else{
                var i = 0
                while i < itemViews.count {
                    let view = itemViews[i]
                    view.center = CGPoint.init(x: self.frame.size.width/2.0 + CGFloat(i-1) * pageWidth, y: self.frame.size.height/2.0)
                    if(i == 1){
                        view.layer.transform = CATransform3DScale(CATransform3DIdentity, maxScale, maxScale, 1)
                    }else{
                        view.layer.transform = CATransform3DIdentity
                    }
                    i=i+1
                }
                containView.bringSubview(toFront: itemViews[1])
                waitCount = -1;
                upScale = minScale
                downScale = maxScale
                offset = .zero
                currentIndex = (currentIndex + 1)%itemCount
                itemViewHasMoved = false
                isUserInteractionEnabled = true
            }
            
            waitCount = waitCount + 1
        }
        //
        CATransaction.commit()
    }
    
    func transformView(){
        stopAnimation()
        let pageWidth = itemWidth + itemMargin
        //        if fabsf(Float(self.offset.x)) > Float(0.4 * pageWidth){
        if fabsf(Float(offset.x)) + Float(pageWidth) > Float(self.frame.size.width){
            if offset.x < 0{
                currentIndex = (currentIndex + 1)%itemCount
            }else{
                currentIndex = (itemCount + currentIndex - 1)%itemCount
            }
        }
        containView.bringSubview(toFront: itemViews[1])

        
        //        UIView.animate(withDuration:(max(0.2,TimeInterval(1.0 - fabsf(Float(offset.x/pageWidth)))) * animationTimeInterval), animations: {
//        UIView.animate(withDuration:0.1, animations: {

            var i = 0
            while i < self.itemViews.count {
                let view = self.itemViews[i]
                view.center = CGPoint.init(x: self.frame.size.width/2.0 + CGFloat(i-1) * pageWidth, y: self.frame.size.height/2.0)
                if(i == 1){
                    view.layer.transform = CATransform3DScale(CATransform3DIdentity, self.maxScale, self.maxScale, 1)
                }else{
                    view.layer.transform = CATransform3DIdentity
                }
                i=i+1
            }
//        }) { (finished) in
            self.waitCount = -1
            self.offset = .zero
            self.dragOffset = .zero
            self.lastDragOffset = .zero
            self.startAnimation()
//        }
    }
    
    @objc func didPan(pan : UIPanGestureRecognizer){
        switch pan.state {
        case .began:
            dragging = true
            break;
        case .changed:
            let x = pan.translation(in: self).x
            dragOffset.x = x
            if(lastDragOffset == .zero){
                lastDragOffset.x = x
            }
            break;
        case .failed:fallthrough
        case .cancelled:fallthrough
        case .ended:
            dragging = false
            itemPreMoved = false
//            itemAdjusting = true
            transformView()
            break;
        default:
            break;
        }
    }
    
    @objc func didTap(tap : UITapGestureRecognizer){
        if let _ = delegate{
            let pt = tap.location(in: containView)
            if let itemView = itemViewAtPoint(pt: pt){
                delegate?.didSelectItemForIndex(index: itemView.index)
            }
        }
    }
    
    func itemViewAtPoint(pt:CGPoint) -> CSBannerItemView?{
        var i = 0
        while i < itemViews.count{
            if let _ = itemViews[i].layer.hitTest(pt){
                return itemViews[i]
            }
            i += 1
        }
        return nil
    }
    
    @objc public func reloadData(){
        /// reload view
        stopAnimation()
        removeItemViews()
        loadItemViews()
        startAnimation()
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
    
    func startAnimation(){
        if !autoScroll{
            return
        }
        if let _ = timer {
            
        }else{
            timer = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(updateItemViews), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
            RunLoop.main.add(timer!, forMode: RunLoopMode.UITrackingRunLoopMode)
        }
    }
    
    func stopAnimation(){
        if let _ = timer{
            timer!.invalidate()
            timer = nil
        }
    }
    
    deinit {
        stopAnimation()
    }
}


