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
            DropDownAlert.showMessage("Logged out Successfully", withTextColor: nil, backGroundColor: nil, position: .bottom)
            self.navigationController?.popViewController(animated: true)
        }
        catch let error {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
        SVProgressHUD.dismiss()
    }
    
    @IBAction func driverRideAction(_ sender: UIButton) {
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }
}
