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

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
    

class ViewControllerA: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var a: MKMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        let initialLocation = CLLocation(latitude: 39.329143, longitude: -76.620534)
        let regionRadius: CLLocationDistance = 700
        func centerMapOnLocation(Location: CLLocation)
        {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(Location.coordinate, regionRadius*2.0, regionRadius*2.0)
            a.setRegion(coordinateRegion, animated: true)
        }
        centerMapOnLocation(initialLocation)
        
        //test pin
        let pinPlot = Pinplotting(coordinate: CLLocationCoordinate2D(latitude: 39.329143, longitude: -76.620534))
        a.addAnnotation(pinPlot)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func dropPin(lat: Double, long: Double) {
        //var coord = CLLocationCoordinate2DMake(CLLocationDegrees(Double(lat)), CLLocationDegrees(Double(long)))
        //var pin = Pinplotting(coordinate: coord)
        //a.addAnnotation(pin)
        
        a.addAnnotation(Pinplotting(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))))
        //println("point @ \(lat),\(long)")
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
                self.sendFootstep(pm)
            }
        })
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Error" + error.localizedDescription)
    }
    
    
    func sendFootstep(placemark: CLPlacemark) {
        self.locationManager.stopUpdatingLocation()
        //println(placemark.location) //<+37.78585200,-122.40652900> +/- 100.00m (speed -1.00 mps / course -1.00) @ 9/12/15, 5:15:10 PM Eastern Daylight Time
        
        //turn location into a string
        var locationString = String(stringInterpolationSegment: placemark.location)
        
        var longitudeString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 1), end: advance(locationString.endIndex, -105))))
        var latitudeString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 14), end: advance(locationString.endIndex, -91))))
        var dateString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 76), end: advance(locationString.endIndex, -21))))
        var timeString = String(locationString.substringWithRange(Range<String.Index>(start: advance(locationString.startIndex, 85), end: advance(locationString.endIndex, -21))))
        
        //println("long:\(longitudeString)\t lat:\(latitudeString)\t datetime:\(dateString)") //long:+37.7858520	 lat:-122.4065290	 datetime:9/12/15, 5:18:13 PM
        //dateString contains date and time
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy, hh:mm:ss a"
        var date = dateFormatter.dateFromString(dateString)
        //println(date!) //2015-09-12 21:20:03 +0000
        
        var timestamp = (date!.timeIntervalSince1970)
        //Gets us EPOCH time
        //println(timestamp) //1442092803.0
        
        var ip = getWiFiAddress()!
        //println(ip) //10.188.163.216
        
        let request = NSMutableURLRequest(URL: NSURL(string: URL+":3000/api/post")!)
        request.HTTPMethod = "POST"
        
        let postString = "ip=\(ip)&time=\(timestamp)&lat=\(latitudeString)&long=\(longitudeString)"
        println("ip:\(ip)\t time:\(timestamp)\t lat:\(latitudeString)\t long:\(longitudeString)")
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request)
        {
            data, response, error in
            
            if error != nil
            {
                println(error!)
                return
            }
            
            //println("response = \(response)")
            /*  response = <NSHTTPURLResponse: 0x7fb254805a10> { URL: http://52.21.51.134:3000/api/post } { status code: 200, headers {
                Connection = "keep-alive";
                Date = "Sat, 12 Sep 2015 21:29:10 GMT";
                "Transfer-Encoding" = Identity;
                Vary = "Accept-Encoding";
                } }                                         */

            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
            println(responseString!) //Data recorded! 10.188.163.216 (180134872) at -122.4065290, 37.7858520 on Sat Sep 12 2015 21:36:25 GMT+0000 (UTC)
            //.substringToIndex(count(responseString!)-1)   .substringToIndex(name.endIndex.predecessor())
            
            self.getFootsteps(min: MIN)
        }
        task.resume()
    }
    
    func getFootsteps(min: Int = 5) {
        DataManager.getData(min, success: { (footsteps) -> Void in
            let json = JSON(data: footsteps)
            let footsteps = json.array!
            //println(footsteps)
            for footstep in footsteps {
                let ip = footstep["ip"].number!
                let time = footstep["time"].number!
                let lat = footstep["lat"].number!
                let long = footstep["long"].number!
                println("ip:\(ip)\t time:\(time)\t lat:\(lat)\t long:\(long)")
                self.dropPin(Double(lat), long: Double(long))
            }
        })
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
    
}













