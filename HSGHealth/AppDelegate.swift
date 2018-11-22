//
//  AppDelegate.swift
//  HSGHealth
//
//  Created by Doan Phuc Hien on 11/21/18.
//  Copyright © 2018 HSG. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import SwiftLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var locationManager = CLLocationManager()
    lazy var db = Firestore.firestore()
    lazy var center = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        let dict = [
            "type" : "didFinishLaunchingWithOptions",
            ] as [String : Any]
        storeFS(dict: dict)
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringVisits()
        
        center.requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
            
        }
        
        
        /// If you start monitoring significant location changes and your app is subsequently terminated,
        /// the system automatically relaunches the app into the background if a new event arrives.
        // Upon relaunch, you must still subscribe to significant location changes to continue receiving location events.
        if let _ = launchOptions?[UIApplication.LaunchOptionsKey.location] {
            Locator.subscribeSignificantLocations(onUpdate: { newLocation in
                // This block will be executed with the details of the significant location change that triggered the background app launch,
                // and will continue to execute for any future significant location change events as well (unless canceled).
                self.storeLocation("onUpdate", latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
            }, onFail: { (err, lastLocation) in
                // Something bad has occurred
            })
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

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        
        self.storeLocation("didVisit", latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
    }
    
    func storeLocation(_ description: String, latitude: Double, longitude: Double) {
        
        let dict = [
            "type" : description,
            "lat": latitude,
            "lng": longitude,
            ] as [String : Any]
        storeFS(dict: dict)
        
        showLocalNotification()
        
        
    }
    
    func storeFS(dict: [String : Any]) {
        let uuid = getUUID()
        
        var data = dict
        data["created"] = Date()
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        ref = db.collection(uuid).addDocument(data: data) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    func showLocalNotification() {
        
        let badge: Int = getAndIncrease("badge")
        
        let content = UNMutableNotificationContent()
        content.title = "Ahihi \(badge)"
        content.body = "Di nhau thoi"
        content.sound = .default
        content.badge = NSNumber.init(integerLiteral: badge)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: Date.init().description, content: content, trigger: trigger)
        
        center.add(request, withCompletionHandler: nil)
        
    }
    
    func getAndIncrease(_ key: String) -> Int {
        
        let badge = UserDefaults.standard.integer(forKey: key)
        var newBadge = badge
        newBadge += 1
        
        UserDefaults.standard.set(newBadge, forKey: key)
        UserDefaults.standard.synchronize()
        
        return newBadge
    }
    
    func getUUID() -> String {
        let uuid = UserDefaults.standard.string(forKey: "uuid")
        if let uuid = uuid {
            return uuid
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "uuid")
        UserDefaults.standard.synchronize()
        
        return newId
    }
    
}


