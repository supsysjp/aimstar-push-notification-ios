//
//  ViewController.swift
//  AimstarMessaging
//
//  Created by Jesse Katsumata on 07/25/2022.
//  Copyright (c) 2022 Jesse Katsumata. All rights reserved.
//
import UIKit
import AimstarMessagingSDK
import FirebaseMessaging

let AIMSTAR_ID = "AimstarMessagingTestIos"

class ViewController: UIViewController {
    @IBOutlet var fcmTokenMessage: UILabel!
    @IBOutlet var remoteFCMTokenMessage: UILabel!

    func createHeader(_ label: String) -> UILabel {
      let header = UILabel()
      header.text = label
      header.textColor = .black
      header.font = .boldSystemFont(ofSize: 21)
      header.translatesAutoresizingMaskIntoConstraints = false

      return header
    }

    func createLabel(_ text: String) -> UILabel {
      let label = UILabel()
      label.text = text
      label.textColor = .black
      label.translatesAutoresizingMaskIntoConstraints = false

      return label
    }

    func createButton(_ label: String) -> UIButton {
        let button = UIButton()
        button.setTitleColor(.blue, for: .normal)
        button.setTitleColor(.red, for: .highlighted)
        button.setTitle(label, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .boldSystemFont(ofSize: 21)

        return button
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Notification の Observer を追加
        NotificationCenter.default.addObserver(
             self,
             selector: #selector(displayFCMToken(notification:)),
             name: Notification.Name("FCMToken"),
             object: nil
           )

        // 基本的機能をテストするためのUIを追加
        view.backgroundColor = .white

        let fcmTokenLabel = createHeader("Logged FCM Token:")
        view.addSubview(fcmTokenLabel)

        self.fcmTokenMessage = createLabel("")
        view.addSubview(self.fcmTokenMessage)
                
        let label = createHeader("Aimstar Messaging Example")
        view.addSubview(label)
        
        let registerButton = createButton("Register AimstarId")
        registerButton.addTarget(self, action: #selector(registerAimstarId), for: .touchUpInside)
        view.addSubview(registerButton)
        
        let logoutButton = createButton("Logout")
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        view.addSubview(logoutButton)

        let copyButton = createButton("Copy FCM Token")
        copyButton.addTarget(self, action: #selector(copyFCMToken), for: .touchUpInside)
        view.addSubview(copyButton)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            registerButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 24),
            copyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            copyButton.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 24),
            // Log Messages
            fcmTokenLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            self.fcmTokenMessage.topAnchor.constraint(equalTo: fcmTokenLabel.bottomAnchor)
        ])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func logout () {
        print("logout")
        AimstarMessaging.shared.logout()
    }
    
    @objc func registerAimstarId () {
        print("register aimstar Id")
        AimstarMessaging.shared.registerAimstarId(aimstarId: AIMSTAR_ID)
    }
    
    @objc func displayFCMToken(notification: NSNotification) {
      guard let userInfo = notification.userInfo else { return }
        
      if let fcmToken = userInfo["token"] as? String {
        print("Received FCM token: \(fcmToken)")
        fcmTokenMessage.text = "\(fcmToken)"
      }
    }

    @objc func copyFCMToken() {
        UIPasteboard.general.string = self.fcmTokenMessage.text
    }
}

