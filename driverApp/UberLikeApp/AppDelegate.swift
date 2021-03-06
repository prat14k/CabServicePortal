//
//  AppDelegate.swift
//  UberLikeApp
//
//  Created by Prateek Sharma on 25/01/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
// Override point for customization after application launch.
        
//        [[UINavigationBar appearance] setTitleTextAttributes: @{
//            NSFontAttributeName: [UIFont fontWithName:@"SFUIDisplay-Regular" size:17.0f]
//            }];
//        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
//        
//        if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
//            statusBar.backgroundColor = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1];
//            //        statusBar.backgroundColor = [UIColor clearColor];
//            statusBar.tintColor = [UIColor blackColor];
//            
//        }
        
        if let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView {
            statusBarView.backgroundColor = UIColor.rgb(red: 248, green: 248, blue: 248, alpha: 1.0)
        }
        
        FirebaseApp.configure()
        
        if (UserDefaults.standard.value(forKey: USER_UID) as? String) != nil {
            // User already logged in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyBoard.instantiateViewController(withIdentifier: kDashBoardVCStoryboardID) as? DashboardViewController {
                if let navigationControll = self.window?.rootViewController as? UINavigationController {
                    navigationControll.pushViewController(vc, animated: true)
                }
            }
        }
        else{
            if Auth.auth().currentUser != nil {
                do {
                   try Auth.auth().signOut()
                }
                catch _ {}
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension UIColor {
    
    class func rgb(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
    }
    
//    class func hexToRGB(hexColor : String) -> UIColor {
//        var hexColor = hexColor.replacingOccurrences(of: "#", with: "")
//        
//        var red = hexColor.sub
//        
//        
//        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
//    }
}


extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}


