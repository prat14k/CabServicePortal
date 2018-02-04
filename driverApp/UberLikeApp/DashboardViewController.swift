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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        SVProgressHUD.show(withStatus: "Logging Out")
        do {
            try Auth.auth().signOut()
        }
        catch let error {
            
        }
        
    }
    
    @IBAction func driverRideAction(_ sender: UIButton) {
        
        
    }
}
