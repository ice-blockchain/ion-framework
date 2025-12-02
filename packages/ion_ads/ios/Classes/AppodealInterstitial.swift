import Flutter
import Foundation
import Appodeal

internal final class AppodealInterstitial {
    
    internal let adChannel: FlutterMethodChannel
    internal let adListener: Listener
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/interstitial", binaryMessenger: registrar.messenger())
        adListener = Listener(adChannel: adChannel)
    }
    
    internal final class Listener: NSObject, AppodealInterstitialDelegate {
        
        private let adChannel: FlutterMethodChannel
        
        fileprivate init(adChannel: FlutterMethodChannel) {
            self.adChannel = adChannel
        }
        
        func interstitialDidLoadAdIsPrecache(_ precache: Bool) {
            adChannel.invokeMethod("onInterstitialLoaded", arguments: ["isPrecache": precache])
        }
        
        func interstitialDidFailToLoadAd() {
            adChannel.invokeMethod("onInterstitialFailedToLoad", arguments: nil)
        }
        
        func interstitialWillPresent() {
            adChannel.invokeMethod("onInterstitialShown", arguments: nil)
        }
        
        func interstitialDidFailToPresent() {
            adChannel.invokeMethod("onInterstitialShowFailed", arguments: nil)
        }
        
        func interstitialDidClick() {
            adChannel.invokeMethod("onInterstitialClicked", arguments: nil)
        }
        
        func interstitialDidDismiss() {
            adChannel.invokeMethod("onInterstitialClosed", arguments: nil)
        }
        
        func interstitialDidExpired() {
            adChannel.invokeMethod("onInterstitialExpired", arguments: nil)
        }
    }
}
