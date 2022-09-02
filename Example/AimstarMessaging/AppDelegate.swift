//
//  AppDelegate.swift
//  AimstarMessaging
//
//  Created by Jesse Katsumata on 07/25/2022.
//  Copyright (c) 2022 Jesse Katsumata. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import AimstarMessagingSDK

let API_KEY = "YOUR_API_KEY"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        
        // AimstarMessaging Module を Initialize する
        AimstarMessaging.shared.setup(apiKey: API_KEY)
        AimstarMessaging.shared.setDeviceId(deviceId: UUID().uuidString)
        
        let token = Messaging.messaging().fcmToken
        
        if (token != nil) {
            AimstarMessaging.shared.setFcmId(fcmId: token!)
        }
        

        // Remote Notification を使える用にセットアップする
        
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )

        application.registerForRemoteNotifications()
            return true
        }

}



// [START ios_10_message_handling]
extension AppDelegate: UNUserNotificationCenterDelegate {
  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                -> Void) {
    AimstarMessaging.shared.sendLog(notification:notification)

    // Change this to your preferred presentation option
    completionHandler([[.alert, .sound]])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    AimstarMessaging.shared.sendLog(notification:response.notification)

    completionHandler()
  }
}

extension AppDelegate: MessagingDelegate {
  // [START refresh_token]
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
  }

  // [END refresh_token]
}
