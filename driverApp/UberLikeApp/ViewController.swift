//
//  ViewController.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 25/01/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    @IBAction func alertAct(_ sender: UIButton) {
        
        DropDownAlert.showMessage("Hi !!! A test MessageHi !!! A test MessageHi !!! A test MessageHi !!! A test MessageHi !!! A test MessageHi !!! A test Message", withTextColor: nil, backGroundColor: nil, position: DisplayPosition.bottom)
        
    }
    
    
    @IBAction func alertActTop(_ sender: UIButton) {
        
        DropDownAlert.showMessage("Hi !!! A test MessageHi !!! A test MessageHi !!! A test MessageHi !!! A test MessageHi !!! A test MessageHi !!! A test Message", withTextColor: nil, backGroundColor: nil, position: DisplayPosition.top)
        
    }
    
}

