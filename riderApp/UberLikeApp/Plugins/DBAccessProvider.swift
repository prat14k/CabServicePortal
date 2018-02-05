//
//  DBAccessProvider.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 05/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit
import Firebase

class DBAccessProvider: NSObject {

    private static let _instance = DBAccessProvider()
    
    static let Instance : DBAccessProvider = {
        return _instance
    }()
    
    var FirebaseDBURL: DatabaseReference {
        return Database.database().reference()
    }

}

extension DBAccessProvider {
    
    func saveUser(email : String , password : String , uid : String) {
        
        let data = [EMAIL : email , PASSWORD : password]
        FirebaseDBURL.child(portalUserType.lowercased()).child(uid).updateChildValues(data)
        
    }
    
    func checkIfUserAvailable(uid : String) {
        
        FirebaseDBURL.child("working\(portalUserType)").child(uid).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil, userInfo: [REQUEST_UID  : snapShot.value as! String])
            }
        }
        
    }
    
}
