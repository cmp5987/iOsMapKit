//
//  ViewController.swift
//  User Location
//
//  Created by catie on 4/19/20.
//  Copyright © 2020 cmp5987. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double =  10000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
    }
    
    func setupLocationManager(){
         locationManager.delegate = self
         locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation(){
        //location is optional so we need to unwrap and initialize region with center
        if let location = locationManager.location?.coordinate {
            //how zoomed in do we want to be
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
     
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled() {
             //setup location manager
            setupLocationManager()
            checkLocationAuthorization()
             
        }else{
            print("Error in checking location services")
             //error handling here
             //Show alert letting the user know that they have to turn this on
        }
    }


    func checkLocationAuthorization(){
        print("In checkLocationAuthorization")
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
             //Do Map Stuff
            print("In .authorizedWhenInUse")
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
             //mapView.showsUserLocation = true
            break
        case .denied:
             //user hit not allow for permissions
             //they must manually go to general settings and turn it on
            break
        case .notDetermined:
             //they haven't picked allow or not allow
             //request permission
            locationManager.requestWhenInUseAuthorization()
            mapView.showsUserLocation = true

        case .restricted:
             //User cannot change app status due to parental controls
             //show alert letting them know what is goin on
            break
        case .authorizedAlways:
             //we are not asking for always
            break
        
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //guard is a line in the  sand --- nothing below happens if conditional isn't met
        guard let  location = locations.last else{ return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
}
    
    /* This is alternative version
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        //mapView.showsUserLocation = true
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Do any additional setup after loading the view.
        //checkLocationServices()
        if CLLocationManager.locationServicesEnabled(){
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer { currentLocation = locations.last }
        
        if currentLocation == nil {
            //Zoom to user location
            if let userLocation = locations.last {
                let viewRegion  = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
                mapView.setRegion(viewRegion, animated: false)
            }
        }
    }
    */


