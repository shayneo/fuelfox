//
//  SettingsViewController.swift
//  FuelFox
//
//  Created by Shayne O'Sullivan on 9/22/16.
//  Copyright © 2016 Shayne O'Sullivan. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    let defaults = UserDefaults.standard


    @IBOutlet weak var highInput: UITextField!
    @IBOutlet weak var lowInput: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check user defaults for high and low threshold settings
        
        if defaults.float(forKey: "highThreshold").description != nil {
            let high = defaults.integer(forKey: "highThreshold")
            highInput.text = String(high)
            
        } else {
            highInput.text = "75"
        }
        
        if defaults.float(forKey: "lowThreshold").description != nil {
            let low = defaults.integer(forKey: "lowThreshold")
            
            lowInput.text = String(low)
            
        } else {
            highInput.text = "15"
        }
    
        
    }
    
    @IBAction func saved(_ sender: AnyObject) {
        defaults.set(Int(highInput.text!), forKey: "highThreshold")
        defaults.set(Int(lowInput.text!), forKey: "lowThreshold")
        defaults.synchronize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
