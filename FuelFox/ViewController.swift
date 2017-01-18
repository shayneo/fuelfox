//
//  ViewController.swift
//  FuelFox
//
//  Created by Shayne O'Sullivan on 9/2/16.
//  Copyright © 2016 Shayne O'Sullivan. All rights reserved.
//

import UIKit
import VinliNet

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var button: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let reuseIdentifier = "tableViewCell"
    let defaults = UserDefaults.standard
    
    var VinliService:VLService!
    var user:VLUser!
    var deviceList = [VLDevice]()
    var latestVehicleMap = [String:VLVehicle]()
    var vehicleList = [VLVehicle]()
    var deviceNames = [String]()
    var fuelMap = [String:Float]()
    var lastFuelSnap:VLSnapshot!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if VLSessionManager.loggedIn() {
            VinliService = VLService.init(session: VLSessionManager.currentSession())
            button.title = "Sign Out"
            getDevices()
        } else {
            button.title = "Sign In"
        }
        
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        self.tableView.addSubview(self.refreshControl)
    }
    
    //login
    @IBAction func LoginTapped(_ sender: AnyObject) {
        
        if VLSessionManager.loggedIn() == false {
            VLSessionManager.login(withClientId: "XXXXXXXX", redirectUri: "https://li.my.vin", completion: {VLSession, error in
                
                if error != nil {
                    print("There was an error logging into Vinli")
                } else {
                    print("Successfully logged in!")
                    self.button.title = "Sign Out"
                    self.VinliService = VLService.init(session: VLSessionManager.currentSession())
                    self.getDevices()
                }
                }, onCancel: {
                    print("login cancelled")
            })

        } else {
            logOut()
        }
        
        
    }
    
    //logout
    func logOut() {
        clearDefaults()
        VLSessionManager.logOut()
        self.button.title = "Sign In"
        deviceList.removeAll()
        tableView.reloadData()
    }
    
    //get devices for a logged in user
    func getDevices() {
        
        VinliService.getDevicesOnSuccess({(devicePager: VLDevicePager?, response: HTTPURLResponse?) in
//            print("got dem devices")
//            print(devicePager?.devices)
            
            self.tableView.reloadData()
            
            for device in (devicePager?.devices)!{
                if let d = device as? VLDevice{
                    self.deviceList.append(d)
                    self.deviceNames.append(d.name)
                    self.getFuel(device: d)
                }
            }
            
            }, onFailure: { (error: Error?, response: HTTPURLResponse?, bodyString: String?) in
                print("error fetching devices")
        })

    }
    
    // get a snapshot for a device
    
    func getFuel(device: VLDevice) {
        self.tableView.reloadData()
        
        
            VinliService.getSnapshotsForDevice(withId: device.deviceId, fields: "fuelLevelInput", onSuccess: {(snapPager: VLSnapshotPager?, response: HTTPURLResponse?) in
                
                if let snap = snapPager?.snapshots[0]{
                    
                    let fuelSnap = snap as! VLSnapshot
                    
                    self.fuelMap[device.name] = fuelSnap.data["fuelLevelInput"] as? Float
                    //print("fuelz gotten")
                    
                    
                }
                self.tableView.reloadData()
                
                }, onFailure: { (error: Error?, response: HTTPURLResponse?, bodyString: String?) -> Void in
                    print("error fetching devices: \(bodyString)")
                })

        }

    //get latest vehicle for a device
    
    func fetchLatestVehicles() {
        for i in 0..<deviceList.count {
            let device = deviceList[i]
            
            
            VinliService.getLatestVehicleForDevice(withId: device.deviceId, onSuccess: { (vehicle: VLVehicle?, response: HTTPURLResponse?) -> Void in
                if vehicle != nil {
                    self.latestVehicleMap[device.deviceId] = vehicle
                    self.vehicleList.append(vehicle!)
                }
                
                }, onFailure: {(error: Error?, response: HTTPURLResponse?, bodyString: String?) -> Void in
                                    print("Error getting latest vehicle for device \(device.deviceId): \(bodyString)")
            })
        }
        
    }
    
    //tableview
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MyTableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MyTableViewCell
        
        let device = deviceList[indexPath.row].name
        let level = fuelMap[deviceList[indexPath.row].name]
        
        if let fuel = level {
            
            cell.cellLabel.text? = "\(device!)"
            cell.fuelLevelLabel.text? = "\(fuel) %"
            
            let highSetting = defaults.float(forKey: "highThreshold")
            let lowSetting = defaults.float(forKey: "lowThreshold")
            
            if fuel >= highSetting {
                cell.fuelLevelLabel.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            } else {
                if fuel >= lowSetting && fuel < highSetting {
                    cell.fuelLevelLabel.backgroundColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
                } else {
                    cell.fuelLevelLabel.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                }
                
            }
            
        }
        
        return cell
    }
    
    //table refresh
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        
        deviceList.removeAll()
        getDevices()
        
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    //clear userdefaults on logout
    func clearDefaults(){
        for i in 0..<vehicleList.count {
            let vehicle = vehicleList[i]
            
            if defaults.string(forKey: "\(vehicle.vehicleId)lastOdometerId") != nil {
                defaults.setValue(nil, forKey: "\(vehicle.vehicleId)lastOdometerId")
            }
        }
    }
    
    //prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let id = segue.identifier{
            if (id == "showDeviceDetailSegue") {
                let newVc = segue.destination as! DeviceDetailViewController
                
                var indexPath = self.tableView.indexPath(for: sender as! UITableViewCell)
                
                if let device:VLDevice? = self.deviceList[(indexPath?.row)!] {
                    newVc.device = device
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

