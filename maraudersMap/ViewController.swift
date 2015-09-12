//
//  ViewController.swift
//  maraudersMap
//
//  Created by Jake Sager on 9/11/15.
//  Copyright (c) 2015 Jake Sager. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    
    let locationManager = CLLocationManager()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: { (placemarks, error) -> Void in
            
            if error != nil
            {
                println("Error: " + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0
            {
                let pm = placemarks[0] as! CLPlacemark
                self.displayLocationInfo(pm)
            }
            
        })
        
    }
    //Gets us our location
    
    
    func getFootsteps()
    {
        println("start getFootsteps")
        DataManager.getFootsteps { (footsteps) -> Void in
            let json = JSON(data: footsteps)
            let footsteps = json.array!
            //println(footsteps)
            for footstep in footsteps {
                let ip = footstep["ip"].number!
                let lat = footstep["lat"].number!
                let long = footstep["long"].number!
                let time = footstep["time"].number!
                println("ip=\(ip)&time=\(time)&lat=\(lat)&long=\(long)")
            }
        }
        println("end getFootsteps")
    }
    
    
    func displayLocationInfo(placemark: CLPlacemark)
    {
        self.locationManager.stopUpdatingLocation()
        println(placemark.location)
        
        //turn location into a string
        
        var locationString = String(stringInterpolationSegment: placemark.location)
        
        var longitudeString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 1), end: advance(locationString.endIndex, -105))))
        
        var latitudeString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 14), end: advance(locationString.endIndex, -91))))
        
        var timeString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 85), end: advance(locationString.endIndex, -21))))
        
        var dateString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 76), end: advance(locationString.endIndex, -21))))
        
        println(longitudeString)
        println(latitudeString)
        println(timeString)
        println(dateString)
        //dateString contains date and time
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy, hh:mm:ss a"
        
        var date = dateFormatter.dateFromString(dateString)
        
        println(date)
        
        var timestamp = (date!.timeIntervalSince1970)
        //Gets us EPOCH time
        println(timestamp)
        
        var ip = getWiFiAddress()!
        
        println(ip)
        
        /*
        
        these are the final three variables we care about:
        
        println(longitudeString)
        println(latitudeString)
        println(timeString)
        */
        
        
        //send the stuff here POST
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://52.21.51.134:3000/api/post")!)
        request.HTTPMethod = "POST"
        
        //send the variables here i think
        
        let postString = "ip=\(ip)&time=\(timestamp)&lat=\(latitudeString)&long=\(longitudeString)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request)
        {
            data, response, error in
            
            if error != nil
            {
                println("error=\(error)")
                return
            }
            
            println("response = \(response)")
            
            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
            println("responseString = \(responseString)")
            
            self.getFootsteps()
        }
        task.resume()
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Error" + error.localizedDescription)
    }
    
    //http://stackoverflow.com/questions/30748480/swift-get-devices-ip-address
    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let interface = ptr.memory
                
                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.memory.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    // Check interface name:
                    if let name = String.fromCString(interface.ifa_name) where name == "en0" {
                        
                        // Convert interface address to a human readable string:
                        var addr = interface.ifa_addr.memory
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                        address = String.fromCString(hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    //POSTED
    
    
    
    /*
    
    these are the final three variables we care about:
    
    println(longitudeString)
    println(latitudeString)
    println(timeString)
    */
    
    
    //Gets map image
    //http://52.21.51.134:3000/api/get?min=10000
    

    
}



class ViewControllerA: UIViewController {
    
    
    
    @IBOutlet weak var a: MKMapView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let initialLocation = CLLocation(latitude: 39.329143, longitude: -76.620534)
        let regionRadius: CLLocationDistance = 700
        func centerMapOnLocation(Location: CLLocation)
        {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(Location.coordinate, regionRadius*2.0, regionRadius*2.0)
            a.setRegion(coordinateRegion, animated: true)
        
        }
        
        centerMapOnLocation(initialLocation)
        
    }

    
    
    
    
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}













