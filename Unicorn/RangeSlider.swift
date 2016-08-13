//
//  RangeSlider.swift
//  Unicorn
//
//  Created by Christina Ng on 12/21/14.
//  Copyright (c) 2014 Christina Ng. All rights reserved.
//

import UIKit
import QuartzCore

class RangeSlider: UIControl {
    
    // NOTE TO SELF: REPLACE THIS WITH ACTUAL AUTHKEY
    var authKey : String = "// NOTE TO SELF: REPLACE THIS WITH ACTUAL AUTHKEY"

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    
    var minimumValue: Double = 68.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var maximumValue: Double = 82.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var lowerValue: Double = 68.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var upperValue: Double = 80.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var previousLocation = CGPoint()
    
    let trackLayer = RangeSliderTrackLayer()
    let lowerThumbLayer = RangeSliderThumbLayer()
    let upperThumbLayer = RangeSliderThumbLayer()
    
    var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.94, blue: 0.45, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var thumbTintColor: UIColor = UIColor.whiteColor() {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }
    
    var curvaceousness: CGFloat = 1.0 {
        didSet {
            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }
    
    
    var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(trackLayer)
        
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(lowerThumbLayer)
        
        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(upperThumbLayer)
        
        // initialise position of sliders
        checkNests()
        let minTemp : NSString = self.nestJsonResult[0]["minTemp"] as! NSString
        let minimumTemp : Double = minTemp.doubleValue
        let maxTemp : NSString = self.nestJsonResult[0]["maxTemp"] as! NSString
        let maximumTemp : Double = maxTemp.doubleValue
        
        self.lowerValue = minimumTemp
        self.upperValue = maximumTemp
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        lowerThumbLayer.rangeSlider = self
        upperThumbLayer.rangeSlider = self
    }
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / 3)
        trackLayer.setNeedsDisplay()
        
        let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
        
        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0,
            width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()
        
        let upperThumbCenter = CGFloat(positionForValue(upperValue))
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2.0, y: 0.0,
            width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func positionForValue(value: Double) -> Double {
        // let widthDouble = Double(thumbWidth)
        return Double(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbWidth / 2.0)
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        previousLocation = touch.locationInView(self)
        
        // Hit test the thumb layers
        if lowerThumbLayer.frame.contains(previousLocation) {
            lowerThumbLayer.highlighted = true
        } else if upperThumbLayer.frame.contains(previousLocation) {
            upperThumbLayer.highlighted = true
        }
        
        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }
    
    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        // 1. Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)
        
        previousLocation = location
        
        // 2. Update the values
        if lowerThumbLayer.highlighted {
            lowerValue += deltaValue
            lowerValue = boundValue(lowerValue, toLowerValue: minimumValue, upperValue: upperValue)
        } else if upperThumbLayer.highlighted {
            upperValue += deltaValue
            upperValue = boundValue(upperValue, toLowerValue: lowerValue, upperValue: maximumValue)
        }

        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        
        sendActionsForControlEvents(.ValueChanged)
        
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
    }
    
    var nestJsonResult : [NSDictionary] = []

    // synchronous call to load initial nest state
    
    func checkNests() {
        // create the request & response
        let url : String = "http://home.isidorechan.com/nests"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    nestJsonResult.append(result as! NSDictionary)
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        
    }



}
