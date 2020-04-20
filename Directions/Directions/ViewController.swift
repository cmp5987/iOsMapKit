//
//  ViewController.swift
//  Directions
//
//  Created by catie on 4/17/20.
//  Copyright © 2020 cmp5987. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var textFieldAddress: UITextField!
    @IBOutlet weak var getDirectionsButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func getDirectionsTapped(_ sender: Any) {
        getAddress()
    }
    
    func getAddress(){
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(textFieldAddress.text!) { (placemarks, error) in
            guard let placemarks = placemarks, let location = placemarks.first?.location
                else{
                    print("No Location Found")
                    return
            }
            print(location)
        }
    }
    
    
}

