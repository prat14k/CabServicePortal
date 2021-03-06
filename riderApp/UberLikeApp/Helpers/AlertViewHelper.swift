//
//  AlertViewHelper.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 06/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit

class AlertViewHelper: NSObject {

    class func showAlertWithTitle(_ title : String , message : String , presentingController : UIViewController){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(okayAction)
        
        presentingController.present(alertController, animated: true, completion: nil)
    }
    
}
