//
//  ARItem.swift
//  AR_Hunt
//
//  Created by zhiwei xu on 25/03/2018.
//

import Foundation
import CoreLocation
import SceneKit

struct ARItem {
  let itemDescription: String
  let location: CLLocation
  var itemNode: SCNNode?
}
