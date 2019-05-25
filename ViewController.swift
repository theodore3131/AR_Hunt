//
//  ViewController.swift
//  AR_Hunt
//
//  Created by zhiwei xu on 25/03/2018.
//
import UIKit
import MapKit
import SceneKit
import AVFoundation
import CoreLocation

protocol ARControllerDelegate {
  func viewController(controller: ViewController, tappedTarget: ARItem)
}
class ViewController: UIViewController {
  @IBOutlet weak var sceneView: SCNView!
  @IBOutlet weak var leftIndicator: UILabel!
  @IBOutlet weak var rightIndicator: UILabel!
  var delegate : ARControllerDelegate?
  var cameraSession: AVCaptureSession?
  var cameraLayer: AVCaptureVideoPreviewLayer?
  var target: ARItem!
  var locationManager = CLLocationManager()
  var heading: Double = 0
  var userLocation = CLLocation()
  let scene = SCNScene()
  let cameraNode = SCNNode()
  let targetNode = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
  
  func createCaptureSession() -> (session: AVCaptureSession?, error: NSError?) {
    var error: NSError?
    var captureSession: AVCaptureSession?
//    获取iPhone的后置摄像头
    let backVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
    if backVideoDevice != nil {
      var videoInput: AVCaptureDeviceInput!
      do {
        videoInput = try AVCaptureDeviceInput(device: backVideoDevice!)
      } catch let error1 as NSError {
        error = error1
        videoInput = nil
      }
      
      if error == nil {
        captureSession = AVCaptureSession()
        
        if captureSession!.canAddInput(videoInput) {
          captureSession!.addInput(videoInput)
        } else {
          error = NSError(domain: "", code: 0, userInfo: ["description": "Error adding video input."])
        }
      } else {
        error = NSError(domain: "", code: 1, userInfo: ["description": "Error creating capture device input."])
      }
    } else {
      error = NSError(domain: "", code: 2, userInfo: ["description": "Back video device not found."])
    }
    return (session: captureSession, error: error)
  }
  
  func loadCamera() {
    let captureSessionResult = createCaptureSession()
    
    guard captureSessionResult.error == nil,
     let session = captureSessionResult.session else {
        print("Error creating capture session")
        return
    }
    
    self.cameraSession = session
    let cameraLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession!)
    
    cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    cameraLayer.frame = self.view.bounds
    
    self.view.layer.insertSublayer(cameraLayer, at: 0)
    self.cameraLayer = cameraLayer
  }
  func repositionTarget() {
//    根据用户和怪兽的位置 获取用户摄像头朝向
    let heading = getHeadingForDirectionFromCoordinate(from: userLocation, to: target.location)
    
    let delta = heading - self.heading
//    并根据用户摄像头朝向显示左右箭头
//    delta在【-15，15】之间时，隐藏箭头，此时怪兽会出现在屏幕上
    if delta < -15.0 {
      leftIndicator.isHidden = false
      rightIndicator.isHidden = true
    } else if delta > 15 {
      leftIndicator.isHidden = true
      rightIndicator.isHidden = false
    } else {
      leftIndicator.isHidden = true
      rightIndicator.isHidden = true
    }
    
    let distance = userLocation.distance(from: target.location)
    
    if let node = target.itemNode {
      if node.parent == nil {
        node.position = SCNVector3(x: Float(delta), y: 0, z: Float(-distance))
        scene.rootNode.addChildNode(node)
      } else {
//        清除所有动作，并把node移动到当前的给定位置
//        这里的坐标轴z朝向屏幕，x,y分别水平和垂直方向
        node.removeAllActions()
        node.runAction(SCNAction.move(to: SCNVector3(x: Float(delta), y: 0, z: Float(-distance)), duration: 0.2))
      }
    }
  }
//  弧度角度转换函数
  func radiansToDegrees(_ radians: Double) -> Double {
    return (radians) * (180.0/Double.pi)
  }
  func degreesToRadians(_ degrees: Double) -> Double {
    return (degrees) * (Double.pi/180.0)
  }

  func getHeadingForDirectionFromCoordinate(from: CLLocation, to: CLLocation) -> Double {
    let fLat = degreesToRadians(from.coordinate.latitude)
    let fLng = degreesToRadians(from.coordinate.longitude)
    let tLat = degreesToRadians(to.coordinate.latitude)
    let tLng = degreesToRadians(to.coordinate.longitude)
//    反正切函数求两个点形成的斜率的角度，这里需要用三角函数使用经纬度计算两点间距离
    let degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)))
    
    if degree >= 0 {
      return degree
    } else {
      return degree+360
    }
  }
  
  func setupTarget() {
    let scene = SCNScene(named: "art.scnassets/\(target.itemDescription).dae")
    var enemy = SCNNode()
    if target.itemDescription == "pokemon" {
      let wrapperNode = SCNNode()
      for child: SCNNode in (scene?.rootNode.childNodes)! {
        wrapperNode.addChildNode(child)
      }
      enemy = wrapperNode
    }
    else {
      enemy = (scene?.rootNode.childNode(withName: target.itemDescription, recursively: true))!
    }
    if target.itemDescription == "dragon" {
      enemy.position = SCNVector3(x: 0, y: -15, z: -10)
    }
    else if target.itemDescription == "pokemon" {
      enemy.position = SCNVector3(x: 0, y: 0, z: 10)
    }
    else {
      enemy.position = SCNVector3(x: 0, y: 0, z: -10)
    }
    
    let node = SCNNode()
    node.addChildNode(enemy)
    node.name = "enemy"
    self.target.itemNode = node
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    let touch = touches.first!
    let location = touch.location(in: sceneView)
    
    let hitResult = sceneView.hitTest(location, options: nil)
    
    let fireBall = SCNParticleSystem(named: "Fireball.scnp", inDirectory: nil)
    
    let emitterNode = SCNNode()
    emitterNode.position = SCNVector3(x: 0, y: -5, z: 10)
    emitterNode.addParticleSystem(fireBall!)
    scene.rootNode.addChildNode(emitterNode)
//    向怪兽扔火球
    if hitResult.first != nil {
      target.itemNode?.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.5), SCNAction.removeFromParentNode(), SCNAction.hide()]))
      let moveAction = SCNAction.move(to: target.itemNode!.position, duration: 0.5)
      let waitAction = SCNAction.wait(duration: 0.5)
      let runAction = SCNAction.run({_ in self.delegate?.viewController(controller: self, tappedTarget: self.target)})
      let sequence = SCNAction.sequence([moveAction,waitAction,runAction])
      
      emitterNode.runAction(sequence)
      
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    loadCamera()
    self.cameraSession?.startRunning()
//    使用delegate获取用户的摄像机头朝向
    self.locationManager.delegate = self
    self.locationManager.startUpdatingHeading()
    
    sceneView.scene = scene
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x:0, y:0, z:10)
    scene.rootNode.addChildNode(cameraNode)
    
    setupTarget()
  }
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
extension ViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    self.heading = fmod(newHeading.trueHeading, 360.0)
    repositionTarget()
  }
}

