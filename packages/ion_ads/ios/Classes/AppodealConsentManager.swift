import Flutter
import Foundation
import Appodeal
import StackConsentManager

internal final class AppodealConsentManager {
    
    internal let adChannel: FlutterMethodChannel
    private var dialog: ConsentDialog?
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/consent_manager", binaryMessenger: registrar.messenger())
        adChannel.setMethodCallHandler(handle)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load": load(call, result)
        case "show": show(call, result)
        case "loadAndShowIfRequired": loadAndShowIfRequired(call, result)
        case "revoke": revoke(call, result)
        default: result(FlutterMethodNotImplemented)
        }
    }
    
    private func load(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let appKey = args["appKey"] as! String
        let tagForUnderAgeOfConsent = args["tagForUnderAgeOfConsent"] as! Bool
        
        let parameters = ConsentUpdateRequestParameters(
            appKey: appKey,
            mediationSdkName: "appodeal",
            mediationSdkVersion: Appodeal.getVersion(),
            COPPA: tagForUnderAgeOfConsent
        )
        
        ConsentManager.shared.requestConsentInfoUpdate(parameters: parameters) { error in
            if let error = error {
                let args: [String: String] = ["error": error.localizedDescription]
                self.adChannel.invokeMethod("onConsentFormLoadFailure", arguments: args)
            } else {
                ConsentManager.shared.load { dialog, error in
                    if let error = error {
                        let args: [String: String] = ["error": error.localizedDescription]
                        self.adChannel.invokeMethod("onConsentFormLoadFailure", arguments: args)
                    } else {
                        self.dialog = dialog
                        let status = ConsentManager.shared.status
                        let args: [String: UInt] = ["status": status.rawValue]
                        self.adChannel.invokeMethod("onConsentFormLoadSuccess", arguments: args)
                    }
                }
            }
        }
        result(nil)
    }
    
    private func show(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            let args: [String: String] = ["error": "Root view controller is nil"]
            self.adChannel.invokeMethod("onConsentFormDismissed", arguments: args)
            return
        }
        
        if let dialog = self.dialog {
            dialog.present(rootViewController: rootViewController, completion: { error in
                self.dialog = nil
                if let error = error {
                    let args: [String: String] = ["error": error.localizedDescription]
                    self.adChannel.invokeMethod("onConsentFormDismissed", arguments: args)
                } else {
                    self.adChannel.invokeMethod("onConsentFormDismissed", arguments: nil)
                }
            })
        } else {
            let args: [String: String] = ["error": "Consent form is not loaded"]
            self.adChannel.invokeMethod("onConsentFormDismissed", arguments: args)
        }
        result(nil)
    }
    
    
    private func loadAndShowIfRequired(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let appKey = args["appKey"] as! String
        let tagForUnderAgeOfConsent = args["tagForUnderAgeOfConsent"] as! Bool
        
        let parameters = ConsentUpdateRequestParameters(
            appKey: appKey,
            mediationSdkName: "appodeal",
            mediationSdkVersion: Appodeal.getVersion(),
            COPPA: tagForUnderAgeOfConsent
        )
        
        ConsentManager.shared.requestConsentInfoUpdate(parameters: parameters) { error in
            if let error = error {
                let args: [String: String] = ["error": error.localizedDescription]
                self.adChannel.invokeMethod("onConsentFormDismissed", arguments: args)
            } else {
                guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
                    let args: [String: String] = ["error": "Root view controller is nil"]
                    self.adChannel.invokeMethod("onConsentFormDismissed", arguments: args)
                    return
                }
                
                ConsentManager.shared.loadAndPresentIfNeeded(rootViewController: rootViewController) { error in
                    if let error = error {
                        let args: [String: String] = ["error": error.localizedDescription]
                        self.adChannel.invokeMethod("onConsentFormDismissed", arguments: args)
                    } else {
                        self.adChannel.invokeMethod("onConsentFormDismissed", arguments: nil)
                    }
                }
            }
        }
        
        result(nil)
    }
    
    private func revoke(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        ConsentManager.shared.revoke()
        result(nil)
    }
}
