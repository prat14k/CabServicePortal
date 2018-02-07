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

    typealias DBQueryHandler = (_ success : Bool ,_ message : String?) -> Void
    
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
    
    
    func checkIfUserAvailable() {
        
        var uid : String
        if let user = Auth.auth().currentUser {
            uid = user.uid
        }
        else{
            return
        }
        
        FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(uid).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil, userInfo: [REQUEST_UID  : snapShot.value as! String])
            }
        }
        
    }
    
    
    func callForACab(latitude : Double , longitude : Double , requestID : String? , completionHandler : DBQueryHandler?) {
        var requestID = requestID
        if requestID == nil {
            requestID = NSUUID().uuidString
        }
        
        var uid = ""
        if let user = Auth.auth().currentUser {
            uid = user.uid
        }
        else{
            completionHandler?(false,"Problem with user authentication. Please logout and login again !!!")
            return
        }
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).child(requestID!).updateChildValues([ RIDER_UID : uid , LATITUDE : latitude , LONGITUDE : longitude ]) { (error, dbref) in
            if let error = error {
                completionHandler?(false,error.localizedDescription)
            }
            else{
                self.FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).updateChildValues([ uid : requestID! ], withCompletionBlock: { (error, dbRef) in
                    if let error = error {
                        completionHandler?(false,error.localizedDescription)
                    }
                    else{
                        completionHandler?(true,requestID!)
                    }
                })
            }
        }
    }
    
    
    func observeCabRequestStatus(requestID : String , completionHandler : DBQueryHandler?) {
        
        var handle : UInt = 0
        let ref = FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS)
        
        handle = ref.observe(.childRemoved) { (snapShot) in
            if snapShot.exists() {
                if snapShot.key == requestID {
                    completionHandler?(true , nil)
                    ref.removeObserver(withHandle: handle)
                }
            }
        }
        
    }
}
