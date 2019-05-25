
import Foundation
import CoreLocation

class Place: ARAnnotation {
  let reference: String
  let placeName: String
  let address: String
  var phoneNumber: String?
  var website: String?
  var rating: String?
  
  var infoText: String {
    get {
      var info = "Address: \(address)"
      
      if phoneNumber != nil {
        info += "\nPhone: \(phoneNumber!)"
      }
      
      if website != nil {
        info += "\nweb: \(website!)"
      }
      
      if rating != nil {
        info += "\nrating: \(rating!)"
      }
      
      return info
    }
  }
  
  init(location: CLLocation, reference: String, name: String, address: String) {
    placeName = name
    self.reference = reference
    self.address = address
    
    super.init()
    
    self.location = location
  }
  
  override var description: String {
    return placeName
  }
}
