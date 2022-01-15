# 概要
iPhoneアプリとAWS IoTでMQTTを行うシンプルなソースコードです。
CocoaMQTT https://github.com/emqx/CocoaMQTT をベースにしています。

&nbsp;
# 環境
iPhone8   iOS:15.2

Xcode 13.2.1

AWS IoT

&nbsp;
# 使い方

## AWS IoTのホスト
```
let defaultHost = "XXXXXXXXXXXXXXX-ats.iot.ap-northeast-1.amazonaws.com"
```

## MQTTの設定
clientIDにはAWS IoTの「モノ」の名前とします。
```
let clientID = "iPhone-location"
```

client-keycertにはAWS IoTでモノを作成した際に取得できる証明書、秘密鍵、ルート証明書から作成します。
```
openssl pkcs12 -export -clcerts -in XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-certificate.pem.crt -inkey XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-private.pem.key -certfile AmazonRootCA1.pem -out client.p12

```

client-keycertのcertPasswordはp12ファイル作成時に設定したパスワードを入力します。

```
let clientCertArray = getClientCertFromP12File(certName: "client-keycert", certPassword: "password") //certPassword is your password when you created p12 file
```

## Puslish
MQTT設定で指定したモノに対して、「iphone/topic」というトピック名でメッセージを発行します。
```
@IBAction func sendMessage(_ sender: Any) {
        print("send Message")
        let message = "{\"message\":\"hello world!\"}"
        let publishProperties = MqttPublishProperties()
        publishProperties.contentType = "JSON"
        
        mqtt!.publish("iphone/topic", withString: message, qos: .qos1)
    }
```

## Subscribe
AWS IoTから「aws/iot」というトピック名で発行されたメッセージを購読します。
```
mqtt.subscribe("aws/iot", qos: CocoaMQTTQoS.qos1)
```
