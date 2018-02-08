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
    
    @IBOutlet weak var cabRideActionButton: UIButton!
    
    private var driverLocation : CLLocationCoordinate2D!
    
    private var riderLocation : CLLocationCoordinate2D!
    private var isDriverBooked : Bool!
    private var riderID : String!
    private var cabRequestID : String!
    
    private var cabRideisBeingCancelled = false
    
    private lazy var locationManager : CLLocationManager! = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 500
        locationManager.requestWhenInUseAuthorization()
        
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cabRideActionButton.isHidden = true
        locationManager.startUpdatingLocation()
        
        isDriverBooked = false
        NotificationCenter.default.addObserver(self, selector: #selector(unavailabilityNotification(_:)), name: NSNotification.Name(UNAVAILABILITY_ISSUE), object: nil)
        SVProgressHUD.show(withStatus: "Checking User status")
        DBAccessProvider.Instance.checkIfUserAvailable()
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
            makeUserBooked(infoDict: info)
        }
        else{
            makeUserFree()
            addObserverForPendingReq()
        }
    }
    
    func makeUserBooked(infoDict : [String : Any]){
        print("BOOKED : ")
        print(infoDict)
        
        isDriverBooked = true
        cabRideActionButton.isHidden = false
        
        cabRequestID = infoDict[REQUEST_UID] as! String
        riderID = infoDict[RIDER_UID] as! String
        
        if let coordinates = infoDict[RIDER_LOCATION] as? [String : Double] {
            riderLocation = CLLocationCoordinate2D(latitude: coordinates[LATITUDE]!, longitude: coordinates[LONGITUDE]!)
        }
        
        addRequestStatusObserver(requestID : cabRequestID)
        
        addRiderLocationUpdateObserver(requestID : cabRequestID)
    }
    func makeUserFree(){
        cabRideActionButton.isHidden = true
        isDriverBooked = false
        cabRequestID = nil
        riderID = nil
        riderLocation = nil
    }
    
    
    private func addRequestStatusObserver(requestID : String) {
        DBAccessProvider.Instance.addObserverForRequestCancelling(requestID: requestID) { (success, message) in
            if success {
                if !self.cabRideisBeingCancelled {
                    if let msg = message {
                        AlertViewHelper.showAlertWithTitle("Cab Ride has been Cancelled", message: msg, presentingController: self, startPendingRequestsAtCompletion: true)
                        self.makeUserFree()
                    }
                }
            }
        }
    }
    
    private func addRiderLocationUpdateObserver(requestID : String) {
//        DBAccessProvider.Instance.addObserverForRidersLocationUpdate(requestID: requestID, completionHandler: <#T##DBQueryHandler?##DBQueryHandler?##(Bool, String?) -> Void#>)
    }
    
    private func addObserverForPendingReq(){
        if driverLocation != nil {
            DBAccessProvider.Instance.checkIfAnyPendingCabRequests(newRequestHandler: { (infoDict) in
                let positiveAction = UIAlertAction(title: "Accept", style: .default, handler: { (action) in
                    SVProgressHUD.show(withStatus: "Accepting the Cab Request")
                    if self.driverLocation == nil {
                        AlertViewHelper.showAlertWithTitle("Problem with Accepting request", message: "We cannot access your location which is neccessary for accepting the ride request", presentingController: self)
                        return
                    }
                    DBAccessProvider.Instance.acceptCabRideRequest(infoDict: infoDict, driverLocation : [LATITUDE : self.driverLocation.latitude , LONGITUDE : self.driverLocation.longitude] , withCompletionHandler: { (success, message) in
                        if success {
                            self.makeUserBooked(infoDict: infoDict)
                            DropDownAlert.showMessage("Request Accepted Successfully. You can see the rider's location in the map.", withTextColor: nil, backGroundColor: successColor, position: .bottom)
                        }
                        else{
                            if let msg = message {
                                AlertViewHelper.showAlertWithTitle("Problem with Accepting request", message: msg, presentingController: self)
                            }
                        }
                        SVProgressHUD.dismiss()
                    })
                })
                
                if let coordinates = infoDict[RIDER_LOCATION] as? [String : Double] {
                    let latitude = coordinates[LATITUDE]!
                    let longitude = coordinates[LONGITUDE]!
                    AlertViewHelper.showAlertWithTitle("Accept Ride Request ?", message: "A cab request has been recieved from coordinates(\(LATITUDE):\(latitude) , \(LONGITUDE):\(longitude)). Do you accept it ?", positiveAlertAction: positiveAction, presentingController: self , shouldBePresentedNow: !self.isDriverBooked)
                }
            
            })
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
                AlertViewHelper.Instance.clearAnyPendingAlerts()
                self.navigationController?.popViewController(animated: true)
                
                SVProgressHUD.dismiss()
            }
        }
        
    }
    
    @IBAction func driverRideAction(_ sender: UIButton!) {
        
        if isDriverBooked {
            
            cabRideisBeingCancelled = true
            let ridersInfo = [RIDER_UID : riderID , RIDER_LOCATION : [LATITUDE : riderLocation.latitude , LONGITUDE : riderLocation.longitude]] as [String : Any]
            DBAccessProvider.Instance.cancelRide(requestID: cabRequestID, ridersInfo: ridersInfo, completionHandler: { (success, message) in
                if success {
                    DropDownAlert.showMessage("The ride has been cancelled", withTextColor: nil, backGroundColor: errorColor, position: .bottom)
                    self.makeUserFree()
                    AlertViewHelper.Instance.startPendingRequestsAlertsAgain(presentingController: self)
                }
            })
            
        }
        
    }
}


extension DashboardViewController : MKMapViewDelegate , CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            
            if let curLoc = locations.first {
                
                driverLocation = CLLocationCoordinate2D(latitude: curLoc.coordinate.latitude, longitude: curLoc.coordinate.longitude)
                
                let region = MKCoordinateRegion(center: driverLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                mapkit.setRegion(region, animated: true)
                
                mapkit.removeAnnotations(mapkit.annotations)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = driverLocation
                annotation.title = "\(portalUserType) Locations"
                mapkit.addAnnotation(annotation)
                
                if isDriverBooked {
                    DBAccessProvider.Instance.updateUsersCurrentLocation(requestID: cabRequestID, latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        driverLocation = nil
        mapkit.removeAnnotations(mapkit.annotations)
        if status == .denied || status == .restricted {
            AlertViewHelper.showAlertWithTitle("Location Services not available", message: "Unable to access the location services. Please provide access in order to use the feature better.", presentingController: self)
        }
        else if status != .notDetermined {
            locationManager.startUpdatingLocation()
        }
    }
    
}





















