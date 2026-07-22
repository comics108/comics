//
//  KDCircularProgress.swift
//  KDCircularProgress
//
//  Created by Kaan Dedeoglu on 1/14/15.
//  Copyright (c) 2015 Kaan Dedeoglu. All rights reserved.
//

import UIKit

internal extension Comparable {
    func clamped(toMinimum minimum: Self, maximum: Self) -> Self {
        assert(maximum >= minimum, "Maximum clamp value can't be higher than the minimum")
        if self < minimum {
            return minimum
        } else if self > maximum {
            return maximum
        } else {
            return self
        }
    }
}

@IBDesignable
public class CircularProgressView: UIView {
 
    private var radius: CGFloat = 0
    
    public var progress: Double = 0 {
        didSet {
            progress = progress.clamped(toMinimum: 0, maximum: 1)
//			print("===== progress: \(progress)")
			
			self.setNeedsDisplay()
        }
    }
    
	public var trackWidth: CGFloat = 1.0
    
    public var trackColor: UIColor = .white {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    public var progressColor: UIColor? = .blue
	
	//MARK: - init
	init(radius: CGFloat, trackWidth: CGFloat) {
		self.radius = radius
		self.trackWidth = trackWidth
		
		let width = Double(2 * radius)
		super.init(frame: CGRect(x: 0.0, y: 0.0, width: width, height: width))
		
		self.clearsContextBeforeDrawing = false
	}

	override public init(frame: CGRect) {
        super.init(frame: frame)
		radius = (frame.size.width / 2.0)
		backgroundColor = .clear
     }
    
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override public class var layerClass: AnyClass {
		return CAShapeLayer.self
	}
	
	//MARK: - Lifecycle
    public override func layoutSubviews() {
        super.layoutSubviews()
        radius = frame.size.width / 2.0
    }
    
    public override func didMoveToWindow() {
        if let window = window {
			self.layer.contentsScale = window.screen.scale
        }
    }
	
	public override func draw(_ rect: CGRect) {
		if let ctx = UIGraphicsGetCurrentContext() {
			
			let size = bounds.size
			let width = size.width
			let height = size.height
			
			let arcRadius = radius - trackWidth
			
			let angle = 2 * CGFloat.pi * CGFloat(progress)
			//NOTE: arc coordinate start is pi/2
			let fix = 0.5 * CGFloat.pi
			
			//Track (empty part)
			ctx.addArc(center: CGPoint(x: width / 2.0, y: height / 2.0), radius: arcRadius, startAngle: angle - fix, endAngle: CGFloat.pi * 2, clockwise: false)
			//Color of empty circle part
			UIColor.clear.set()
			
			ctx.setStrokeColor(trackColor.cgColor)
			ctx.setLineWidth(trackWidth)
			ctx.setLineCap(CGLineCap.butt)
			ctx.drawPath(using: .fillStroke)
			
			//Progress
			ctx.addArc(center: CGPoint(x: width / 2.0, y: height / 2.0), radius: arcRadius, startAngle: -fix, endAngle: angle - fix, clockwise: false)
			
			ctx.setStrokeColor((progressColor ?? .clear).cgColor)
			ctx.setLineWidth(trackWidth)
			ctx.setLineCap(CGLineCap.butt)
			ctx.drawPath(using: .fillStroke)
		}
	}
}
