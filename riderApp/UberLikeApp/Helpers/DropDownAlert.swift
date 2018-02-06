//
//  DropDownAlert.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 04/02/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit

enum DisplayPosition {
    case top
    case bottom
}

let labelLeftPadding : CGFloat = 15
let labelRightPadding : CGFloat = 15
let labelTopPadding : CGFloat = 15
let labelBottomPadding : CGFloat = 15

class DropDownAlert: NSObject {
    
    
    private static let alertView : UIView! = {

        let alertView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        alertView.backgroundColor = UIColor.gray

        alertView.addSubview(alertLabel)
        
        alertView.addConstraint(NSLayoutConstraint(item: alertLabel, attribute: .top, relatedBy: .equal, toItem: alertView, attribute: .top, multiplier: 1, constant: labelTopPadding))
        alertView.addConstraint(NSLayoutConstraint(item: DropDownAlert.alertLabel, attribute: .bottom, relatedBy: .equal, toItem: alertView, attribute: .bottom, multiplier: 1, constant: -labelBottomPadding))
        alertView.addConstraint(NSLayoutConstraint(item: DropDownAlert.alertLabel, attribute: .leading, relatedBy: .equal, toItem: alertView, attribute: .leading, multiplier: 1, constant: labelLeftPadding))
        alertView.addConstraint(NSLayoutConstraint(item: DropDownAlert.alertLabel, attribute: .trailing, relatedBy: .equal, toItem: alertView, attribute: .trailing, multiplier: 1, constant: -labelRightPadding))
        
        return alertView
    }()
    
    private static let alertLabel : UILabel! = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.font = UIFont(descriptor: UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.family : "Helvetica" , UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.semibold]]), size: 16)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private class func addLabelContraints() {
        alertView.addSubview(alertLabel)
        
        alertView.addConstraint(NSLayoutConstraint(item: alertLabel, attribute: .top, relatedBy: .equal, toItem: alertView, attribute: .top, multiplier: 1, constant: labelTopPadding))
        alertView.addConstraint(NSLayoutConstraint(item: DropDownAlert.alertLabel, attribute: .bottom, relatedBy: .equal, toItem: alertView, attribute: .bottom, multiplier: 1, constant: -labelBottomPadding))
        alertView.addConstraint(NSLayoutConstraint(item: DropDownAlert.alertLabel, attribute: .leading, relatedBy: .equal, toItem: alertView, attribute: .leading, multiplier: 1, constant: labelLeftPadding))
        alertView.addConstraint(NSLayoutConstraint(item: DropDownAlert.alertLabel, attribute: .trailing, relatedBy: .equal, toItem: alertView, attribute: .trailing, multiplier: 1, constant: -labelRightPadding))
    }
    
    
    class private func calcLabelSize(text : String, font : UIFont , maxWidth : CGFloat) -> CGRect {
        let size = CGSize(width: maxWidth, height: 500)
        return NSString(string: text).boundingRect(with: size, options: [NSStringDrawingOptions.usesLineFragmentOrigin , .usesFontLeading], attributes: [NSAttributedStringKey.font : font], context: nil)
    }
    
}


extension DropDownAlert {
    
    
    class func showMessage(_ message : String, withTextColor textColor : UIColor?, backGroundColor : UIColor? ,  position : DisplayPosition?){
        
        //        var displayPos : DisplayPosition = .top, txtColor, bgColor  : UIColor
        
        var displayPos : DisplayPosition = .top, txtColor = UIColor.white, bgColor = UIColor.gray
        
        if let position = position {
            displayPos = position
        }
        
        if let color = textColor {
            txtColor = color
        }
        
        if let color = backGroundColor {
            bgColor = color
        }
        
        alertView.layer.removeAllAnimations()
        
        alertView.backgroundColor = bgColor
        alertLabel.textColor = txtColor
        
        alertLabel.text = message
        
        if let window = UIApplication.shared.keyWindow {
            
            var rect = calcLabelSize(text: message, font: alertLabel.font , maxWidth : window.frame.size.width - 30)
            rect.size.height = rect.height + labelBottomPadding + labelTopPadding
            
            var initialFrame , finalFrame : CGRect
            
            var bottomYSafeAreaInset : CGFloat = 0.0
            if #available(iOS 11, *){
                bottomYSafeAreaInset = window.safeAreaInsets.bottom
            }
            
            
            switch displayPos {
            case .top:
                initialFrame = CGRect(x: 0, y: -rect.size.height-5, width: window.frame.size.width, height: rect.size.height)
                finalFrame = CGRect(x: 0, y: UIApplication.shared.statusBarFrame.size.height, width: window.frame.size.width, height: rect.size.height)
            case .bottom:
                initialFrame = CGRect(x: 0, y: 5+window.frame.size.height, width: window.frame.size.width, height: rect.size.height)
                finalFrame = CGRect(x: 0, y: window.frame.size.height - rect.size.height - bottomYSafeAreaInset, width: window.frame.size.width, height: rect.size.height)
            }
            
            
            alertView.frame = initialFrame
            
            window.addSubview(alertView)
            
            UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseOut], animations: {
                alertView.frame = finalFrame
            }, completion: { (finished) in
                
            })
            
            removeDropDownAlert(alertView, withInitialState: initialFrame)
            
        }
        
    }
    
    class func removeDropDownAlert(_ alert : UIView, withInitialState initialFrame : CGRect){
        
        UIView.animate(withDuration: 1, delay: 3, options: [.curveEaseIn], animations: {
            alert.frame = initialFrame
        }, completion: { (finished) in
            if finished {
                alert.removeFromSuperview()
            }
        })
        
    }
    
}

