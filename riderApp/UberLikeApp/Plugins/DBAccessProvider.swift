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
    
    
    func updateRequestStatusInAvailabilityStatusInfo(status : Bool){
        FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(AuthProvider.Instance.UID()).updateChildValues([REQUEST_STATUS : status])
    }
    
    
    func checkIfUserAvailable() {
        
        FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(AuthProvider.Instance.UID()).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                
                if let info = snapShot.value as? [String : Any]{
                    if let requestID = info[REQUEST_UID] as? String , let status = info[REQUEST_STATUS] as? Bool {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil, userInfo: [REQUEST_UID  : requestID , REQUEST_STATUS : status])
                        return
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil, userInfo: nil)
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
                self.FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).updateChildValues([ uid : [ REQUEST_UID : requestID! , REQUEST_STATUS : false ] ], withCompletionBlock: { (error, dbRef) in
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
    
    func getRequestedRideQueryData(requestID : String , requestStatusType : String , completionHandler : @escaping DBQueryInfoHandler) {
        FirebaseDBURL.child(RIDE_REQUESTS).child(requestStatusType).child(requestID).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                if let rideInfo = snapShot.value as? [String : Any] {
                    completionHandler(true,rideInfo,nil)
                }
            }
        }
    }
    
    func removeRiderBookingData(){
        FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(AuthProvider.Instance.UID()).removeValue()
    }
    
    func removeRiderRequestInfoData(requestType : String , requestID : String){
        FirebaseDBURL.child(RIDE_REQUESTS).child(requestType).child(requestID).removeValue()
    }
    
    func addDriverLocationObserver(requestID : String , updateHandler : @escaping DBQueryInfoHandler){
        
        let ref = FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).child(DRIVER_LOCATION)
        
        ref.observe(.childChanged) { (snapShot) in
            if snapShot.exists() {
                if let info = snapShot.value as? Double {
                    updateHandler(true, [ snapShot.key : info], nil)
                }
            }
        }
        
        ref.observe(.childRemoved, with: { (snapShot) in
            ref.removeAllObservers()
        })
        
    }
}
