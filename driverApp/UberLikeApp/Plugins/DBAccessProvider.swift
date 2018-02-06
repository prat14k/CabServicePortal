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

class DBAccessProvider: NSObject {

    weak var delegate : RideRequestAcceptanceProtocol?
    
    typealias DBQueryHandler = (_ message : String?) -> Void
    typealias RideAlertHandler = (_ infoDict : [String : Any]) -> Void
    
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
        }
        
    }
    
    func checkIfAnyPendingCabRequests(newRequestHandler : @escaping RideAlertHandler){
        
        FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).observe(.childAdded) { (pendingReq) in
            
            if pendingReq.exists() {
                
                let requestID = pendingReq.key
                
                if let requestInfo = pendingReq.value as? [String : Any] {
                    
                    let riderID = requestInfo[RIDER_UID] as! String
                    let latitude = requestInfo[LATITUDE] as! Double
                    let longitude = requestInfo[LONGITUDE] as! Double
                    
                    newRequestHandler([ REQUEST_UID : requestID , RIDER_UID : riderID , LATITUDE : latitude , LONGITUDE : longitude ])
                    
                }
                
            }
            
        }
    }
    
    func acceptCabRideRequest(infoDict : [String : Any]) -> Void {
        
        if let requestID = infoDict[REQUEST_UID] as? String {
            FirebaseDBURL.child(RIDE_REQUESTS).child(PENDING_REQUESTS).child(requestID).removeValue(completionBlock: { (error, dbRef) in
                
                if let error = error {
                    
                }
                else{
                    Fir
                }
                
            })
        }
        
    }
    
}
