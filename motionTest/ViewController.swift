//
//  ViewController.swift
//  motionTest
//
//  Created by Alif Mahardhika on 17/07/21.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    @IBOutlet weak var gyroLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var zLabel: UILabel!
    var motion = CMMotionManager()
    var queue = OperationQueue()
    var prevHeading = 0.0
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var timer :  Timer?
    var prevMaxZ: Double?
    var prevMaxY = 0.0
    var distance = 0.0
    var arrAcc = [Double]()

    @IBOutlet weak var activityTypeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("init")
        startUpdating()
        startQueuedUpdates()
        startAccelerometers()
        // Do any additional setup after loading the view.
    }
    
    
    func startAccelerometers() {
        print("IN")
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
        self.motion.accelerometerUpdateInterval = 1.0 / 10.0  // 60 Hz
          self.motion.startAccelerometerUpdates()

          // Configure a timer to fetch the data.
        self.timer = Timer(fire: Date(), interval: (1.0/10.0),
                           repeats: true, block: { [self] (timer) in
             // Get the accelerometer data.
             if let data = self.motion.accelerometerData {
                let z = data.acceleration.z
                arrAcc.append(z)
//                let z = data.acceleration.z
                let x = data.acceleration.x
                let y = data.acceleration.y
                            
                // Use the accelerometer data in your app.
                
//                USE Z BECOS KEDEPAN:
                DispatchQueue.main.async {
//                    PER SECOND, avg of 10 acc measurement
                    if self.arrAcc.count == 30{
//                        print(self.arrAcc)
                        var avgAcc = self.arrAcc.reduce(0, +) / Double(self.arrAcc.count)
                        self.arrAcc.removeAll()
//                        print("AVG: \(avgAcc)")
//                        avgAcc = avgAcc
                        if abs(avgAcc*9.8) > 0.5 && self.activityTypeLabel.text == "Walking"{
                            let distpersec = (abs(avgAcc*9.8) * 9) //results in movement per 1 second
                            print("AVG: \(abs(avgAcc*9.8))")
                            print("DIST: \(distpersec)")
    //                        print("DIST/SEC: \(distpersec)")
                            self.distance += distpersec
                            self.xLabel.text = String(format: "DIST: %.3f", self.distance )
                            self.zLabel.text = String(format: "Z: %.3f", (abs(avgAcc*9.8)))
    //                        self.xLabel.text = String(format: "X: %.3f", x)
    //                        self.yLabel.text = String(format: "Y: %.3f", y)
    //                        if prevMaxY == 0 || prevMaxY < y {
    //                            prevMaxY = y
    //                            self.yLabel.text = String(format: "Y: %.3f", prevMaxY)
    //                        }
                        }
                        else {
                            print("stationary")
                            self.zLabel.text = "DIEM"
                        }
                    }
                }
             }
                    
//                }
//             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: .default)
       }
    }
    
    private func startCountingSteps() {
        if self.distanceLabel.text == "dist"{
            self.distanceLabel.text = "waiting"
        }
      pedometer.startUpdates(from: Date()) {
          [weak self] pedometerData, error in
          guard let pedometerData = pedometerData, error == nil else {
            print("ERROR")
            return
          }
        print("called")
//        print(pedometerData.distance)
          DispatchQueue.main.async {
            self?.distanceLabel.text = pedometerData.numberOfSteps.stringValue
          }
      }
    }
    
    
    private func startTrackingActivityType() {
      activityManager.startActivityUpdates(to: OperationQueue.main) {
          [weak self] (activity: CMMotionActivity?) in

          guard let activity = activity else { return }
          DispatchQueue.main.async {
              if activity.walking {
                  self?.activityTypeLabel.text = "Walking"
              } else if activity.stationary {
                  self?.activityTypeLabel.text = "Stationary"
              } else if activity.running {
                  self?.activityTypeLabel.text = "Running"
              } else if activity.automotive {
                  self?.activityTypeLabel.text = "Automotive"
              }
          }
      }
    }
    
    private func startUpdating() {
      if CMMotionActivityManager.isActivityAvailable() {
          startTrackingActivityType()
      }

      if CMPedometer.isStepCountingAvailable() {
          startCountingSteps()
      }
    }
    
    func cardinalValue(heading: Double) -> String {
            switch heading {
            case 0 ..< 22.5:
                return "N"
            case 22.5 ..< 67.5:
                return "NE"
            case 67.5 ..< 112.5:
                return "E"
            case 112.5 ..< 157.5:
                return "SE"
            case 157.5 ..< 202.5:
                return "S"
            case 202.5 ..< 247.5:
                return "SW"
            case 247.5 ..< 292.5:
                return "W"
            case 292.5 ..< 337.5:
                return "NW"
            case 337.5 ... 360.0:
                return "N"
            default:
                return ""
            }
        }
    
    
    func startQueuedUpdates() {
       if motion.isDeviceMotionAvailable {       self.motion.deviceMotionUpdateInterval = 1.0 / 2.0
          self.motion.showsDeviceMovementDisplay = true
          self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                   to: self.queue, withHandler: { (data, error) in
             // Make sure the data is valid before accessing it.
             if let validData = data {
                // Get the attitude relative to the magnetic north reference frame.
//                let roll = validData.attitude.roll
//                let pitch = validData.attitude.pitch
//                let yaw = validData.attitude.yaw
                let heading = validData.heading
                
//                self.queue.performSelector(onMainThread: <#T##Selector#>, with: <#T##Any?#>, waitUntilDone: <#T##Bool#>)
//                print(self.cardinalValue(heading: heading))
//                print(pitch)
//                print(yaw)
                DispatchQueue.main.async {
                    if self.prevHeading == 0.0 {
                        self.prevHeading = heading
                    }
                    if (abs(self.prevHeading - heading) >= 30){
//                        print("BELOK")
                        UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                            self.view.backgroundColor = .red
                        }, completion:{_ in
                            self.view.backgroundColor = .black
                        })
                        
                    }
                    self.prevHeading = heading
//                    self.gyroLabel.text = String(format: "heading: %.3f", heading)
                    self.gyroLabel.text = self.cardinalValue(heading: heading)
                }
                
             }
          })
       }
    }

}

