# AimstarMessaging SDK iOS

## 動作環境

- iOS 13 以降が必要です
- Xcode 14.2 以降を開発環境としています

## インストール

マニュアルまたは CocoaPods でインストールできます。

### マニュアル

[releases](releases) から AimstarMessagingSDK.zip をダウンロードして展開し AimstarMessagingSDK.xcframework をプロジェクトに含めてください

### CocoaPods

```ruby
pod "AimstarMessaging"
```

## SDK で提供する機能について

- Aimstar の Push 通知を受信するために必要な情報を登録する
- Push 通知から起動した場合のログ送信

※ Firebase 自体は既に該当するアプリに組み込まれている想定です。

# SDK の Interface について

## 用語

| 用語         | 説明                                                                                                       |
| ------------ | ---------------------------------------------------------------------------------------------------------- |
| API Key      | AimstarMessaging を利用するために必要な API キーで、Aimstar 側で事前にアプリ開発者に発行されます。         |
| Tenant ID    | AimstarMessaging を利用するために必要なテナント ID で、Aimstar 側で事前にアプリ開発者に発行されます。      |
| Customer ID  | アプリ開発者がユーザーを識別する ID で、アプリ開発者が独自に発行、生成、または利用します。                 |
| FCM トークン | Firebase がプッシュ通知を送信するために必要な ID で、Firebase 側で発行・更新され、アプリ側で取得できます。 |

## AimstarMessaging class

使用する際は `Aimstar.shared` から下記メソッドを呼び出します

### func setup(apiKey: String, tenantId: String)

アプリ起動時に呼び出してください。

### registerToken(customerId: String, fcmToken: String)

アプリ起動時など、ログインが完了したタイミングで FcmToken を取得して呼び出してください。 ここで配信基盤のバックエンドに CustomerID、FcmToken が連携され、配信対象になります


### logout()  
ログアウトしたときなど、CustomerIDがアプリ側で有効ではなくなった時に呼び出してください。

この処理を呼び出すことでPush通知の配信対象外になります

また、通信などの影響でログアウト処理が完了しなかった場合は、以下のようにしてエラーハンドリングすることが出来ます

```swift
  do {
      try await AimstarMessaging.shared.logout()
  } catch let error as AimstarMessaging.Error {
      print("error at \(#function): \(String(describing: error))")
      switch error {
      case .serverError, .networkError:
        // (optional) error handling with retry
      case .clientError, .precondition:
          // ignore the error
          break
      }
  }
```

logoutリクエストが失敗したままですと、想定していない通知が届いてしまう場合があります
そういったケースを防ぐために、もしリクエストが失敗した際にリクエストをリトライしたい場合等に使用することができます



### sendLog(notification: UNNotification)

Aimstar の Push 通知から起動した際にログを送信します
ログを aimstar に集積することで、Push 通知の効果検証を行うことができます

# アプリ側で実装する必要がある機能

### AimstarMessaging の Initialize

アプリが起動した際に AimstarMessaging に必要なパラメーターを記入します

Swift:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  AimstarMessaging.shared.setup(apiKey: API_KEY, tenantId: TENANT_ID)
  ...
}
```

### Customer ID / FCM トークン の設定

ユーザーの Customer ID と FCM トークンをセットしてください。これら二つを合わせて `registerToken(customerId:fcmToken:)` に渡すとセットできます。

例えばアプリ起動時にログイン済みの場合やログイン完了時に、FCM トークンを取得して呼び出してください。

```swift
  ...
  let fcmToken = Messaging.messaging().fcmToken
  AimstarMessaging.shared.registerToken(customerId: customerId, fcmToken: fcmToken)
  ...
```

FCM トークンが更新された場合も再度セットしてください。

```swift
  ...
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    ...
    if let fcmToken {
      AimstarMessaging.shared.registerToken(customerId: customerId, fcmToken: fcmToken)
    }
    ...
  }
  ...
```

ログアウトしたときなど、Customer ID がアプリ側で有効ではなくなった時はlogoutを呼び出してください。

```swift
  ...
  AimstarMessaging.shared.logout()
  ...
```

### ユーザーが通知を開いた際にログ送信

ユーザーがアプリのフォアグラウンド、及びバックグラウンドで通知を開いた際に sendLog を発火させます

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                -> Void) {
    AimstarMessaging.shared.sendLog(notification: notification)
    completionHandler([[.alert, .sound]])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    AimstarMessaging.shared.sendLog(notification: response.notification)
    completionHandler()
  }
}

```
