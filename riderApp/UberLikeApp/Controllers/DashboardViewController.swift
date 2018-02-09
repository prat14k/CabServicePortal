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
    
    private var riderAnnotation , driverAnnotation : MKPointAnnotation!
    
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
        
        locationManager.startUpdatingLocation()
        
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
//            locationManager.startUpdatingLocation()
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
    
    private func getRequestInfo(requestStatus : Bool){
        let requestStatusType = requestStatus ? ACCEPTED_REQUESTS : PENDING_REQUESTS
        
        DBAccessProvider.Instance.getRequestedRideQueryData(requestID: cabRequestID, requestStatusType: requestStatusType) { (success, infoDict, message) in
            
            if let requestInfo = infoDict {
                if let loc = requestInfo[RIDER_LOCATION] as? [String : Double] {
                    if self.riderLocation == nil {
                        if let latitude = loc[LATITUDE] , let longitude = loc[LONGITUDE] {
                            self.riderLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            self.setMapRegionAndAnnotation()
                        }
                    }
                }
                self.makeUserBooked(info: requestInfo)
            }
        }
    }
    
    private func userUnAvailabityInfo(_ info : [String : Any]?){
        if let info = info {
            cabRequestID = info[REQUEST_UID] as! String
            getRequestInfo(requestStatus: info[REQUEST_STATUS] as! Bool)
        }
        else{
            makeUserFree()
        }
    }
    
    private func addDriverAnnotation(){
        
        if driverAnnotation != nil {
            mapkit.removeAnnotation(driverAnnotation)
        }
        driverAnnotation = MKPointAnnotation()
        driverAnnotation.coordinate = driverLocation
        driverAnnotation.title = "Driver's Location"
        
        mapkit.addAnnotation(driverAnnotation)
    }
    
    private func addDriverLocationObserver(){
        
        DBAccessProvider.Instance.addDriverLocationObserver(requestID: cabRequestID) { (success, infoDict, message) in
            if success {
                if self.driverLocation == nil {
                    return
                }
                if let info = infoDict as? [String : Double] {
                    var latitude = self.driverLocation.latitude
                    var longitude = self.driverLocation.longitude
                    if let newLatitude = info[LATITUDE] {
                        latitude = newLatitude
                    }
                    if let newLongitude = info[LONGITUDE] {
                        longitude = newLongitude
                    }
                    self.driverLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.addDriverAnnotation()
                }
            }
        }
    }
    
    private func makeUserBooked(info : [String : Any] = [String : Any]()){
        isRideBooked = true
        
        if let driverid = info[DRIVER_UID] as? String{
            self.driverID = driverid
            if let driverLocInfo = info[DRIVER_LOCATION] as? [String : Double] {
                driverLocation = CLLocationCoordinate2D(latitude: driverLocInfo[LATITUDE]!, longitude: driverLocInfo[LONGITUDE]!)
                addDriverAnnotation()
                addDriverLocationObserver()
            }
            addRideRequestAcceptedStatusObserver()
        }
        else{
            addRideRequestStatusObserver()
        }
        
        cabActionButton.backgroundColor = UIColor.rgb(red: 15, green: 79, blue: 239, alpha: 1.0)
        cabActionButton.setTitle("Cancel Uber Ride Request", for: .normal)
    }
    
    func makeUserFree(){
        isRideBooked = false
        cabRequestID = nil
        driverID = nil
        driverLocation = nil
        requestIsBeingCancelled = false
        if driverAnnotation != nil {
            mapkit.removeAnnotation(driverAnnotation)
            driverAnnotation = nil
        }
        
        cabActionButton.backgroundColor = UIColor.rgb(red: 15, green: 79, blue: 59, alpha: 1.0)
        cabActionButton.setTitle("Call Uber Cab", for: .normal)
    }
    
    private func addRideRequestStatusObserver(){
        DBAccessProvider.Instance.observeCabRequestStatus(requestID: cabRequestID , requestTypeName: PENDING_REQUESTS) { (success, message) in
            if success {
                if !self.requestIsBeingCancelled {
                    self.fetchAcceptedRequestData()
                    AlertViewHelper.showAlertWithTitle("Your call for a cab has been accepted", message: "A Driver has accepted your request. You can see his position in the map.", presentingController: self)
                    DBAccessProvider.Instance.removeRiderRequestInfoData(requestType: PENDING_REQUESTS, requestID: self.cabRequestID)
                    DBAccessProvider.Instance.updateRequestStatusInAvailabilityStatusInfo(status: true)
                }
            }
        }
    }
    
    private func removeDriverDetails(){
        driverID = nil
        driverLocation = nil
        
        if driverAnnotation != nil {
            mapkit.removeAnnotation(driverAnnotation)
            driverAnnotation = nil
        }
        
        self.addRideRequestStatusObserver()
    }
    
    private func addRideRequestAcceptedStatusObserver(){
        DBAccessProvider.Instance.observeCabRequestStatus(requestID: cabRequestID, requestTypeName: ACCEPTED_REQUESTS) { (success, message) in
            if success {
                if !self.requestIsBeingCancelled {
                    self.removeDriverDetails()
                    AlertViewHelper.showAlertWithTitle("Your driver have cancelled the ride", message: "The driver have cancelled the acceptance for cab ride offer. We will share your request to other drivers now.", presentingController: self)
                    DBAccessProvider.Instance.removeRiderRequestInfoData(requestType: ACCEPTED_REQUESTS, requestID: self.cabRequestID)
                    DBAccessProvider.Instance.updateRequestStatusInAvailabilityStatusInfo(status: false)
                }
            }
        }
    }
    
    private func fetchAcceptedRequestData(){
        DBAccessProvider.Instance.getRequestedRideQueryData(requestID: cabRequestID, requestStatusType: ACCEPTED_REQUESTS, completionHandler: { (success, infoDict, message) in
            if success {
                if let infoDict = infoDict {
                    self.makeUserBooked(info: infoDict)
                    self.addRideRequestAcceptedStatusObserver()
                }
            }
        })
    }
    
    private func setMapRegionAndAnnotation(){
        if riderLocation == nil {
            return
        }
        
        let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapkit.setRegion(region, animated: true)
        
        if riderAnnotation != nil {
            mapkit.removeAnnotation(riderAnnotation)
        }
        
        riderAnnotation = MKPointAnnotation()
        riderAnnotation.coordinate = riderLocation
        riderAnnotation.title = "\(portalUserType) Locations"
        mapkit.addAnnotation(riderAnnotation)
        
        if isRideBooked {
            let isDriverBooked = (driverLocation != nil)
            DBAccessProvider.Instance.updateRidersLocation(requestID: cabRequestID, latitude: riderLocation.latitude, longitude: riderLocation.longitude, isRequestAccepted: isDriverBooked)
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
                    if self.driverID != nil {
                        DBAccessProvider.Instance.removeDriversAvailabilityStatus(driverID: self.driverID)
                    }
                    DropDownAlert.showMessage("The cab request has been cancelled successfully.", withTextColor: nil, backGroundColor: errorColor, position: .bottom)
                    DBAccessProvider.Instance.removeRiderRequestInfoData(requestType: (self.driverLocation != nil ? ACCEPTED_REQUESTS : PENDING_REQUESTS), requestID: self.cabRequestID)
                    DBAccessProvider.Instance.removeRiderBookingData()
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
                
                setMapRegionAndAnnotation()
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


