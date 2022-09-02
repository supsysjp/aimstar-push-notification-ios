# AimstarMessaging SDK iOS

## Requirements
iOS 13+
Xcode 13.4.1+

## SDKで提供する機能について
- aimstarのPush通知を受信するために必要な情報を登録する
- Push通知から起動した場合のログ送信

# SDKのInterfaceについて
## Aimstar class
Aimstar のクラスです。
シングルトンとして使うため、使用する際は `Aimstar.shared` からメソッドを呼び出します
### setup(apiKey: String)  
アプリ起動時に呼び出してください。

### registerAimstarId(aimstarId: String)
Aimstar Id を登録する際に使用します。

### setDeviceId(deviceId: String)
端末の識別IDをセットします

### setFcmId(fcmId: String)
端末のFCM IDをセットします

### logout()
セットしている aimstarId を削除します

### sendLog(notification: UNNotification)
AimstarのPush通知から起動した際にPayloadに含まれるNotificationIdを使用して呼び出しします。
# アプリ側で実装する必要がある機能
### AimstarMessaging の Initialize
アプリが起動した際に AimstarMessaging に必要なパラメーターを記入します

Swift:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  AimstarMessaging.shared.setup(apiKey: API_KEY, apiHost: API_HOST)
  AimstarMessaging.shared.setDeviceId(deviceId: UUID().uuidString)

  ...
}
```

### FCM ID の設定

任意のタイミングで FCM ID をAimstarMessagingに設定します。

```swift

import FirebaseMessaging

  ...
  let token = Messaging.messaging().fcmToken
  AimstarMessaging.shared.setFcmId(fcmId: token)
```

### ユーザーが通知を開いた際にログ送信

ユーザーがアプリのフォアグラウンド、及びバックグラウンドで通知を開いた際に sendLog を発火させます

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                -> Void) {
    AimstarMessaging.shared.sendLog(notification:notification)
    completionHandler([[.alert, .sound]])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    AimstarMessaging.shared.sendLog(notification:response.notification)
    completionHandler()
  }
}

```
