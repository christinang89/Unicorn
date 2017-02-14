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
    
    
    var authKey : String = "// NOTE TO SELF: REPLACE THIS WITH ACTUAL AUTHKEY"
    
    let rangeSlider = RangeSlider(frame: CGRect.zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(rangeSlider)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        rangeSlider.addTarget(self, action: #selector(ViewController.rangeSliderValueChanged(_:)), for: .valueChanged)
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            for _ in 0..<100
            {
                Thread.sleep(forTimeInterval: 1)
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
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.jsonResult.count;
    }
    
    // populating data in uitableview
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let url : String = "http://home.isidorechan.com/lights"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        cell.textLabel?.text = self.jsonResult[indexPath.row]["name"]! as! NSString as String;
        
        let lightId : String = self.jsonResult[indexPath.row]["id"] as! NSString as String
        
        let s = lightToggles[lightId]
        
        cell.accessoryType = UITableViewCellAccessoryType.none
        cell.accessoryView = s
        
        return cell
    }
    
    
    ///////////// loading functions /////////////
    
    // synchronous call to load initial light state
    
    func checkLights() {
        
        // create the request & response
        let url : String = "http://home.isidorechan.com/lights"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: URLResponse?
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: Data = try! NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: dataVal, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    jsonResult.append(result as! NSDictionary)
                    
                    let s = UISwitch(frame:CGRect(x: 0, y: 0, width: 0, height: 0))
                    let lightId = (result as? NSDictionary)?["id"] as! String
                    s.tag = Int(lightId)!
                    s.addTarget(self, action: #selector(ViewController.switchValueDidChange(_:)), for: .valueChanged);
                    
                    if (result as? NSDictionary)?["state"]! as! NSString == "1" {
                        s.setOn(true, animated: false)
                    } else {
                        s.setOn(false, animated: false)
                    }
                    
                    lightToggles.updateValue(s, forKey: (result as? NSDictionary)?["id"]! as! NSString as String)
                    
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
        var response: URLResponse?
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: Data = try! NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: dataVal, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    nestJsonResult.append(result as! NSDictionary)
                    let currentTemp : String = (result as? NSDictionary)?["currentTemp"] as! String
                    let maxTemp : String = (result as? NSDictionary)?["maxTemp"] as! String
                    let minTemp : String = (result as? NSDictionary)?["minTemp"] as! String
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
        var response: URLResponse?
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: Data = try! NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: dataVal, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                lockJsonResult.append(result as! NSDictionary)
                
                if (result as? NSDictionary)?["state"]! as! NSString == "1" {
                    lockStateLabel.setTitle("Locked", for: UIControlState.selected)
                    lockStateLabel.isSelected = true
                } else {
                    lockStateLabel.setTitle("Unlocked", for: UIControlState())
                    lockStateLabel.isSelected = false
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
        var response: URLResponse?
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: Data = try! NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: dataVal, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    let state : String = (result as? NSDictionary)?["state"] as! String
                    var lightState : Bool
                    if (state == "1") {
                        lightState = true
                    } else {
                        lightState = false
                    }
                    let lightId : String = (result as? NSDictionary)?["id"] as! String
                    let tempSwitch : UISwitch = lightToggles[lightId]! as UISwitch
                    if (tempSwitch.isOn != lightState) {
                        DispatchQueue.main.async {
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
        var response: URLResponse?
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: Data = try! NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: dataVal, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    let state : String = (result as? NSDictionary)?["state"] as! String
                    if (state == "1") {
                        if self.lockStateLabel.isSelected != true {
                            DispatchQueue.main.async {
                                self.lockStateLabel.isSelected = true
                                self.lockStateLabel.setTitle("Locked", for: UIControlState.selected)
                                print("lock changed to locked")
                            }
                        }
                    } else {
                        if self.lockStateLabel.isSelected == true {
                            DispatchQueue.main.async {
                                self.lockStateLabel.isSelected = false
                                self.lockStateLabel.setTitle("Unlocked", for: UIControlState())
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
        var response: URLResponse?
        request.url = URL(string: url)
        request.httpMethod = "GET"
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        let dataVal: Data = try! NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: dataVal, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                for (_, result) in jsonResponse {
                    // nestJsonResult.append(result as NSDictionary)
                    let currentTemp : String = (result as? NSDictionary)?["currentTemp"] as! String
                    let maxTemp : NSString = (result as? NSDictionary)?["maxTemp"] as! NSString
                    let minTemp : NSString = (result as? NSDictionary)?["minTemp"] as! NSString
                    if (self.nestJsonResult[0]["currentTemp"] as! String != currentTemp) {
                        self.nestJsonResult[0].setValue(currentTemp, forKey: "currentTemp")
                        DispatchQueue.main.async {
                            self.currentTempLabel.text = currentTemp
                            print("Nest current temp updated to \(currentTemp)")
                        }
                    }
                    if (self.nestJsonResult[0]["minTemp"] as! String != minTemp as String || self.nestJsonResult[0]["maxTemp"] as! String != maxTemp as String) {
                        self.nestJsonResult[0].setValue(minTemp, forKey: "minTemp")
                        self.nestJsonResult[0].setValue(maxTemp, forKey: "maxTemp")
                        DispatchQueue.main.async {
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
    
    func setLights(_ lightId : String, state : String) {
        // create the request & response
        let url : String = "http://home.isidorechan.com/lights/" + lightId
        let request : NSMutableURLRequest = NSMutableURLRequest()
        var response: URLResponse?
        var error: NSError?
        
        // create some JSON data and configure the request
        let jsonString = "{\"state\":\"" + state + "\"}"
        request.url = URL(string: url)
        request.httpBody = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: true)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        do {
            // send the request
            try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
        } catch let error1 as NSError {
            error = error1
        }
        
        // look at the response
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP response: \(httpResponse.statusCode)")
            print(response)
        } else {
            print("No HTTP response")
            print(error)
        }
    }
    
    
    // async call to switch nest temps
    
    func setNests(_ nestId : String, minTemp : String, maxTemp : String) {
        // create the request & response
        let url : String = "http://home.isidorechan.com/nests/" + nestId
        let request : NSMutableURLRequest = NSMutableURLRequest()
        
        // create some JSON data and configure the request
        let jsonString = "{\"password\":\"" + password + "\", \"minTemp\":\"" + minTemp + "\", \"maxTemp\":\"" + maxTemp + "\"}"
        request.url = URL(string: url)
        request.httpBody = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: true)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse?, data: Data?, error: NSError?) -> Void in
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    print(jsonResult)
                    DispatchQueue.main.async {
                        self.nestTemp.text = "(\(minTemp) - \(maxTemp))"
                    }
                    
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            
        } as! (URLResponse?, Data?, Error?) -> Void)
        
    }
    
    // async call to switch lock state
    
    func setLocks(_ lockId : String, state : String) {
        // create the request & response
        let url : String = "http://home.isidorechan.com/locks/" + lockId
        let request : NSMutableURLRequest = NSMutableURLRequest()
        
        // create some JSON data and configure the request
        let jsonString = "{\"password\":\"" + password + "\", \"state\":\"" + state + "\"}"
        request.url = URL(string: url)
        request.httpBody = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: true)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        
        // send the request
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse?, data: Data?, error: NSError?) -> Void in
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    // process jsonResult
                    print(jsonResult)
                    
                    if jsonResult["state"] != nil {
                        DispatchQueue.main.async {
                            if jsonResult["state"] as! NSString == "1" {
                                self.lockStateLabel.isSelected = true
                                self.lockStateLabel.setTitle("Locked", for: UIControlState.selected)
                            }
                            else {
                                
                                self.lockStateLabel.isSelected = false
                                self.lockStateLabel.setTitle("Unlocked", for: UIControlState())
                            }
                            
                        }
                    }
                    
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            
            DispatchQueue.main.async {
                self.lockStateLabel.isEnabled = true
            }
            
            
        } as! (URLResponse?, Data?, Error?) -> Void)
        
    }
    
    ///////////// trigger functions /////////////
    
    // turn lights on/off based on switch action
    
    func switchValueDidChange(_ sender:UISwitch!) {
        var newState : String
        
        if (sender.isOn == true){
            newState = "1"
        }
        else{
            newState = "0"
        }
        
        let tag : String = String(sender.tag)
        setLights(tag, state: newState)
    }
    
    // set temp based on slider values
    
    func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        let minimumTemp : Int = Int(rangeSlider.lowerValue)
        let maximumTemp : Int = Int(rangeSlider.upperValue)
        DispatchQueue.main.async {
            self.nestTemp.text = "(\(minimumTemp) - \(maximumTemp))"
        }
        setNests("32", minTemp: String(minimumTemp) , maxTemp: String(maximumTemp))
        print("Range slider value changed: (\(minimumTemp) \(maximumTemp))")
    }
    
    // set lock based on button action
    
    @IBAction func switchLockState(_ sender: UIButton) {
        var newState : String
        if sender.isSelected {
            newState = "0"
        } else {
            newState = "1"
        }
        sender.isEnabled = false
        setLocks("34", state: String(newState))
        print("New lock state: (\(newState))")
    }
    
    
    
    
}

