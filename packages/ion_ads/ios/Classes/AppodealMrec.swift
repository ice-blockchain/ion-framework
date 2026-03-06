import Flutter
import Foundation
import Appodeal

internal final class AppodealMrec {
    
    internal let adChannel: FlutterMethodChannel
    internal let adListener: Listener
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/mrec", binaryMessenger: registrar.messenger())
        adListener = Listener(adChannel: adChannel)
    }
    
    internal final class Listener: NSObject, APDBannerViewDelegate {
        
        private let adChannel: FlutterMethodChannel
        
        fileprivate init(adChannel: FlutterMethodChannel) {
            self.adChannel = adChannel
        }
        
        func bannerViewDidLoadAd(_ bannerView: APDBannerView, isPrecache precache: Bool) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                adChannel.invokeMethod("onMrecLoaded", arguments: ["isPrecache": precache])
            }
        }
        
        func bannerViewDidShow(_ bannerView: APDBannerView) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                adChannel.invokeMethod("onMrecShown", arguments: nil)
            }
        }
        
        func bannerViewExpired(_ bannerView: APDBannerView) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                adChannel.invokeMethod("onMrecExpired", arguments: nil)
            }
        }
        
        func bannerViewDidInteract(_ bannerView: APDBannerView) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                adChannel.invokeMethod("onMrecClicked", arguments: nil)
            }
        }
        
        func bannerView(_ bannerView: APDBannerView, didFailToLoadAdWithError error: Error) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                adChannel.invokeMethod("onMrecFailedToLoad", arguments: nil)
            }
        }
    }
}
