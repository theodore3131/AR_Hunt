//
//  MapAnnotation.swift
//  AR_Hunt
//
//  Created by zhiwei xu on 25/03/2018.
//

import Foundation
import MapKit

class MapAnnotation: NSObject, MKAnnotation {
  let coordinate: CLLocationCoordinate2D
  let title: String?
  
  let item: ARItem
  
  init(location: CLLocationCoordinate2D, item: ARItem) {
    self.coordinate = location
    self.item = item
    self.title = item.itemDescription
    
    super.init()
  }
}
