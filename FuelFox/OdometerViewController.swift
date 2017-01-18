//
//  OdometerViewController.swift
//  FuelFox
//
//  Created by Shayne O'Sullivan on 10/13/16.
//  Copyright © 2016 Shayne O'Sullivan. All rights reserved.
//

import UIKit
import VinliNet

class OdometerViewController: UIViewController {
    
    let defaults = UserDefaults.standard

    var vinli:VLService!
    var device:VLDevice!
    var vehicle:VLVehicle!
    var odometerString:String!
    
    @IBOutlet weak var odometerTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getOdometer(vehicle: vehicle)
        // Do any additional setup after loading the view.
    }
    
    //get current odometer reading and fill in text input
    func getOdometer(vehicle:VLVehicle) {
        vinli.getDistancesForVehicle(withId: vehicle.vehicleId, onSuccess: { (pager: VLDistancePager?, response: HTTPURLResponse?) in
            
            if let lastDistance = pager?.distances[0] {
                
                let distance = lastDistance as! VLDistance
                
                let distanceMiles = Int(round(Double(distance.value.intValue) * 0.00062138))
                
                self.odometerTextField.text = distanceMiles.description
                print("got distance \(distanceMiles.description)")
            }
            
        }) { (error: Error?, responst: HTTPURLResponse?, bodyString: String?) in
                print("error getting current odometer for vehicle: \(bodyString)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateButton(_ sender: AnyObject) {
        
        //delete the last odometer if there is one
        
        if defaults.string(forKey: "\(self.vehicle.vehicleId)lastOdomterId") != nil{
            vinli.deleteOdometer(withId: defaults.string(forKey: "\(self.vehicle.vehicleId)lastOdometerId")!, onSuccess: { (response: HTTPURLResponse?) in
                print("deleted Odometer \(self.defaults.string(forKey: "\(self.vehicle.vehicleId)lastOdometerId"))")
                }, onFailure: { (eroor: Error?, response: HTTPURLResponse?, bodyString: String?) in
                    print("error deleting odometer \(bodyString)")
            })
        }
        
        var readingNum:NSNumber!
        let date:String!
        let unit:VLDistanceUnit!
        

        //build out the VLOdometer
        date = VLDateFormatter.string(from: Date())
        unit = VLDistanceUnit.miles
        
        //convert the string from input field to NSNumber
        
        let odoString = odometerTextField.text
        if let odoInt = Int(odoString!) {
            readingNum = NSNumber(value:odoInt)
        }
        
        
        let odometer:VLOdometer! = VLOdometer.init(reading: readingNum, dateStr: date!, unit: unit)
        
        vinli.createOdometer(odometer, vehicleId: vehicle.vehicleId, onSuccess: { (createdOdometer: VLOdometer?, response: HTTPURLResponse?) in
            print("created an odometer!\(response)")

            self.defaults.set(createdOdometer?.odometerId, forKey: "\(self.vehicle.vehicleId)lastOdometer")
            
        }) { (error: Error?, response: HTTPURLResponse?, bodyString:String?) in
                print("error creating odometer report \(bodyString)")
        }
    }
    
     //MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let id = segue.identifier{
            if (id == "OdometerToDetailSegue") {
                let newVc = segue.destination as! DeviceDetailViewController

                if let device:VLDevice? = self.device {
                    newVc.device = device
                }

            }
        }
         
    }

}
