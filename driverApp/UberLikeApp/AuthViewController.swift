//
//  AuthViewController.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 04/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit
import SVProgressHUD

class AuthViewController: UIViewController {

    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var scrollViewBottomSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    var isKeyBoardVisible : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addGradientLayer()
        addTapGestureToView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardNotificationListeners()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotificationListeners()
    }
    
    func addGradientLayer(){
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.rgb(red: 36, green: 198, blue: 217, alpha: 1.0).cgColor , UIColor.rgb(red: 8, green: 8, blue: 99, alpha: 1.0).cgColor]
        
        gradientLayer.frame = view.frame
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func addTapGestureToView(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard(_:)))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func closeKeyboard(_ sender : UIGestureRecognizer){
        self.view.endEditing(true)
    }
    
    @IBAction func loginAction(_ sender : UIButton){
        if !checkCredentialsLiability() {
            return
        }
        
        let email = emailTextField.text!
        let password = passwordTextField.text!
        
        SVProgressHUD.show(withStatus: "Logging in")
        
        AuthProvider.Instance.loginUser(withEmail: email, andPassword: password) { (message) in
            if let msg = message {
                //                self.showAlertWithTitle("Problem with Login", message: msg)
                SVProgressHUD.showError(withStatus: msg)
            }
            else{
                SVProgressHUD.showSuccess(withStatus: "Successfully logged in")
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyBoard.instantiateViewController(withIdentifier: kDashBoardVCStoryboardID) as? DashboardViewController {
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
        
    }
    
    @IBAction func signupAction(_ sender : UIButton) {
        if !checkCredentialsLiability() {
            return
        }
        
        let email = emailTextField.text!
        let password = passwordTextField.text!
        
        AuthProvider.Instance.registerAction(withEmail: email, andPassword: password) { (message) in
            if let msg = message {
                //                self.showAlertWithTitle("Problem with Signup", message: msg)
                SVProgressHUD.showError(withStatus: msg)
            }
            else{
                SVProgressHUD.showSuccess(withStatus: "Successfully logged in")
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyBoard.instantiateViewController(withIdentifier: kDashBoardVCStoryboardID) as? DashboardViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                        self.navigationController?.pushViewController(vc, animated: true)
                    })
                }
            }
        }
        
        
    }
    
    func checkCredentialsLiability() -> Bool{
        
        if let email = emailTextField.text {
            if !isEmailValid(email: email) {
                showAlertWithTitle("The entered email is not valid", message: "The entered email doesn't follow the email id character rules")
                return false
            }
        }
        
        if let password = passwordTextField.text {
            if password.count < 6 {
                showAlertWithTitle("The entered password is too small", message: "The minimum length for the password is 6 letters")
                return false
            }
        }
        
        return true
    }
    
    func addKeyboardNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboardNotificationListeners() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}

extension AuthViewController : UITextFieldDelegate {
    
    @objc func keyboardWillShow(_ notification : Notification){
        scrollViewBottomSpaceConstraint.constant = 300
        self.view.layoutIfNeeded()
        
        isKeyBoardVisible = true
    }
    
    @objc func keyboardWillHide(_ notification : Notification){
        scrollViewBottomSpaceConstraint.constant = 50
        self.view.layoutIfNeeded()
        
        isKeyBoardVisible = false
    }
    
    func isEmailValid(email : String) -> Bool {
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
            return false
        }
        
        let stricterFilter = true
        let stricterFilterString = "^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$"
        let laxString = "^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$"
        let emailRegex = stricterFilter ? stricterFilterString : laxString
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailTest.evaluate(with:email)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let textfieldPos = scrollView.convert(textField.frame.origin, to: view).y
        let textFieldHght = textField.frame.size.height
        
        let scrollViewHght = scrollView.frame.size.height
        
        if (textfieldPos + textFieldHght) > (scrollViewHght - 240) {
            
            var duration : Double
            if isKeyBoardVisible {
                duration = 0.2
            }
            else {
                duration = 0.5
            }
            
            UIView.animate(withDuration: duration, animations: {
                self.scrollView.contentOffset = CGPoint(x: 0, y: (textfieldPos + textFieldHght) - (scrollViewHght - 240) + 30)
            })
        }
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == passwordTextField {
            if string != "" {
                if let txt = textField.text {
                    if txt.count >= 150 {
                        showAlertWithTitle("The entered password is too big", message: "The maximum length for the password is 150 letters only")
                    }
                }
            }
        }
        return true
    }
    
    
    func showAlertWithTitle(_ title : String , message : String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(okayAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
