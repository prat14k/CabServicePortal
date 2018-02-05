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
import Firebase
import SVProgressHUD

class DashboardViewController: UIViewController {

    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var mapkit: MKMapView!
    
    private var driverLocation : CLLocationCoordinate2D!
    
    private lazy var locationManager : CLLocationManager! = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.startUpdatingLocation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(unavailabilityNotification(_:)), name: NSNotification.Name(UNAVAILABILITY_ISSUE), object: nil)
        
        if let user = Auth.auth().currentUser {
            DBAccessProvider.Instance.checkIfUserAvailable(uid: user.uid)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        locationManager.stopUpdatingLocation()
    }
    
    @objc func unavailabilityNotification(_ notification : Notification){
        userUnAvailabityInfo(notification.userInfo as? [String : Any])
    }
    
    private func userUnAvailabityInfo(_ info : [String : Any]?){
        if let info = info {
            
        }
        else{
            print("available")
        }
    }
    
}

extension DashboardViewController {
    @IBAction func logoutAction(_ sender: UIButton) {
        SVProgressHUD.show(withStatus: "Logging Out")
        do {
            try Auth.auth().signOut()
            DropDownAlert.showMessage("Logged out Successfully", withTextColor: nil, backGroundColor: nil, position: .bottom)
            
            UserDefaults.standard.removeObject(forKey: USER_UID)
            
            self.navigationController?.popViewController(animated: true)
        }
        catch let error {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
        SVProgressHUD.dismiss()
    }
    
    @IBAction func driverRideAction(_ sender: UIButton) {
        
        
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
            }
        }
    }
    
}





















