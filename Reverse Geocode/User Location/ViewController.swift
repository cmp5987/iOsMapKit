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
    @IBOutlet weak var addressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double =  10000
    var previousLocation: CLLocation?
    
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
             startTrackingUserLocation()
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
    func startTrackingUserLocation(){
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
         //mapView.showsUserLocation = true
    }
    
    //helper methods for mapView
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension ViewController: CLLocationManagerDelegate{
    // Comment this out so it doesn't update constantly
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

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //we have center of map, we are going to keep track of it and reverse geolocate and put it on a label
        //geocoders are rate limited for apps so you cannot keep recalling, you want to wait for a significant movement in the app
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        

        
        //when ever you define a variable that is outside a closure use weak self
        geoCoder.reverseGeocodeLocation(center) { [weak  self] (placemark,error) in
            //self is an optional so we are unwrapping it and guarding for it
            guard let self = self else {  return }
            
            //we can get an error for the closure
            if let _ = error {
                //ToDo:  Show alert informing the user
                return
            }
            
            //array of cl placemarks / we want to check that we  have one
            guard let placemark = placemark?.first  else{
                //ToDo:  Show alert informing the user
                return
            }
            
            //keep track of previous loction and check it is significant enough movement
            //initial previous location is nil
            //placemark contains all kinds of location properites like zipcode or street number
            let streetNumber  = placemark.subThoroughfare ?? ""
            let streetName =  placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
            
            
        }
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


