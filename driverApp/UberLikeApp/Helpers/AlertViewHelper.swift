//
//  AlertViewHelper.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 06/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit

class AlertViewHelper: NSObject {

    private static let _instance = AlertViewHelper()
    static let Instance : AlertViewHelper = {
        return AlertViewHelper._instance
    }()
    
    private var pendingAlerts = [UIAlertController]()
    
    class func showAlertWithTitle(_ title : String , message : String , presentingController : UIViewController , startPendingRequestsAtCompletion : Bool = false){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(okayAction)

        presentingController.present(alertController, animated: true) {
            if startPendingRequestsAtCompletion {
                AlertViewHelper.Instance.startPendingRequestsAlertsAgain(presentingController: presentingController)
            }
        }
//        presentingController.present(alertController, animated: true, completion: nil)
    }
    
    class func showAlertWithTitle(_ title : String , message : String , positiveAlertAction : UIAlertAction , presentingController : UIViewController , shouldBePresentedNow presentAlertNow : Bool = true){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let negativeAction = UIAlertAction(title: "NO", style: .cancel) { (action) in
            if AlertViewHelper.Instance.pendingAlerts.count > 0 {
                if let alertController = AlertViewHelper.Instance.pendingAlerts.first {
                    AlertViewHelper.Instance.pendingAlerts.remove(at: 0)
                    presentingController.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        alertController.addAction(negativeAction)
        alertController.addAction(positiveAlertAction)
        
        if presentingController.presentedViewController == nil && presentAlertNow {
            presentingController.present(alertController, animated: true, completion: nil)
        }
        else{
            AlertViewHelper.Instance.pendingAlerts.append(alertController)
        }
    }


    func startPendingRequestsAlertsAgain(presentingController : UIViewController){
        if pendingAlerts.count > 0 {
            if let alertController = pendingAlerts.first {
                AlertViewHelper.Instance.pendingAlerts.remove(at: 0)
                presentingController.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func clearAnyPendingAlerts(){
        pendingAlerts.removeAll()
    }
}
