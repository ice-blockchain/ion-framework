import Flutter
import Foundation
import Appodeal

internal final class AppodealBanner {
    
    internal let adChannel: FlutterMethodChannel
    internal let adListener: Listener
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/banner", binaryMessenger: registrar.messenger())
        adListener = Listener(adChannel: adChannel)
    }
    
    internal final class Listener: NSObject, AppodealBannerDelegate {
        
        private let adChannel: FlutterMethodChannel
        
        fileprivate init(adChannel: FlutterMethodChannel) {
            self.adChannel = adChannel
        }
        
        func bannerDidLoadAdIsPrecache(_ precache: Bool) {
            adChannel.invokeMethod("onBannerLoaded", arguments: ["isPrecache": precache])
        }
        
        func bannerDidShow() {
            adChannel.invokeMethod("onBannerShown", arguments: nil)
        }
        
        func bannerDidFailToLoadAd() {
            adChannel.invokeMethod("onBannerFailedToLoad", arguments: nil)
        }
        
        func bannerDidClick() {
            adChannel.invokeMethod("onBannerClicked", arguments: nil)
        }
        
        func bannerDidExpired() {
            adChannel.invokeMethod("onBannerExpired", arguments: nil)
        }
    }
}
