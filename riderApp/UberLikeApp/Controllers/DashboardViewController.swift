//
//  DashboardViewController.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 02/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SVProgressHUD

class DashboardViewController: UIViewController {

    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var mapkit: MKMapView!
    @IBOutlet weak var cabActionButton: UIButton!
    
    private var riderLocation : CLLocationCoordinate2D!
    
    private var driverLocation : CLLocationCoordinate2D!
    private var isRideBooked : Bool!
    private var driverID : String!
    private var cabRequestID : String!
    
    private var requestIsBeingCancelled = false
    
    private lazy var locationManager : CLLocationManager! = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 30
        locationManager.requestWhenInUseAuthorization()
        
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationAuthorizationStatus()
        
        isRideBooked = false
        NotificationCenter.default.addObserver(self, selector: #selector(unavailabilityNotification(_:)), name: NSNotification.Name(UNAVAILABILITY_ISSUE), object: nil)
        
        SVProgressHUD.show(withStatus: "Checking user status")
        DBAccessProvider.Instance.checkIfUserAvailable()
    
    }
    
    private func checkLocationAuthorizationStatus(){
//        let code = CLLocationManager.authorizationStatus()
//        if code == .notDetermined {
//            if Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil {
//                locationManager.requestAlwaysAuthorization()
//            }
//            else if code == .restricted || code == .denied {
//                print("Cannot be loaded")
//            }
//        }
//        else{
            locationManager.startUpdatingLocation()
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil)
        locationManager.stopUpdatingLocation()
    }
    
    @objc func unavailabilityNotification(_ notification : Notification){
        SVProgressHUD.dismiss()
        userUnAvailabityInfo(notification.userInfo as? [String : Any])
    }
    
    private func userUnAvailabityInfo(_ info : [String : Any]?){
        if let info = info {
            cabRequestID = info[REQUEST_UID] as! String
            makeUserBooked()
        }
        else{
            makeUserFree()
        }
    }
    
    func makeUserBooked(){
        isRideBooked = true
        cabActionButton.backgroundColor = UIColor.rgb(red: 15, green: 79, blue: 239, alpha: 1.0)
        cabActionButton.setTitle("Cancel Uber Ride Request", for: .normal)
    }
    func makeUserFree(){
        isRideBooked = false
        cabRequestID = nil
        driverID = nil
        riderLocation = nil
        requestIsBeingCancelled = false
        cabActionButton.backgroundColor = UIColor.rgb(red: 15, green: 79, blue: 59, alpha: 1.0)
        cabActionButton.setTitle("Call Uber Cab", for: .normal)
    }
    
    private func addRideRequestStatusObserver(){
        DBAccessProvider.Instance.observeCabRequestStatus(requestID: cabRequestID) { (success, message) in
            if success {
                if !self.requestIsBeingCancelled {
                    AlertViewHelper.showAlertWithTitle("Your call for a cab has been accepted", message: "A Driver has accepted your request. You can see his position in the map.", presentingController: self)
                }
            }
        }
    }
    
}

extension DashboardViewController {
    
    @IBAction func logoutAction(_ sender: UIButton) {
        SVProgressHUD.show(withStatus: "Logging Out")
        
        AuthProvider.Instance.logoutUser { (msg) in
            if let message = msg {
                //Unsuccessful logout
                SVProgressHUD.showError(withStatus: message)
            }
            else{
                // Successful Logout
                DropDownAlert.showMessage("Logged out Successfully", withTextColor: nil, backGroundColor: nil, position: .top)
                UserDefaults.standard.removeObject(forKey: USER_UID)
                self.navigationController?.popViewController(animated: true)
                
                SVProgressHUD.dismiss()
            }
        }
        
    }
    
    @IBAction func riderRideAction(_ sender: UIButton) {
        
        if isRideBooked {
            requestIsBeingCancelled = true
            SVProgressHUD.show(withStatus: "Cancelling the Ride")
            DBAccessProvider.Instance.cancelUberCall(requestID: cabRequestID, isRequestAccepted: (driverLocation != nil), completionHandler: { (success, message) in
                if success {
                    DropDownAlert.showMessage("The cab request has been cancelled successfully.", withTextColor: nil, backGroundColor: errorColor, position: .bottom)
                    self.makeUserFree()
                }
                else{
                    if let msg = message {
                        AlertViewHelper.showAlertWithTitle("Problem with Cancelling Cab", message: msg, presentingController: self)
                        self.requestIsBeingCancelled = false
                    }
                }
                SVProgressHUD.dismiss()
            })
        }
        else{
            if riderLocation != nil {
                SVProgressHUD.show(withStatus: "Sending your requests to cab drivers")
                DBAccessProvider.Instance.callForACab(latitude: riderLocation.latitude, longitude: riderLocation.longitude, requestID: cabRequestID, completionHandler: { (success,message) in
                    
                    if success {
                        if message != nil {
                            DropDownAlert.showMessage("Your request for a cab is registered successfully. We will notify you as soon as someone accepts.", withTextColor: nil, backGroundColor: UIColor.rgb(red: 0, green: 200, blue: 70, alpha: 1.0), position: .bottom)
                            self.isRideBooked = true
                            self.cabRequestID = message!
                            if self.cabRequestID != nil {
                                self.makeUserBooked()
                                self.addRideRequestStatusObserver()
                            }
                        }
                    }
                    else{
                        if let msg = message {
                            AlertViewHelper.showAlertWithTitle("Problem to call a Cab", message: msg, presentingController: self)
                        }
                    }
                    
                    SVProgressHUD.dismiss()
                })
            }
        }
    }
}


extension DashboardViewController : MKMapViewDelegate , CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            
            if let curLoc = locations.first {
                
                riderLocation = CLLocationCoordinate2D(latitude: curLoc.coordinate.latitude, longitude: curLoc.coordinate.longitude)
                
                let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                mapkit.setRegion(region, animated: true)
                
                mapkit.removeAnnotations(mapkit.annotations)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = riderLocation
                annotation.title = "\(portalUserType) Locations"
                mapkit.addAnnotation(annotation)
                
                if isRideBooked {
                    let isDriverBooked = (driverLocation != nil)
                    DBAccessProvider.Instance.updateRidersLocation(requestID: cabRequestID, latitude: riderLocation.latitude, longitude: riderLocation.longitude, isRequestAccepted: isDriverBooked)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        riderLocation = nil
        mapkit.removeAnnotations(mapkit.annotations)
        if status == .denied || status == .restricted {
            AlertViewHelper.showAlertWithTitle("Location Services not available", message: "Unable to access the location services. Please provide access in order to use the feature better.", presentingController: self)
        }
        else {
            locationManager.startUpdatingLocation()
        }
    }
}


