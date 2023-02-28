# AimstarMessaging SDK iOS

## 動作環境

* iOS 13以降が必要です
* Xcode 13.4.1以降を開発環境としています

## インストール

マニュアルまたはCocoaPodsでインストールできます。

### マニュアル

[releases](releases) から AimstarMessagingSDK.zip をダウンロードして展開し AimstarMessagingSDK.xcframework をプロジェクトに含めてください

### CocoaPods

```ruby
pod "AimstarMessaging"
```


## SDKで提供する機能について
- AimstarのPush通知を受信するために必要な情報を登録する
- Push通知から起動した場合のログ送信

※ Firebase自体は既に該当するアプリに組み込まれている想定です。

# SDKのInterfaceについて

## 用語

| 用語 | 説明 |
|---|---|
| API Key | AimstarMessagingを利用するために必要なAPIキーで、Aimstar側で事前にアプリ開発者に発行されます。 |
| Tenant ID | AimstarMessagingを利用するために必要なテナントIDで、Aimstar側で事前にアプリ開発者に発行されます。 |
| Aimstar ID | アプリ開発者がユーザーを識別するIDで、アプリ開発者が独自に発行、生成、または利用します。 |
| 端末の識別ID | アプリを端末ごと(インストールごと)に識別するIDです。アプリ起動後の初回のセットアップ時にUUIDを永続化して使います。 |
| FCMトークン | Firebaseがプッシュ通知を送信するために必要なIDで、Firebase側で発行・更新され、アプリ側で取得できます。 |

## AimstarMessaging class
使用する際は `Aimstar.shared` から下記メソッドを呼び出します

### func setup(apiKey: String, tenantId: String)
アプリ起動時に呼び出してください。


### registerAimstarId(aimstarId: String)
Aimstar ID をセットします。
このタイミングで、fcmTokenおよびaimstarId、deviceIdが揃っている場合は配信基盤へそれらの情報が連携されます

### setDeviceId(deviceId: String)
端末の識別IDをセットします

### setFcmId(fcmId: String)
端末のFCMトークンをセットします
このタイミングで、fcmTokenおよびaimstarId、deviceIdが揃っている場合は配信基盤へそれらの情報が連携されます

### logout()
ログアウトしたときや、匿名ユーザーによる使用など、アプリにおいてAimstarIdを特定できない状態となった場合に呼び出してください。
この処理を呼び出すことでPush通知の配信対象外になります。

### sendLog(notification: UNNotification)
AimstarのPush通知から起動した際にログを送信します
ログをaimstarに集積することで、Push通知の効果検証を行うことができます

# アプリ側で実装する必要がある機能


### AimstarMessaging の Initialize
アプリが起動した際に AimstarMessaging に必要なパラメーターを記入します

Swift:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  AimstarMessaging.shared.setup(apiKey: API_KEY, tenantId: TENANT_ID)
  AimstarMessaging.shared.setDeviceId(deviceId: uuid) // UUID().uuidStringを端末ごとに永続化したものをセットします

  ...
}
```

### Aimstar IDの設定

ユーザーのAimstar IDをセットしてください。例えばアプリ起動時にログイン済みの場合やログイン完了時に呼び出してください。

```swift
  ...
  AimstarMessaging.shared.registerAimstarId(aimstarId: AIMSTAR_ID)
  ...
```

ログアウトしたときなど、有効なAimstar IDが無くなった場合に呼び出してください。

```swift
  ...
  AimstarMessaging.shared.logout()
  ...
```

### FCMトークンの設定

FirebaseからFCMトークンを取得できたタイミングでAimstarMessagingにセットします。FCMトークンが更新された場合も再度セットしてください。

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
