//
//  ViewController.swift
//  FindSquare
//
//  Created by johnson mathew on 7/12/17.
//  Copyright © 2017 johnson mathew. All rights reserved.
//  johnson.mathew@hotmail.com

import UIKit


let MAXWIDTH : CGFloat = 60.0, MAXHEIGHT : CGFloat = 60.0

enum Animation{
    case none,move,bounce(UIView)
}


class ViewController: UIViewController {
    
    var touchedPoint : CGPoint = .zero
    var animation : Animation = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        
        self.view.addGestureRecognizer(tap)

    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        touchedPoint = sender.location(in: self.view)
        
        self.draw(to: touchedPoint)

    }
    
    
    func draw(to point : CGPoint) -> Void {
        
        let location = CGRect(x: point.x - MAXWIDTH / 2, y: point.y - MAXHEIGHT / 2, width: MAXWIDTH, height: MAXHEIGHT)
        
        var rect : CGRect = location
        
        if !self.view.bounds.contains(location) {
            if  rect.origin.x < 0 { rect.origin.x = 0 }
            if  rect.origin.y < 0 { rect.origin.y = 0 }
            if  rect.origin.x + rect.size.width > self.view.bounds.size.width { rect.origin.x = self.view.bounds.size.width - rect.size.width }
            if  rect.origin.y + rect.size.height > self.view.bounds.size.height { rect.origin.y = self.view.bounds.size.height - rect.size.height }
        }
        
        var canDraw = true;
        
        animation = .move
        
        if self.view.frame.contains(rect) {
            for subView in self.view.subviews   {
                if let view = subView as? SquareView{
                    if view.isItYourLocation(location: rect){
                        canDraw = false
                        break
                    }
                }
            }
        }
        else{
            canDraw = false
        }
        
        if canDraw{
            self.draw(rect,tapped: location)
        }
        else{
            var best : CGRect = .zero
            var distance : Float = 99999.0
             for subView in self.view.subviews   {
                 if let view = subView as? SquareView{
                    let availability = view.availablespaceFortheBest(from: touchedPoint)
                    if availability.available {
                        let dx = sqrtf(Float(pow(abs(availability.rect.center.x - touchedPoint.x), 2) + pow(abs(availability.rect.center.y - touchedPoint.y), 2)))
                        if dx < distance {
                            distance = dx
                            best = availability.rect
                        }
                    }
                }
            }
            if best != .zero {
                self.draw(best, tapped: location)
            }
            else{
                let message =  UIAlertController(title: nil, message: "Sorry!! No space left", preferredStyle: .alert)
                message.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                self.present(message, animated: true, completion: nil)
            }
        }
    }
    
    func draw(_ rect : CGRect, _ color : UIColor) -> Void {
        let view = SquareView(frame: rect)
        view.boundary = self.view.bounds.size
        view.backgroundColor = color
        self.view.addSubview(view)
    }
    

    func draw(_ rect : CGRect,tapped location : CGRect) -> Void {
        let view = SquareView(frame: location)
        view.boundary = self.view.bounds.size
        
        
        view.leftTop = rect.origin
        view.rightTop = CGPoint(x: rect.origin.x + MAXWIDTH, y: rect.origin.y)
        view.leftBottom = CGPoint(x: (view.leftTop.x), y: (view.leftTop.y) + MAXHEIGHT)
        view.rightBottom = CGPoint(x: view.rightTop.x, y: view.leftBottom.y)

        
        let neighborsArea = CGRect(x: rect.origin.x - MAXWIDTH, y: rect.origin.y - MAXHEIGHT , width: rect.size.width + MAXWIDTH * 2, height: rect.size.height + MAXHEIGHT * 2)
        for subView in self.view.subviews   {
            if let subview = subView as? SquareView, subview != view{
                if subview.isItYourLocation(location: neighborsArea){
                    subview.addNeighbour(view)
                    view.addNeighbour(subView as! SquareView)
                }
            }
        }
        
        self.view.addSubview(view)
        
        switch animation {
        case .bounce( _):
            UIView.animate(withDuration: 0.2, animations: {
                view.frame = rect
            })
            
            /*let animator = UIDynamicAnimator(referenceView: refereceView)
             let gravityBehavior = UIGravityBehavior(items: [view])
             
             animator.addBehavior(gravityBehavior)
             
             let collisionBehavior = UICollisionBehavior(items: [view])
             collisionBehavior.translatesReferenceBoundsIntoBoundary = true
             animator.addBehavior(collisionBehavior)
             
             let elasticityBehavior = UIDynamicItemBehavior(items: [view])
             elasticityBehavior.elasticity = 0.7
             animator.addBehavior(elasticityBehavior)*/
            
            
            
            break
        case .move:
            UIView.animate(withDuration: 0.2, animations: {
                view.frame = rect
            })
            break
        case .none:
            view.frame = rect
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

class SquareView: UIView {
    
    enum Direction {
        case none
        case up
        case down
        case right
        case left
    }
    
    struct Availability {
        typealias rectAndAvailability = (available : Bool,rect : CGRect)
        var left : rectAndAvailability
        var right : rectAndAvailability
        var top : rectAndAvailability
        var bottom : rectAndAvailability
        
        func nearest(to point : CGPoint) -> rectAndAvailability {
            var array = Array<rectAndAvailability>()
            if left.available {array.append(left)}
            if right.available {array.append(right)}
            if top.available {array.append(top)}
            if bottom.available {array.append(bottom)}
            
            guard  let min =  (array.min(by: { (first : rectAndAvailability, second : rectAndAvailability) -> Bool in
                let d1 = sqrtf(Float(pow(abs(first.rect.center.x - point.x), 2) + pow(abs(first.rect.center.y - point.y), 2)))
                let d2 = sqrtf(Float(pow(abs(second.rect.center.x - point.x), 2) + pow(abs(second.rect.center.y - point.y), 2)))
                
                return d1 < d2
            })?.rect), array.count != 0 else { return (false,.zero)}
            
            return (true,min)
        }
    }
    

    private var w : CGFloat = 0.0
    private var h : CGFloat = 0.0
    
    var availability : Availability = Availability(left: (true, CGRect.zero), right: (true, CGRect.zero), top: (true, CGRect.zero), bottom: (true, CGRect.zero))
    
     var leftTop     : CGPoint = CGPoint.zero
     var rightTop    : CGPoint = CGPoint.zero
     var leftBottom  : CGPoint = CGPoint.zero
     var rightBottom : CGPoint = CGPoint.zero
    
    private var neighbours : Array<SquareView> = Array<SquareView>()
    
    var boundary : CGSize = .zero
    
    
    
    let lookLeft  : (_ view : SquareView) -> (Bool,CGRect) = {(view :SquareView) -> (Bool,CGRect)
        in
        var left: CGPoint = .zero
        var rect: CGRect = .zero
        var hasNeighbor = false
        var direction = Direction.none
        
        
        if let neighbors = Optional(view.neighbours) , neighbors.count > 0{
            for n in  neighbors{
                if left == .zero && n.rightTop.x <= view.leftTop.x {
                    hasNeighbor = true
                    if n.rightTop.y > view.leftTop.y {
                        left = CGPoint (x: view.leftTop.x, y: n.rightTop.y)
                        direction = .down
                    }
                    else{
                        left = CGPoint (x: view.leftBottom.x, y: n.rightBottom.y)
                        direction = .up
                    }
                }
                
                //Check whether space available in left side
                var r : CGRect = .zero
                if left != .zero {
                    if direction == .up {
                        r = CGRect(x: left.x - view.w, y: left.y , width: view.w, height: view.h)
                    }
                    else if direction == .down{
                        r = CGRect(x: left.x - view.w, y: left.y - view.h, width: view.w, height: view.h)
                    }
                    
                    var found = true
                    
                    for k in  neighbors{
                        if r.origin.x < 0 || r.origin.y < 0 || r.origin.x + r.size.width > view.boundary.width || r.origin.y + r.size.height > view.boundary.height || k.isItYourLocation(location: r) {
                            found = false
                            left = .zero
                        }
                    }
                    
                    if found {
                        rect = r
                        break
                    }
                }
            }
            if rect == .zero && !hasNeighbor{
                rect = CGRect(x: view.leftTop.x - view.w, y: view.leftTop.y , width: view.w, height: view.h)
            }
            
        }
        else{
            rect = CGRect(x: view.leftTop.x - view.w, y: view.leftTop.y , width: view.w, height: view.h)
        }
        if  rect != .zero && rect.origin.x >= 0 && rect.origin.y >= 0 && rect.origin.x + rect.size.width <= view.boundary.width && rect.origin.y + rect.size.height <= view.boundary.height  {
            return (true,rect)
        }
        else{
            return (false,.zero)
        }
    }
    
    
    
    let lookRight  : (_ view : SquareView) -> (Bool,CGRect) = {(view :SquareView) -> (Bool,CGRect)
        in
        var right: CGPoint = .zero
        var rect: CGRect = .zero
        var hasNeighbor = false
        var direction = Direction.none
        
        if let neighbors = Optional(view.neighbours) , neighbors.count > 0{
            //Right
            for n in  neighbors{
                if right == .zero && n.leftTop.x >= view.rightTop.x {
                    hasNeighbor = true
                    if n.leftTop.y > view.rightTop.y {
                        right = CGPoint (x: view.rightTop.x, y: n.leftTop.y)
                        direction = .down
                    }
                    else{
                        right = CGPoint (x: view.rightBottom.x, y: n.leftBottom.y)
                        direction = .up
                    }
                }
                
                //Check whether space available in Right side
                var r : CGRect = .zero
                r  = .zero
                if right != .zero {
                    if direction == .up {
                        r = CGRect(x: right.x , y: right.y , width: view.w, height: view.h)
                    }
                    else if direction == .down{
                        r = CGRect(x: right.x , y: right.y - view.h, width: view.w, height: view.h)
                    }
                    
                    var found = true
                    
                    for k in  neighbors{
                        if r.origin.x < 0 || r.origin.y < 0 || r.origin.x + r.size.width > view.boundary.width || r.origin.y + r.size.height > view.boundary.height || k.isItYourLocation(location: r){
                            found = false
                            right = .zero
                        }
                    }
                    
                    if found {
                        rect = r
                        break
                    }
                }
            }
            
            if rect == .zero && !hasNeighbor{
                rect = CGRect(x: view.rightTop.x , y: view.leftTop.y , width: view.w, height: view.h)
            }
            
        }
        else{
            rect = CGRect(x: view.rightTop.x , y: view.leftTop.y , width: view.w, height: view.h)
        }
        if  rect != .zero && rect.origin.x >= 0 && rect.origin.y >= 0 && rect.origin.x + rect.size.width <= view.boundary.width && rect.origin.y + rect.size.height <= view.boundary.height  {
            return (true,rect)
        }else{
            return (false,.zero)
        }
    }
    
    
    let lookTop  : (_ view : SquareView) -> (Bool,CGRect) = {(view :SquareView) -> (Bool,CGRect)
        in
        var top: CGPoint = .zero
        var rect: CGRect = .zero
        var hasNeighbor = false
        var direction = Direction.none
        
        if let neighbors = Optional(view.neighbours) , neighbors.count > 0{
            for n in  neighbors{
                if top == .zero && n.leftBottom.y <= view.leftTop.y {
                    hasNeighbor = true
                    if n.leftBottom.x > view.leftTop.x {
                        top = CGPoint (x: n.leftBottom.x, y: view.leftTop.y)
                        direction = .right
                    }
                    else{
                        top = CGPoint (x: n.rightBottom.x, y: view.rightTop.y)
                        direction = .left
                    }
                }
                
                //Check whether space available in left side
                var r : CGRect = .zero
                if top != .zero {
                    if direction == .right {
                        r = CGRect(x: top.x - view.w , y: top.y - view.h , width: view.w, height: view.h)
                    }
                    else if direction == .left{
                        r = CGRect(x: top.x  , y: top.y - view.h, width: view.w, height: view.h)
                    }
                    
                    var found = true
                    
                    for k in  neighbors{
                        if r.origin.x < 0 || r.origin.y < 0 || r.origin.x + r.size.width > view.boundary.width || r.origin.y + r.size.height > view.boundary.height || k.isItYourLocation(location: r) {
                            found = false
                            top = .zero
                        }
                    }
                    
                    if found {
                        rect = r
                        break
                    }
                }
            }
            if rect == .zero && !hasNeighbor{
                rect = CGRect(x: view.leftTop.x , y: view.leftTop.y - view.h , width: view.w, height: view.h)
            }
        }
        else{
            rect = CGRect(x: view.leftTop.x , y: view.leftTop.y - view.h , width: view.w, height: view.h)
        }
        
        if  rect != .zero && rect.origin.x >= 0 && rect.origin.y >= 0 && rect.origin.x + rect.size.width <= view.boundary.width && rect.origin.y + rect.size.height <= view.boundary.height  {
            return (true,rect)
        }
        else{
            return (false,.zero)
        }
    }
    
    
    let lookBottom  : (_ view : SquareView) -> (Bool,CGRect) = {(view :SquareView) -> (Bool,CGRect)
        in
        var bottom: CGPoint = .zero
        var rect: CGRect = .zero
        var hasNeighbor = false
        var direction = Direction.none
        
        if let neighbors = Optional(view.neighbours) , neighbors.count > 0{
            for n in  neighbors{
                if bottom == .zero && n.leftTop.y >= view.leftBottom.y {
                    hasNeighbor = true
                    if n.leftTop.x > view.leftBottom.x {
                        bottom = CGPoint (x: n.leftTop.x, y: view.leftBottom.y)
                        direction = .right
                    }
                    else{
                        bottom = CGPoint (x: n.rightTop.x, y: view.rightBottom.y)
                        direction = .left
                    }
                }
                
                //Check whether space available in left side
                var r : CGRect = .zero
                if bottom != .zero {
                    if direction == .right {
                        r = CGRect(x: bottom.x - view.w, y: bottom.y , width: view.w, height: view.h)
                    }
                    else if direction == .left{
                        r = CGRect(x: bottom.x , y: bottom.y, width: view.w, height: view.h)
                    }
                    
                    var found = true
                    
                    for k in  neighbors{
                        if r.origin.x < 0 || r.origin.y < 0 || r.origin.x + r.size.width > view.boundary.width || r.origin.y + r.size.height > view.boundary.height || k.isItYourLocation(location: r) {
                            found = false
                            bottom = .zero
                        }
                    }
                    
                    if found {
                        rect = r
                        break
                    }
                }
            }
            if rect == .zero && !hasNeighbor{
                rect = CGRect(x: view.leftBottom.x , y: view.leftBottom.y  , width: view.w, height: view.h)
            }
        }
        else{
            rect = CGRect(x: view.leftBottom.x , y: view.leftBottom.y  , width: view.w, height: view.h)
        }
        if rect != .zero && rect.origin.x >= 0 && rect.origin.y >= 0 && rect.origin.x + rect.size.width <= view.boundary.width && rect.origin.y + rect.size.height <= view.boundary.height  {
            return (true,rect)
        }
        else{
            return (false,.zero)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        w = frame.size.width
        h = frame.size.height
        
        self.isUserInteractionEnabled = false
        self.backgroundColor =  UIColor.orange
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func isItYourLocation(location rect: CGRect) ->Bool{
        return self.frame.intersects(rect)
    }
    
    
    func availablespaceFortheBest(from center : CGPoint) -> (available : Bool,rect : CGRect) {
        
        if availability.left.available {
            availability.left = lookLeft(self)
        }
        
        if availability.right.available {
            availability.right = lookRight(self)
        }
        
        if availability.top.available {
            availability.top =  lookTop(self)
        }
        
        if availability.bottom.available {
            availability.bottom =  lookBottom(self)
        }
        
        
        return availability.nearest(to: center)
    }
    
    
    func addNeighbour(_ neighbour : SquareView) -> Void {
        self.neighbours.append(neighbour)
    }
    
}

extension CGRect{
    var center : CGPoint{
        get{
            return CGPoint(x: self.origin.x + (self.size.width/2), y: self.origin.y + (self.size.height/2))
        }
    }
}

