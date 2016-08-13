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
    @IBOutlet weak var lightLabel: UILabel!
    
    @IBOutlet weak var nestTemp: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var lockStateLabel: UIButton!
    
    var jsonResult : [NSDictionary] = [] // lights json result
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
        rangeSlider.addTarget(self, action: #selector(ViewController.rangeSliderValueChanged(_:)), forControlEvents: .ValueChanged)
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            for _ in 0..<100
            {
                NSThread.sleepForTimeInterval(1)
                self.pollLights()
                self.pollLocks()
                self.pollNests()
            }
            
        })
        
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
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        let url : String = "http://home.isidorechan.com/lights"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        cell.textLabel?.text = self.jsonResult[indexPath.row]["name"]! as! NSString as String;
        
        let lightId : String = self.jsonResult[indexPath.row]["id"] as! NSString as String
        
        let s = lightToggles[lightId]
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        cell.accessoryView = s
        
        return cell
    }
    
    
    ///////////// loading functions /////////////
    
    // synchronous call to load initial light state
    
    func checkLights() {
        
        // create the request & response
        let url : String = "http://home.isidorechan.com/lights"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    jsonResult.append(result as! NSDictionary)
                    
                    let s = UISwitch(frame:CGRectMake(0, 0, 0, 0))
                    let lightId = result["id"] as! String
                    s.tag = Int(lightId)!
                    s.addTarget(self, action: #selector(ViewController.switchValueDidChange(_:)), forControlEvents: .ValueChanged);
                    
                    if result["state"]! as! NSString == "1" {
                        s.setOn(true, animated: false)
                    } else {
                        s.setOn(false, animated: false)
                    }
                    
                    lightToggles.updateValue(s, forKey: result["id"]! as! NSString as String)
                    
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        
    }
    
    // synchronous call to load initial nest state
    
    func checkNests() {
        // create the request & response
        let url : String = "http://home.isidorechan.com/nests"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    nestJsonResult.append(result as! NSDictionary)
                    let currentTemp : String = result["currentTemp"] as! String
                    let maxTemp : String = result["maxTemp"] as! String
                    let minTemp : String = result["minTemp"] as! String
                    currentTempLabel.text = "\(currentTemp) "
                    nestTemp.text = "(\(minTemp) - \(maxTemp))"
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        
        
    }
    
    
    // synchronous call to load initial lock state
    
    func checkLocks() {
        // create the request & response
        let url : String = "http://home.isidorechan.com/locks"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                lockJsonResult.append(result as! NSDictionary)
                
                if result["state"]! as! NSString == "1" {
                    lockStateLabel.setTitle("Locked", forState: UIControlState.Selected)
                    lockStateLabel.selected = true
                } else {
                    lockStateLabel.setTitle("Unlocked", forState: UIControlState.Normal)
                    lockStateLabel.selected = false
                }
                }
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    
        
    }
    
    ///////////// polling functions /////////////
    
    // synchronous call to poll light states
    
    func pollLights() {
        // create the request & response
        let url : String = "http://home.isidorechan.com/lights"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    let state : String = result["state"] as! String
                    var lightState : Bool
                    if (state == "1") {
                        lightState = true
                    } else {
                        lightState = false
                    }
                    let lightId : String = result["id"] as! String
                    let tempSwitch : UISwitch = lightToggles[lightId]! as UISwitch
                    if (tempSwitch.on != lightState) {
                        dispatch_async(dispatch_get_main_queue()) {
                            tempSwitch.setOn(lightState, animated: true)
                            print("light \(lightId) changed to \(lightState)")
                        }
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    // synchronous call to poll lock state
    
    func pollLocks() {
        // create the request & response
        let url : String = "http://home.isidorechan.com/locks"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    let state : String = result["state"] as! String
                    if (state == "1") {
                        if self.lockStateLabel.selected != true {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.lockStateLabel.selected = true
                                self.lockStateLabel.setTitle("Locked", forState: UIControlState.Selected)
                                print("lock changed to locked")
                            }
                        }
                    } else {
                        if self.lockStateLabel.selected == true {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.lockStateLabel.selected = false
                                self.lockStateLabel.setTitle("Unlocked", forState: UIControlState.Normal)
                                print("lock changed to unlocked")
                            }
                        }
                    }
                    
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    
    func pollNests() {
        // create the request & response
        let url : String = "http://home.isidorechan.com/nests"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        
        // send the request
        let dataVal: NSData = try! NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    // nestJsonResult.append(result as NSDictionary)
                    let currentTemp : String = result["currentTemp"] as! String
                    let maxTemp : NSString = result["maxTemp"] as! NSString
                    let minTemp : NSString = result["minTemp"] as! NSString
                    if (self.nestJsonResult[0]["currentTemp"] as! String != currentTemp) {
                        self.nestJsonResult[0].setValue(currentTemp, forKey: "currentTemp")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.currentTempLabel.text = currentTemp
                            print("Nest current temp updated to \(currentTemp)")
                        }
                    }
                    if (self.nestJsonResult[0]["minTemp"] as! String != minTemp || self.nestJsonResult[0]["maxTemp"] as! String != maxTemp) {
                        self.nestJsonResult[0].setValue(minTemp, forKey: "minTemp")
                        self.nestJsonResult[0].setValue(maxTemp, forKey: "maxTemp")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.nestTemp.text = "(\(minTemp) - \(maxTemp))"
                            print("Nest temp updated to (\(minTemp) - \(maxTemp))")
                            let minimumTemp : Double = minTemp.doubleValue
                            let maximumTemp : Double = maxTemp.doubleValue
                            self.rangeSlider.lowerValue = minimumTemp
                            self.rangeSlider.upperValue = maximumTemp
                        }
                        
                    }
                }

            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    
    ///////////// switching functions /////////////
    
    // synchronous call to switch light state
    
    func setLights(lightId : String, state : String) {
        // create the request & response
        let url : String = "http://home.isidorechan.com/lights/" + lightId
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: NSURLResponse?
        var error: NSError?
        
        // create some JSON data and configure the request
        let jsonString = "{\"state\":\"" + state + "\"}"
        request.URL = NSURL(string: url)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // send the request
            try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        } catch let error1 as NSError {
            error = error1
        }
        
        // look at the response
        if let httpResponse = response as? NSHTTPURLResponse {
            print("HTTP response: \(httpResponse.statusCode)")
            print(response)
        } else {
            print("No HTTP response")
            print(error)
        }
    }
    
    
    // async call to switch nest temps
    
    func setNests(nestId : String, minTemp : String, maxTemp : String) {
        // create the request & response
        let url : String = "http://home.isidorechan.com/nests/" + nestId
        let request : NSMutableURLRequest = NSMutableURLRequest()
        
        // create some JSON data and configure the request
        let jsonString = "{\"password\":\"" + password + "\", \"minTemp\":\"" + minTemp + "\", \"maxTemp\":\"" + maxTemp + "\"}"
        request.URL = NSURL(string: url)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // send the request
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{ (response:NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            do {
                if let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                    print(jsonResult)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.nestTemp.text = "(\(minTemp) - \(maxTemp))"
                    }
                    
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            
        })
        
    }
    
    // async call to switch lock state
    
    func setLocks(lockId : String, state : String) {
        // create the request & response
        let url : String = "http://home.isidorechan.com/locks/" + lockId
        let request : NSMutableURLRequest = NSMutableURLRequest()
        
        // create some JSON data and configure the request
        let jsonString = "{\"password\":\"" + password + "\", \"state\":\"" + state + "\"}"
        request.URL = NSURL(string: url)
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // send the request
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{ (response:NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            do {
                if let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                    // process jsonResult
                    print(jsonResult)
                    
                    if jsonResult["state"] != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            if jsonResult["state"] as! NSString == "1" {
                                self.lockStateLabel.selected = true
                                self.lockStateLabel.setTitle("Locked", forState: UIControlState.Selected)
                            }
                            else {
                                
                                self.lockStateLabel.selected = false
                                self.lockStateLabel.setTitle("Unlocked", forState: UIControlState.Normal)
                            }
                            
                        }
                    }
                    
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            
            dispatch_async(dispatch_get_main_queue()) {
                self.lockStateLabel.enabled = true
            }
            
            
        })
        
    }
    
    ///////////// trigger functions /////////////
    
    // turn lights on/off based on switch action
    
    func switchValueDidChange(sender:UISwitch!) {
        var newState : String
        
        if (sender.on == true){
            newState = "1"
        }
        else{
            newState = "0"
        }
        
        let tag : String = String(sender.tag)
        setLights(tag, state: newState)
    }
    
    // set temp based on slider values
    
    func rangeSliderValueChanged(rangeSlider: RangeSlider) {
        let minimumTemp : Int = Int(rangeSlider.lowerValue)
        let maximumTemp : Int = Int(rangeSlider.upperValue)
        dispatch_async(dispatch_get_main_queue()) {
            self.nestTemp.text = "(\(minimumTemp) - \(maximumTemp))"
        }
        setNests("32", minTemp: String(minimumTemp) , maxTemp: String(maximumTemp))
        print("Range slider value changed: (\(minimumTemp) \(maximumTemp))")
    }
    
    // set lock based on button action
    
    @IBAction func switchLockState(sender: UIButton) {
        var newState : String
        if sender.selected {
            newState = "0"
        } else {
            newState = "1"
        }
        sender.enabled = false
        setLocks("34", state: String(newState))
        print("New lock state: (\(newState))")
    }
    
    
    
    
}

