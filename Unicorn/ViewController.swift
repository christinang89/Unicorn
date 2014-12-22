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
    
    var lightsName = [String:String]()
    var lightsState = [String:String]()
    var jsonResult : [NSDictionary] = []
    var lightToggles = [String:UISwitch]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkLights()
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
        
        var s = UISwitch(frame:CGRectMake(0, 0, 0, 0))
        var lightId = self.jsonResult[indexPath.row]["id"] as String
        s.tag = lightId.toInt()!
        s.addTarget(self, action: "switchValueDidChange:", forControlEvents: .ValueChanged);
        
        if self.jsonResult[indexPath.row]["state"]! as NSString == "1" {
            s.setOn(true, animated: false)
        } else {
            s.setOn(false, animated: false)
        }
        
        lightToggles.updateValue(s, forKey: self.jsonResult[indexPath.row]["id"]! as NSString)
        
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
        
        // look at the response
        if (jsonResponse != nil) {
            for (id, result) in jsonResponse {
                jsonResult.append(result as NSDictionary)
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

    
    

}

