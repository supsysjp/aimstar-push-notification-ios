# Aimstar Push Notification SDK for iOS

Aimstar のプッシュ通知機能を iOS アプリに組み込むための SDK です。

## 目次

- [動作環境](#動作環境)
- [インストール](#インストール)
- [SDK で提供する機能について](#sdk-で提供する機能について)
- [SDK の Interface について](#sdk-の-interface-について)
- [アプリ側で実装する必要がある機能](#アプリ側で実装する必要がある機能)
- [サンプルアプリ](#サンプルアプリ)
- [リリースに際して](#リリースに際して)
- [ライセンス](#ライセンス)

## 動作環境

- iOS 15 以降が必要です
- Xcode 16.0 以降、Swift 5.10 を開発環境としています

## インストール

マニュアルまたは CocoaPods でインストールできます。

### マニュアル

[Releases](https://github.com/supsysjp/aimstar-push-notification-ios/releases) から AimstarMessagingSDK.zip をダウンロードして展開し、AimstarMessagingSDK.xcframework をプロジェクトに含めてください。

### CocoaPods

```ruby
pod "AimstarMessaging"
```

## SDK で提供する機能について

- Aimstar の Push 通知を受信するために必要な情報を登録する
- Push 通知から起動した場合のログ送信

※ Firebase 自体は既に該当するアプリに組み込まれている想定です。

## SDK の Interface について

### 用語

| 用語 | 説明 |
| --- | --- |
| API Key | AimstarMessaging を利用するために必要な API キーで、Aimstar 側で事前にアプリ開発者に発行されます。 |
| Tenant ID | AimstarMessaging を利用するために必要なテナント ID で、Aimstar 側で事前にアプリ開発者に発行されます。 |
| Customer ID | アプリ開発者がユーザーを識別する ID で、アプリ開発者が独自に発行、生成、または利用します。 |
| FCM トークン | Firebase がプッシュ通知を送信するために必要な ID で、Firebase 側で発行・更新され、アプリ側で取得できます。 |

### AimstarMessaging class

使用する際は `AimstarMessaging.shared` から下記メソッドを呼び出します。

#### setup(apiKey: String, tenantId: String)

アプリ起動時に呼び出してください。

#### registerToken(customerId: String, fcmToken: String)

アプリ起動時など、ログインが完了したタイミングで FCM トークンを取得して呼び出してください。ここで配信基盤のバックエンドに CustomerID、FCM トークンが連携され、配信対象になります。

#### registerToken(customerId: String, fcmToken: String, targetAppId: String)

複数のプッシュ通知配信接続先を持つ場合など、ターゲットアプリを明示的に指定したい場合に使用します。

```swift
AimstarMessaging.shared.registerToken(
    customerId: customerId,
    fcmToken: fcmToken,
    targetAppId: "your-app-id"
)
```

#### logout()

ログアウトしたときなど、CustomerID がアプリ側で有効ではなくなった時に呼び出してください。

この処理を呼び出すことで Push 通知の配信対象外になります。

また、通信などの影響でログアウト処理が完了しなかった場合は、以下のようにしてエラーハンドリングすることができます。

```swift
do {
    try await AimstarMessaging.shared.logout()
} catch let error as AimstarMessaging.Error {
    print("error at \(#function): \(String(describing: error))")
    switch error {
    case .serverError, .networkError:
        // リトライ可能なエラー
        break
    case .clientError, .precondition:
        // リトライ不可能なエラー（無視してよい）
        break
    }
}
```

logout リクエストが失敗したままですと、想定していない通知が届いてしまう場合があります。そういったケースを防ぐために、リクエストが失敗した際にリトライしたい場合等に使用することができます。

##### エラー型

| エラー | 説明 | 対処 |
| --- | --- | --- |
| `.precondition(String)` | 内部不整合（SDK の使用方法が誤っている） | リトライ不可 |
| `.clientError(Int?)` | 4xx エラー | リトライ不可 |
| `.serverError(Int?)` | 5xx エラー | リトライ可能 |
| `.networkError(Error)` | ネットワークエラー | リトライ可能 |

#### sendLog(notification: UNNotification)

Aimstar の Push 通知から起動した際にログを送信します。ログを Aimstar に集積することで、Push 通知の効果検証を行うことができます。

## アプリ側で実装する必要がある機能

### AimstarMessaging の Initialize

アプリが起動した際に AimstarMessaging に必要なパラメーターを設定します。

```swift
import AimstarMessagingSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AimstarMessaging.shared.setup(apiKey: API_KEY, tenantId: TENANT_ID)
    // ...
    return true
}
```

### Customer ID / FCM トークン の設定

ユーザーの Customer ID と FCM トークンをセットしてください。これら二つを合わせて `registerToken(customerId:fcmToken:)` に渡すとセットできます。

例えばアプリ起動時にログイン済みの場合やログイン完了時に、FCM トークンを取得して呼び出してください。

```swift
import AimstarMessagingSDK
import FirebaseMessaging

// ログイン完了時などに呼び出す
let fcmToken = Messaging.messaging().fcmToken
if let fcmToken = fcmToken {
    AimstarMessaging.shared.registerToken(customerId: customerId, fcmToken: fcmToken)
}
```

FCM トークンが更新された場合も再度セットしてください。

```swift
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            AimstarMessaging.shared.registerToken(customerId: customerId, fcmToken: fcmToken)
        }
    }
}
```

ログアウトしたときなど、Customer ID がアプリ側で有効ではなくなった時は logout を呼び出してください。

```swift
try await AimstarMessaging.shared.logout()
```

### ユーザーが通知を開いた際にログ送信

ユーザーがアプリのフォアグラウンド、及びバックグラウンドで通知を開いた際に sendLog を発火させます。

```swift
import AimstarMessagingSDK

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        AimstarMessaging.shared.sendLog(notification: notification)
        completionHandler([[.banner, .list, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        AimstarMessaging.shared.sendLog(notification: response.notification)
        completionHandler()
    }
}
```

### アプリアイコンへの通知バッジの付与

アプリアイコンの右上へ丸い数字のバッジを付ける機能は AimstarMessaging SDK では提供しておりません。アプリ側で実装する必要があります。

アプリで `applicationIconBadgeNumber` をセットすることでバッジの数字を設定します。0 に設定すると消すことができます。アプリの起動時やお知らせ画面の表示などの任意の時点で、アプリの機能に合わせて実装してください。

参考ドキュメント: <https://developer.apple.com/documentation/uikit/uiapplication/1622918-applicationiconbadgenumber>

## サンプルアプリ

このリポジトリの [Example](Example/) フォルダに簡易的な実装例があります。SDK の導入方法や各メソッドの呼び出しタイミングの参考にしてください。

## リリースに際して

弊社の AIMSTAR プッシュ配信用 SDK を貴社アプリケーションに実装していただいた際に、アプリをリリースする際にアプリストアの審査で「トラッキングが含まれる」といった旨のアラートが上がってしまう場合がございます。

この際には、大変恐れ入りますが、アプリのプライバシーに関する回答で、トラッキングを行っている旨を記載して更新いただき、リリースを進めていただきますようお願いいたします。

## ライセンス

Apache-2.0 License - 詳細は [LICENSE](LICENSE) を参照してください。
