//
//  DBAccessProvider.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 05/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit
import Firebase

typealias DBQueryHandler = (_ success : Bool ,_ message : String?) -> Void
typealias DBQueryInfoHandler = (_ success : Bool , _ infoDict : [String : Any]? , _ message : String?) -> Void

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
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).child(requestID!).updateChildValues([ RIDER_UID : uid , RIDER_LOCATION : [ LATITUDE : latitude , LONGITUDE : longitude ] ]) { (error, dbref) in
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
    
    
    
    func updateRidersLocation(requestID : String , latitude : Double , longitude : Double , isRequestAccepted : Bool) {
        
        var requestStatusChild : String
        if isRequestAccepted {
            requestStatusChild = ACCEPTED_REQUESTS
        }
        else{
            requestStatusChild = PENDING_REQUESTS
        }
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(requestStatusChild).child(requestID).child(RIDER_LOCATION).updateChildValues([ LATITUDE : latitude , LONGITUDE : longitude ])
        
    }
    
    func cancelUberCall(requestID : String , isRequestAccepted : Bool , completionHandler : DBQueryHandler?) {
        var requestStatusChild : String
        if isRequestAccepted {
            requestStatusChild = ACCEPTED_REQUESTS
        }
        else{
            requestStatusChild = PENDING_REQUESTS
        }
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(requestStatusChild).child(requestID).removeValue { (error, dbref) in
            if let error = error {
                completionHandler?(false, error.localizedDescription)
            }
            else{
                
                if let user = Auth.auth().currentUser {
                    self.FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(user.uid).removeValue(completionBlock: { (error, dbRef) in
                        if let error = error {
                            completionHandler?(false, error.localizedDescription)
                        }
                        else{
                            completionHandler?(true,nil)
                        }
                    })
                }
                else{
                    completionHandler?(false, "There is a problem with the user authentication. Please Logout to correct.")
                }
            }
        }
    }
    
    func observeCabRequestStatus(requestID : String , requestTypeName : String , completionHandler : DBQueryHandler?) {
        
        var handle : UInt = 0
        let ref = FirebaseDBURL.child(RIDE_REQUESTS).child(requestTypeName)
        
        handle = ref.observe(.childRemoved) { (snapShot) in
            if snapShot.exists() {
                if snapShot.key == requestID {
                    completionHandler?(true , nil)
                    ref.removeObserver(withHandle: handle)
                }
            }
        }
    }
    
    func getAcceptedQueryData(requestID : String , completionHandler : @escaping DBQueryInfoHandler) {
        FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                if let rideInfo = snapShot.value as? [String : Any] {
                    completionHandler(true,rideInfo,nil)
                }
            }
        }
    }
    
    
    func addDriverLocationObserver(requestID : String , updateHandler : @escaping DBQueryInfoHandler){
        
        var ref = FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).child(DRIVER_LOCATION)
        
        ref.observe(.childChanged) { (snapShot) in
            if snapShot.exists() {
                if let info = snapShot.value as? [String : Double] {
                    updateHandler(true, info, nil)
                }
            }
        }
        
        ref.observe(.childRemoved, with: { (snapShot) in
            ref.removeAllObservers()
        })
        
    }
}
