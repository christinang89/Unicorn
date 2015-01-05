//
//  ViewController.swift
//  Unicorn
//
//  Created by Christina Ng on 12/20/14.
//  Copyright (c) 2014 Christina Ng. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var nestTemp: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var lightLabel: UILabel!
    
    @IBOutlet weak var lockStateLabel: UIButton!
    
    var jsonResult : [NSDictionary] = []
    var lightToggles = [String:UISwitch]()
    
    var nestJsonResult : [NSDictionary] = []
    var lockJsonResult : [NSDictionary] = []
    
    var password : String = "un1cornH0rn"
    
    let rangeSlider = RangeSlider(frame: CGRectZero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(rangeSlider)
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        rangeSlider.addTarget(self, action: "rangeSliderValueChanged:", forControlEvents: .ValueChanged)
        checkNests()
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        //        dispatch_async(backgroundQueue, {
        //            for( var i: Int = 0; i < 100; i++ )
        //            {
        //                println("This is run on the background queue")
        //                NSThread.sleepForTimeInterval(1)
        //                self.pollLights()
        //                //self.tableView.reloadData()
        //            }
        //
        //        })
        
        //        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
        //        dispatch_after(time, dispatch_get_main_queue()) {
        //            self.rangeSlider.trackHighlightTintColor = UIColor.redColor()
        //            self.rangeSlider.curvaceousness = 0.0
        //        }
        
        
    }
    
    override func viewDidLayoutSubviews() {
        let margin: CGFloat = 60.0
        let width = view.bounds.width - 2.0 * margin
        rangeSlider.frame = CGRect(x: margin, y: 100.0,
            width: width, height: 30.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkLights()
        checkNests()
        checkLocks()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // drawing of the uitableview
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.jsonResult.count;
    }
    
    // populating data in uitableview
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        
        var url : String = "http://home.isidorechan.com/lights"
        var request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        cell.textLabel?.text = self.jsonResult[indexPath.row]["name"]! as NSString;
        
        var lightId : String = self.jsonResult[indexPath.row]["id"] as NSString
        
        var s = lightToggles[lightId]
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        cell.accessoryView = s
        
        return cell
    }
    
    
    // helper functions
    
    // synchronous call to load initial light state
    
    func checkLights() {
        // create the request & response
        var url : String = "http://home.isidorechan.com/lights"
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        var dataVal: NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
        let jsonResponse: NSDictionary! = NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        jsonResult.removeAll(keepCapacity: true)
        
        // look at the response
        if (jsonResponse != nil) {
            for (id, result) in jsonResponse {
                jsonResult.append(result as NSDictionary)
                
                var s = UISwitch(frame:CGRectMake(0, 0, 0, 0))
                var lightId = result["id"] as String
                s.tag = lightId.toInt()!
                s.addTarget(self, action: "switchValueDidChange:", forControlEvents: .ValueChanged);
                
                if result["state"]! as NSString == "1" {
                    s.setOn(true, animated: false)
                } else {
                    s.setOn(false, animated: false)
                }
                
                lightToggles.updateValue(s, forKey: result["id"]! as NSString)
                
            }
        }
        else {
            println("No HTTP response")
            println(error)
        }
        
    }
    
    func pollLights() {
        // create the request & response
        var url : String = "http://home.isidorechan.com/lights"
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        var dataVal: NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
        let jsonResponse: NSDictionary! = NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        // look at the response
        if (jsonResponse != nil) {
            for (id, result) in jsonResponse {
                var state : String = result["state"] as String
                var lightState : Bool
                if (state == "1") {
                    lightState = true
                } else {
                    lightState = false
                }
                var lightId : String = result["id"] as String
                var tempSwitch : UISwitch = lightToggles[lightId]! as UISwitch
                if (tempSwitch.on != lightState) {
                    tempSwitch.setOn(lightState, animated: true)
                    
                    checkLights()
                    self.tableView.reloadData()
                    println("changed to \(lightState)")
                }
            }
        }
        else {
            println("No HTTP response")
            println(error)
        }
        
    }
    
    
    // synchronous call to switch light state
    
    func setLights(lightId : String, state : String) {
        // create the request & response
        var url : String = "http://home.isidorechan.com/lights/" + lightId
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        
        // create some JSON data and configure the request
        let jsonString = "{\"state\":\"" + state + "\"}"
        request.URL = NSURL(string: url)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // send the request
        NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        
        // look at the response
        if let httpResponse = response as? NSHTTPURLResponse {
            println("HTTP response: \(httpResponse.statusCode)")
            println(response)
        } else {
            println("No HTTP response")
            println(error)
        }
    }
    
    // synchronous call to load initial nest state
    
    func checkNests() {
        // create the request & response
        var url : String = "http://home.isidorechan.com/nests"
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        var dataVal: NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
        let jsonResponse: NSDictionary! = NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        // look at the response
        if (jsonResponse != nil) {
            for (id, result) in jsonResponse {
                nestJsonResult.append(result as NSDictionary)
                var currentTemp : String = result["currentTemp"] as String
                var maxTemp : String = result["maxTemp"] as String
                var minTemp : String = result["minTemp"] as String
                currentTempLabel.text = "\(currentTemp) "
                nestTemp.text = "(\(minTemp) - \(maxTemp))"
            }
            
            
        }
        else {
            println("No HTTP response")
            println(error)
        }
        
    }
    
    
    // synchronous call to load initial lock state
    
    func checkLocks() {
        // create the request & response
        var url : String = "http://home.isidorechan.com/locks"
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        var dataVal: NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
        let jsonResponse: NSDictionary! = NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        // look at the response
        if (jsonResponse != nil) {
            for (id, result) in jsonResponse {
                lockJsonResult.append(result as NSDictionary)
                
                if result["state"]! as NSString == "1" {
                    lockStateLabel.setTitle("Locked", forState: UIControlState.Selected)
                    lockStateLabel.selected = true
                } else {
                    lockStateLabel.setTitle("Unlocked", forState: UIControlState.Normal)
                    lockStateLabel.selected = false
                }
            }
            
        }
        else {
            println("No HTTP response")
            println(error)
        }
        
    }
    
    // async call to switch nest temps
    
    func setNests(nestId : String, minTemp : String, maxTemp : String) {
        // create the request & response
        var url : String = "http://home.isidorechan.com/nests/" + nestId
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        
        // create some JSON data and configure the request
        let jsonString = "{\"password\":\"" + password + "\", \"minTemp\":\"" + minTemp + "\", \"maxTemp\":\"" + maxTemp + "\"}"
        request.URL = NSURL(string: url)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // send the request
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{ (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?> = nil
            let jsonResult: NSDictionary! = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: error) as? NSDictionary
            
            
            if (jsonResult != nil) {
                // process jsonResult
                println(jsonResult)
                dispatch_async(dispatch_get_main_queue()) {
                    self.nestTemp.text = "(\(minTemp) - \(maxTemp))"
                }
            } else {
                // couldn't load JSON, look at error
                println(error)
            }
            
            
        })
        
    }
    
    // async call to switch lock state
    
    func setLocks(lockId : String, state : String) {
        // create the request & response
        var url : String = "http://home.isidorechan.com/locks/" + lockId
        var request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        
        // create some JSON data and configure the request
        let jsonString = "{\"password\":\"" + password + "\", \"state\":\"" + state + "\"}"
        request.URL = NSURL(string: url)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // send the request
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{ (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?> = nil
            let jsonResult: NSDictionary! = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: error) as? NSDictionary
            
            if (jsonResult != nil) {
                // process jsonResult
                println(jsonResult)
                
                if jsonResult["state"] != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        if jsonResult["state"] as NSString == "1" {
                            self.lockStateLabel.selected = true
                            self.lockStateLabel.setTitle("Locked", forState: UIControlState.Selected)
                        }
                        else {
                            
                            self.lockStateLabel.selected = false
                            self.lockStateLabel.setTitle("Unlocked", forState: UIControlState.Normal)
                            
                        }
                        
                    }
                }
            } else {
                
                // couldn't load JSON, look at error
                println(error)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.lockStateLabel.enabled = true
            }
            
            
        })
        
    }
    
    
    // turn lights on/off based on switch action
    
    func switchValueDidChange(sender:UISwitch!) {
        var newState : String
        
        if (sender.on == true){
            newState = "1"
        }
        else{
            newState = "0"
        }
        
        var tag : String = String(sender.tag)
        setLights(tag, state: newState)
    }
    
    // set temp based on slider values
    
    func rangeSliderValueChanged(rangeSlider: RangeSlider) {
        var minimumTemp : Int = Int(rangeSlider.lowerValue)
        var maximumTemp : Int = Int(rangeSlider.upperValue)
        dispatch_async(dispatch_get_main_queue()) {
            self.nestTemp.text = "(\(minimumTemp) - \(maximumTemp))"
        }
        setNests("32", minTemp: String(minimumTemp) , maxTemp: String(maximumTemp))
        println("Range slider value changed: (\(minimumTemp) \(maximumTemp))")
    }
    
    
    
    @IBAction func switchLockState(sender: UIButton) {
        var newState : String
        if sender.selected {
            newState = "0"
        } else {
            newState = "1"
        }
        sender.enabled = false
        setLocks("34", state: String(newState))
        println("New lock state: (\(newState))")
    }
    
    
    
    
}

