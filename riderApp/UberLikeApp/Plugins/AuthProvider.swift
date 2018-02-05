//
//  AuthProvider.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 03/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import Foundation
import Firebase

typealias AuthCompletionHandler = (_ message : String?) -> Void

class AuthProvider {
    
    private static let _instance = AuthProvider()
    
    static var Instance : AuthProvider {
        return AuthProvider._instance
    }
    
}


//Public API's
extension AuthProvider {
    
    func loginUser(withEmail email : String , andPassword password : String, completionHandler : AuthCompletionHandler?) {
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            if let error = error {
                var msg : String = error.localizedDescription
                
                if let errCode = AuthErrorCode(rawValue: error.code) {
                    switch errCode {
                    case .userNotFound : msg = "The Credentials entered are not of a registered user"
                    case .wrongPassword : msg = "The entered password is wrong"
                    case .userDisabled : msg = "The user is disabled and the login credentials are blocked"
                    case .invalidEmail : msg = "The Entered email is of invalid format"
                    case .networkError : msg = "Unable to connect to the internet"
                    case .tooManyRequests : msg = "The server is overloaded with requests. Please try again later"
                    default : break;
                    }
                }
                completionHandler?(msg)
            }
            else {
                
                completionHandler?(nil)
                print("Logged in")
            }
            
        }
        
    }
    
    func registerAction(withEmail email : String , andPassword password : String, completionHandler : AuthCompletionHandler?){
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                var msg : String = error.localizedDescription
                
                if let errCode = AuthErrorCode(rawValue: error.code) {
                    switch errCode {
                    case .emailAlreadyInUse : msg = "The entered email is already in use by another account. Please try witha different email."
                    case .weakPassword : msg = "The entered password is weak."
                    case .invalidEmail : msg = "The Entered email is of invalid format"
                    case .networkError : msg = "Unable to connect to the internet"
                    case .tooManyRequests : msg = "The server is overloaded with requests. Please try again later"
                    default : break;
                    }
                }
                completionHandler?(msg)
            }
            else{
                
                if let uid = user?.uid {
                    
                    UserDefaults.standard.set(uid, forKey: USER_UID)
                    
                    DBAccessProvider.Instance.saveUser(email: email, password: password, uid: uid)
                }
                
                completionHandler?(nil)
                print("Registered")
            }
        }
    }
}
