/*
 * zhiweixu 03/25/2018
 *
 * 
 */

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate {

  @IBOutlet weak var mapView: MKMapView!
  fileprivate let locationManager = CLLocationManager()
  fileprivate var startedLoadingPOIs = false
  fileprivate var places = [Place]()
  fileprivate var arViewController : ARViewController!
  
  @IBAction func showARController(_ sender: Any) {
    arViewController = ARViewController()
    arViewController.dataSource = self
//    摄像头界面中最多显示的标记个数
    arViewController.maxVisibleAnnotations = 30
//    设置poi随着摄像头移动的灵敏度
    arViewController.headingSmoothingFactor = 0.05
    arViewController.setAnnotations(places)
    self.present(arViewController, animated: true, completion: nil)
  }
  var targets = [ARItem]()
  var userLocation: CLLocation?
  var selectedAnnotation: MKAnnotation?
  
  var update = false
//  预先根据用户的定位埋伏好Pokemon
  func setupLocations(myLatitude: Double, myLongitude: Double) {
    let firstTarget = ARItem(itemDescription: "wolf", location: CLLocation(latitude: myLatitude+0.00002, longitude: myLongitude+0.00001), itemNode: nil)
    targets.append(firstTarget)
    let secondTarget = ARItem(itemDescription: "pokemon", location: CLLocation(latitude: myLatitude+0.00012, longitude: myLongitude+0.000011), itemNode: nil)
    targets.append(secondTarget)
    let thirdTarget = ARItem(itemDescription: "dragon", location: CLLocation(latitude: myLatitude-0.000012, longitude: myLongitude-0.000011), itemNode: nil)
    targets.append(thirdTarget)
    for item in targets {
      let annotation = MapAnnotation(location: item.location.coordinate, item: item)
      self.mapView.addAnnotation(annotation)
    }
  }
  func showInfoView(forPlace place: Place ) {
    let alert = UIAlertController(title: place.placeName, message: place.infoText, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    
    arViewController.present(alert, animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.startUpdatingLocation()
    if CLLocationManager.authorizationStatus() == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    }
    update = true
  }
}

extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapview: MKMapView, didUpdate userLocation: MKUserLocation) {
    self.userLocation = userLocation.location
    if update {
      if let userCoordinate = self.userLocation {
        setupLocations(myLatitude: userCoordinate.coordinate.latitude, myLongitude: userCoordinate.coordinate.longitude)
        update = false
      }
    }
  }
//  点击Pokemon图标后进入摄像头界面
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    let coordinate = view.annotation!.coordinate
    if let userCoordinate = userLocation {
      if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) < 50 {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ARViewController") as? ViewController {
          viewController.delegate = self
          
          if let mapAnnotation = view.annotation as? MapAnnotation {
            viewController.target = mapAnnotation.item
            viewController.userLocation = mapView.userLocation.location!
            
            selectedAnnotation = view.annotation
            self.present(viewController, animated: true, completion: nil)
          }
        }
      }
    }
  }
//  places在用户更新位置的时候也要进行更新
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //
    if locations.count > 0 {
      let location = locations.last!
      print("Accuracy: \(location.horizontalAccuracy)")
      
      //
      if location.horizontalAccuracy < 100 {
        //根据用户当前定位缩放地图
        manager.stopUpdatingLocation()
        let span = MKCoordinateSpan(latitudeDelta: 0.014, longitudeDelta: 0.014)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.region = region
        
        if !startedLoadingPOIs {
          startedLoadingPOIs = true
          let loader = PlacesLoader()
          loader.loadPOIS(location: location, radius: 1000) { placesDict, error in
            if let dict = placesDict {
              //              guard 保证返回的结果的格式
              guard let placeArray = dict.object(forKey: "results") as? [NSDictionary] else {return}
              //              遍历收到的POI队列
              for placeDict in placeArray {
                //                获取需要的信息
                //                纬度&经度
                let latitude = placeDict.value(forKeyPath: "geometry.location.lat") as! CLLocationDegrees
                let longitude = placeDict.value(forKeyPath: "geometry.location.lng") as! CLLocationDegrees
                let reference = placeDict.object(forKey: "reference") as! String
                let name = placeDict.object(forKey: "name") as! String
                let address = placeDict.object(forKey: "vicinity") as! String
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                let place = Place(location: location, reference: reference, name: name, address: address)
                print(place)
                self.places.append(place)
                //                构造地图标记
                let annotation = PlaceAnnotation(location: place.location!.coordinate, title: place.placeName)
                //                因为要修改UI,所以使用主线程
                DispatchQueue.main.async {
                  self.mapView.addAnnotation(annotation)
                }
              }
              
              
            }
          }
        }
      }
    }
  }
}

extension MapViewController: ARControllerDelegate {
  func viewController(controller: ViewController, tappedTarget: ARItem) {
//    关闭AR界面
    self.dismiss(animated: true, completion: nil)
//    获取我们用火球杀死的ARItem
    let index = self.targets.index(where: {$0.itemDescription == tappedTarget.itemDescription})
    self.targets.remove(at: index!)
//    将它从地图上移去
    if selectedAnnotation != nil {
      mapView.removeAnnotation(selectedAnnotation!)
    }
  }
  
}

extension MapViewController: ARDataSource {
  func ar(_ arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView {
    let annotationView = AnnotationView()
    annotationView.annotation = viewForAnnotation
    annotationView.delegate = self
    annotationView.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
    
    return annotationView
  }
}
extension MapViewController: AnnotationViewDelegate {
  func didTouch(annotationView: AnnotationView) {
    if let annotation = annotationView.annotation as? Place {
      let placeLoader = PlacesLoader()
      //      ?? one imoport question
      placeLoader.loadDetailInformation(forPlace: annotation) {resultDict, error in
        if let infoDict = resultDict?.object(forKey: "result") as? NSDictionary {
          annotation.phoneNumber = infoDict.object(forKey: "formatted_phone_number") as? String
          annotation.website = infoDict.object(forKey: "website") as? String
          annotation.rating = infoDict.object(forKey: "rating") as? String
          self.showInfoView(forPlace: annotation)
        }
      }
    }
  }
}

