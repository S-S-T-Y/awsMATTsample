//
//  ViewController.swift
//  awsMQTTsample
//
//  Created by S-S-T-Y on 2022/01/12.
//

import UIKit
import CocoaMQTT

class ViewController: UIViewController {
    
    let defaultHost = "XXXXXXXXXXXXXXX-ats.iot.ap-northeast-1.amazonaws.com"
    
    var mqtt5: CocoaMQTT5?
    var mqtt: CocoaMQTT?

    @IBAction func sendMessage(_ sender: Any) {
        print("send Message")
        let message = "{\"message\":\"hello world!\"}"
        let publishProperties = MqttPublishProperties()
        publishProperties.contentType = "JSON"
        
        mqtt!.publish("iphone/topic", withString: message, qos: .qos1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mqttSetting()
        print("welcome to MQTT ")
    }
    
    func mqttSetting() {
            let clientID = "iPhone-location"
            mqtt = CocoaMQTT(clientID: clientID, host: defaultHost, port: 8883)
            mqtt!.username = ""
            mqtt!.password = ""
            mqtt!.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
            mqtt!.keepAlive = 60
            mqtt!.delegate = self
            mqtt!.enableSSL = true
            mqtt!.allowUntrustCACertificate = true

            let clientCertArray = getClientCertFromP12File(certName: "client-keycert", certPassword: "password") //certPassword is your password when you created p12 file

            var sslSettings: [String: NSObject] = [:]
            sslSettings[kCFStreamSSLCertificates as String] = clientCertArray
        
            mqtt!.sslSettings = sslSettings
            _ = mqtt!.connect()
            mqtt!.autoReconnect = true
    }
    
    func getClientCertFromP12File(certName: String, certPassword: String) -> CFArray? {
        // get p12 file path
        let resourcePath = Bundle.main.path(forResource: certName, ofType: "p12")
        
        guard let filePath = resourcePath, let p12Data = NSData(contentsOfFile: filePath) else {
            print("Failed to open the certificate file: \(certName).p12")
            return nil
        }
        
        // create key dictionary for reading p12 file
        let key = kSecImportExportPassphrase as String
        let options : NSDictionary = [key: certPassword]
        
        var items : CFArray?
        let securityError = SecPKCS12Import(p12Data, options, &items)
        
        guard securityError == errSecSuccess else {
            if securityError == errSecAuthFailed {
                print("ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?")
            } else {
                print("Failed to open the certificate file: \(certName).p12")
            }
            return nil
        }
        
        guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
            return nil
        }
        
        let dictionary = (theArray as NSArray).object(at: 0)
        guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
            return nil
        }
        let certArray = [identity] as CFArray
        
        return certArray
    }
}

extension ViewController: CocoaMQTTDelegate {

    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")
        /// Validate the server certificate
        ///
        /// Some custom validation...
        ///
        /// if validatePassed {
        ///     completionHandler(true)
        /// } else {
        ///     completionHandler(false)
        /// }
        completionHandler(true)
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")

        if ack == .accept {
            TRACE("accept")
            mqtt.subscribe("aws/iot", qos: CocoaMQTTQoS.qos1)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(message.string.description), id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message: \(message.string.description), id: \(id)")

        let name = NSNotification.Name(rawValue: "MQTTMessageNotification")
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic, "id": id])
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("subscribed: \(success), failed: \(failed)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        TRACE("topic: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(err.description)")
    }
}

extension ViewController {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

extension Optional {
    // Unwrap optional value for printing log only
    var description: String {
        if let self = self {
            return "\(self)"
        }
        return ""
    }
}