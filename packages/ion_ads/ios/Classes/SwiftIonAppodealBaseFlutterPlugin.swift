import Foundation
import Appodeal

extension SwiftIonAppodealFlutterPlugin: AppodealInitializationDelegate {
    
    public func appodealSDKDidInitialize() {
        channel.invokeMethod("onInitializationFinished", arguments: nil)
    }
}

internal var nativeAdViewBinders: [String: NativeAdViewBinder] = [:]

public extension Appodeal {
    @objc class func registerNativeAdBinder(binderId: String,
                                            nativeAdViewBinder: NativeAdViewBinder) -> Bool {
        if nativeAdViewBinders[binderId] != nil {
            NSLog("A NativeAdViewBinder with the following binderId already exists: %@", binderId)
            return false
        }
        
        nativeAdViewBinders[binderId] = nativeAdViewBinder
        return true
    }
    
    @objc class func unregisterNativeAdBinder(binderId: String) -> NativeAdViewBinder? {
        let binder = nativeAdViewBinders[binderId]
        if binder != nil {
            nativeAdViewBinders.removeValue(forKey: binderId)
        }
        return binder
    }
}
