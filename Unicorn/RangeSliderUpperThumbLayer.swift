//
//  RangeSliderUpperThumbLayer.swift
//  Unicorn
//
//  Created by Christina Ng on 12/22/14.
//  Copyright (c) 2014 Christina Ng. All rights reserved.
//

import UIKit
import QuartzCore

class RangeSliderUpperThumbLayer: CALayer {
    
    weak var rangeSlider: RangeSlider?
    
    var highlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawInContext(ctx: CGContext!) {
        if let slider = rangeSlider {
            let thumbFrame = bounds.rectByInsetting(dx: 2.0, dy: 2.0)
            let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
            let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
            
            // Fill - with a subtle shadow
            let shadowColor = UIColor.grayColor()
            CGContextSetShadowWithColor(ctx, CGSize(width: 0.0, height: 1.0), 1.0, shadowColor.CGColor)
            CGContextSetFillColorWithColor(ctx, slider.thumbTintColor.CGColor)
            CGContextAddPath(ctx, thumbPath.CGPath)
            CGContextFillPath(ctx)
            
            // Outline
            CGContextSetStrokeColorWithColor(ctx, shadowColor.CGColor)
            CGContextSetLineWidth(ctx, 0.5)
            CGContextAddPath(ctx, thumbPath.CGPath)
            CGContextStrokePath(ctx)
            
            if highlighted {
                CGContextSetFillColorWithColor(ctx, UIColor(white: 0.0, alpha: 0.1).CGColor)
                CGContextAddPath(ctx, thumbPath.CGPath)
                CGContextFillPath(ctx)
            }
        }
    }
}
