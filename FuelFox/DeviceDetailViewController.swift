//
//  DeviceDetailViewController.swift
//  FuelFox
//
//  Created by Shayne O'Sullivan on 10/11/16.
//  Copyright © 2016 Shayne O'Sullivan. All rights reserved.
//

import UIKit
import MapKit
import VinliNet

class DeviceDetailViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var latestVehicleLabel: UILabel!
    @IBOutlet weak var batteryStatusLabel: UILabel!
    @IBOutlet weak var fuelLevelLabel: UILabel!
    @IBOutlet weak var odometerLabel: UILabel!
    @IBOutlet weak var odometerButton: UIButton!
    
    
    var vinli:VLService!
    var device:VLDevice!
    var latestLocation:VLLocation!
    var latestVehicle:VLVehicle!
    var batteryStatus:String!
    var fuelLevel:Double!

    override func viewDidLoad() {
        super.viewDidLoad()

        if VLSessionManager.loggedIn() {
            deviceNameLabel.text = ""
            vinli = VLService.init(session: VLSessionManager.currentSession())
            deviceNameLabel.text = device.name
            getLocationForDevice()
            getLatestVehicle()
            getFuelLevel(device: device)
            

        }
    }
    
    //get device location and drop pin on map
    func getLocationForDevice() {
        vinli.getLocationsForDevice(withId: device.deviceId, limit: 1, until: nil, since: nil, sortDirection: nil, onSuccess: {(locationPager: VLLocationPager?, response: HTTPURLResponse?) in
            
            if let location = locationPager?.locations[0]{
                self.latestLocation = location as! VLLocation
                
                //create a coordinate to set region/zoom
                let coordinate = CLLocationCoordinate2DMake(self.latestLocation.latitude, self.latestLocation.longitude)
                let region = MKCoordinateRegionMakeWithDistance(coordinate, 200, 200)
                self.mapView.setRegion(region, animated: false)
                
                //create pin and drop on map
                let pin = MKPointAnnotation()
                pin.coordinate.latitude = self.latestLocation.latitude
                pin.coordinate.longitude = self.latestLocation.longitude
                pin.title = self.device.name
    
                self.mapView.addAnnotation(pin)
                
                
            }
            
        }) { (error: Error?, response:HTTPURLResponse?, bodyString: String?) in
                print("error getting locations: \(bodyString)")
        }
    }
    
    func getLatestVehicle() {
        vinli.getLatestVehicleForDevice(withId: device.deviceId, onSuccess: { (vehicle:VLVehicle?, response:HTTPURLResponse?) in
            if let car = vehicle {
                self.latestVehicle = car
                self.setVehicleLabel(vehicle: self.latestVehicle)
                self.getBatteryStatus(vehicle: self.latestVehicle)
                self.getOdometer(vehicle: car)
            }
        }) { (error:Error?, response:HTTPURLResponse?, bodyString: String?) in
                print("error getting latest vehicle: \(bodyString)")
        }
    }
    
    //build out the string for vehicle label, in case there is not one
    func setVehicleLabel(vehicle:VLVehicle) {
        var vString = "unknown"
        
        if let year = vehicle.year{
            vString = year
        }
        if let make = vehicle.make{
            vString += " \(make)"
        }
        if let model = vehicle.model{
            vString += " \(model)"
        }
        
        self.latestVehicleLabel.text = vString
        
    }
    
    //battery status
    func getBatteryStatus(vehicle:VLVehicle){
        vinli.getCurrentBatteryStatus(withVehicleId: vehicle.vehicleId, onSuccess: { (status:VLBatteryStatus?, response:HTTPURLResponse?) in
            if let status = status {

                if status.status == .green {
                    self.batteryStatus = "green"
                    self.batteryStatusLabel.text = "Battery is healthy!"
                }
                if status.status == .yellow {
                    self.batteryStatus = "yellow"
                    self.batteryStatusLabel.text = "Battery may have issues."
                }
                if status.status == .red {
                    self.batteryStatus = "red"
                    self.batteryStatusLabel.text = "Battery is looks dead :("
                }
            }
        }) { (error: Error?, response: HTTPURLResponse?, bodyString: String?) in
                print("error getting battery status \(bodyString)")
        }
    }

    
    //fuel level
    func getFuelLevel(device:VLDevice){
        vinli.getSnapshotsForDevice(withId: device.deviceId, fields: "fuelLevelInput", limit: 1, until: nil, since: nil, sortDirection: nil, onSuccess: { (pager: VLSnapshotPager?, response: HTTPURLResponse?) in
            
            if let snap = pager?.snapshots[0]{
                
                let fuelSnap = snap as! VLSnapshot
                
                self.fuelLevel = fuelSnap.data["fuelLevelInput"] as? Double
                
                let fuelString = self.fuelLevel.description
                
                self.fuelLevelLabel.text = "Current Fuel Level \(fuelString) %"
            }
            
        }) { (error: Error?, response: HTTPURLResponse?, bodyString: String?) in
                print("error getting fuel level for the device \(bodyString)")
        }
    }
    
    //odometer
    func getOdometer(vehicle:VLVehicle) {
        vinli.getDistancesForVehicle(withId: vehicle.vehicleId, onSuccess: { (pager: VLDistancePager?, response: HTTPURLResponse?) in
            
            if let lastDistance = pager?.distances[0] {
                
                let distance = lastDistance as! VLDistance
                
                let distanceInMiles = Int(round(Double(distance.value.intValue) * 0.00062137))
                
                self.odometerLabel.text = "Odometer: \(distanceInMiles) Miles"
            }
            
        }) { (error: Error?, responst: HTTPURLResponse?, bodyString: String?) in
            print("error getting current odometer for vehicle: \(bodyString)")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //////////////////////////////////
    //MARK Navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let id = segue.identifier{
            if (id == "editOdometerSegue") {
                let newVc = segue.destination as! OdometerViewController
                
                if let vinli:VLService? = self.vinli {
                    newVc.vinli = vinli
                }
                if let device:VLDevice? = self.device {
                    newVc.device = device
                }
                if let vehicle:VLVehicle? = self.latestVehicle {
                    newVc.vehicle = vehicle
                }

            }
        }
    }

}
