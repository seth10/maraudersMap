//
//  Pinplotting.swift
//  maraudersMap
//
//  Created by Jake Sager on 9/12/15.
//  Copyright (c) 2015 Jake Sager. All rights reserved.
//

import Foundation
import MapKit

//this class defines the coordinate to plot

class Pinplotting: NSObject, MKAnnotation {
    


    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {

        self.coordinate = coordinate
        
        super.init()
    }
    



}