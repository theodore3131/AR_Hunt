//
//  PlaceAnnotation.swift .swift
//  Places
//
//  Created by zhiwei xu on 2018/6/3.

import Foundation
import MapKit

class PlaceAnnotation: NSObject, MKAnnotation {
  let coordinate: CLLocationCoordinate2D
  let title: String?
  init(location: CLLocationCoordinate2D, title: String) {
    self.coordinate = location
    self.title = title
    
    super.init()
  }
  
  
}
