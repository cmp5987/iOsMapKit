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
    @IBOutlet weak var getDirectionsButton: UIButton!
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double =  10000
    var previousLocation: CLLocation?
    
    let geoCoder = CLGeocoder()
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
    }
    
    @IBAction func getDirectionsTapped(_ sender: Any) {
        getDirections()
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
    
    func resetMapView(withNew directions: MKDirections){
        
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        //$ would multiply
        let _ = directionsArray.map  {$0.cancel()}
        //after calling .cancel we should remove them from the array
    }

    func getDirections(){
        guard let location = locationManager.location?.coordinate else {
            //inform user we don't have their current locaiton
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response,error) in
            guard let response = response else { return }
            //ToDo: Show response not avaliable in an alert
            
            for route in response.routes {
                let steps = route.steps
                self.mapView.addOverlay(route.polyline)
                //fits the route in the screen so it will zoom out to show the full map
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    //request needs a source and a destination
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startingLocation            = MKPlacemark(coordinate: coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true
        
        return request
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
        
        geoCoder.cancelGeocode()
        
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
    }//end of regionDidChange
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
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


