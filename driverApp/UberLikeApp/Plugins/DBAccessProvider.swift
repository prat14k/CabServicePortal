//
//  DBAccessProvider.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 05/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit
import Firebase

protocol RideRequestAcceptanceProtocol : NSObjectProtocol {
    
    func rideReqAccepted(requestID : String , rideLatitude : Double , rideLongitude : Double , riderUID : String)
    
}


typealias DBQueryHandler = (_ success : Bool , _ message : String?) -> Void
typealias RideAlertHandler = (_ infoDict : [String : Any]) -> Void

class DBAccessProvider: NSObject {

    weak var delegate : RideRequestAcceptanceProtocol?
    
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
        
        FirebaseDBURL.child("\(BOOKED_PEOPLE)").child("\(portalUserType.lowercased())").child(uid).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil, userInfo: [REQUEST_UID  : snapShot.value as! String])
            }
            else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UNAVAILABILITY_ISSUE), object: nil, userInfo: nil)
            }
        }
        
    }
    
    func checkIfAnyPendingCabRequests(newRequestHandler : @escaping RideAlertHandler){
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).observe(.childAdded) { (pendingReq) in
            
            if pendingReq.exists() {
                
                let requestID = pendingReq.key
                
                if let requestInfo = pendingReq.value as? [String : Any] {
                    
                    if let riderID = requestInfo[RIDER_UID] as? String {
                        if let coordinates = requestInfo[RIDER_LOCATION] as? [String : Double] {
                            newRequestHandler([ REQUEST_UID : requestID , RIDER_UID : riderID , RIDER_LOCATION : coordinates ])
                        }
                    }
                }
                
            }
            
        }
    }
    
    func acceptCabRideRequest(infoDict : [String : Any] , driverLocation : [String : Any]  ,withCompletionHandler completionHandler : DBQueryHandler? = nil) -> Void {
        
        if let requestID = infoDict[REQUEST_UID] as? String {
            
            var uid : String
            if let user = Auth.auth().currentUser {
                uid = user.uid
            }
            else{
                return
            }
            
            let acceptedReqData = [ DRIVER_UID : uid , RIDER_UID : infoDict[RIDER_UID]! , RIDER_LOCATION : infoDict[RIDER_LOCATION]! , DRIVER_LOCATION : driverLocation ] as [String : Any]
            
            FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).updateChildValues(acceptedReqData, withCompletionBlock: { (error, dbRef) in
                if let error = error {
                    completionHandler?(false,error.localizedDescription)
                }
                else{
                    self.FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).updateChildValues([uid : requestID], withCompletionBlock: { (error, dbRef) in
                        if let error = error {
                            completionHandler?(false,error.localizedDescription)
                            print("Error saving user status : \(error.localizedDescription)")
                        }
                        else{
                            completionHandler?(true , nil)
                        }
                    })
                    
                    self.FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).child(requestID).removeValue(completionBlock: { (error, dbRef) in
                        if let error = error {
//                            completionHandler?(false,error.localizedDescription)
                            print("Error deleting Pending Req : \(error.localizedDescription)")
                        }
                    })
                }
            })
        
        }
        
    }
    
    func addObserverForRequestCancelling(requestID : String , completionHandler : DBQueryHandler?){
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).observeSingleEvent(of: .childRemoved) { (snapShot) in
            if snapShot.exists() {
                completionHandler?(true,"The rider has cancelled the cab request.")
            }
            else {
                print("snapshot not existing")
                print(snapShot)
            }
        }
        
    }
    
    func addObserverForRidersLocationUpdate(requestID : String , completionHandler : DBQueryHandler?){
        
    }
    
    func cancelRide(requestID : String , ridersInfo : [String : Any], completionHandler : DBQueryHandler?){
        
        self.FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(AuthProvider.Instance.getUID()).removeValue { (error, dbRef) in
            
            if let error = error {
                completionHandler?(false, error.localizedDescription)
            }
            else{
                self.FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).removeValue { (error, dbref) in
                    if let error = error {
                        completionHandler?(false,error.localizedDescription)
                    }
                    else{
                        self.FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).child(requestID).updateChildValues(ridersInfo, withCompletionBlock: { (error, dbRef) in
                            if let error = error {
                                completionHandler?(false, error.localizedDescription)
                            }
                            else{
                                completionHandler?(true,"Cancelled Successfully")
                            }
                        })
                    }
                }
            }
            
        }
    }
    
    func updateUsersCurrentLocation(requestID : String , latitude : Double , longitude : Double){
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).child(DRIVER_LOCATION).updateChildValues([LATITUDE : latitude , LONGITUDE : longitude])
        
    }
    
    
    func removeOtherInnecessaryAcceptanceData(requestID : String){
        FirebaseDBURL.child(RIDE_REQUESTS).child(ACCEPTED_REQUESTS).child(requestID).removeValue()
        FirebaseDBURL.child(BOOKED_PEOPLE).child(portalUserType.lowercased()).child(AuthProvider.Instance.getUID()).removeValue()
    }
    
}
