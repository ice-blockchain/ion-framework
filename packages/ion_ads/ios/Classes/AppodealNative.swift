import Appodeal
import Flutter
import Foundation

final class AppodealNative {
    let adChannel: FlutterMethodChannel
    let adListener: Listener
    
    private lazy var settings: APDNativeAdSettings = {
        let adSettings = APDNativeAdSettings.default()
        adSettings.autocacheMask = [.icon, .media]
        adSettings.type = .auto

        return adSettings
    }()
    
    private lazy var nativeAdQueue: APDNativeAdQueue = .init(
        sdk: nil,
        settings: settings,
        delegate: adListener,
        autocache: true
    )
    
    private lazy var nativeArray: [APDNativeAd] = []
    @IBOutlet weak var nativeAdView: UIView!
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/native", binaryMessenger: registrar.messenger())
        adListener = Listener(adChannel: adChannel)
    }
    
    lazy var currentAdCount: NSInteger = nativeAdQueue.currentAdCount
    
    func load() {
        nativeAdQueue.loadAd()
    }
    
    func getNativeAd() -> APDNativeAd? {
        if let nativeAd = nativeArray.first {
            return nativeAd
        }
        let nativeAds = nativeAdQueue.getNativeAds(ofCount: 1)
        
        if let nativeAd = nativeAds.isEmpty ? nil : nativeAds.first {
            nativeAd.delegate = adListener
            nativeArray.append(nativeAd)
            return nativeAd
        } else {
            return nil
        }
    }
        
    final class Listener: NSObject, APDNativeAdQueueDelegate, APDNativeAdPresentationDelegate {
        private let adChannel: FlutterMethodChannel
        
        fileprivate init(adChannel: FlutterMethodChannel) {
            self.adChannel = adChannel
        }
        
        func adQueueAdIsAvailable(_ adQueue: APDNativeAdQueue, ofCount count: UInt) {
            adChannel.invokeMethod("onNativeLoaded", arguments: nil)
            print("The value is \(adQueue.currentAdCount)")
        }
        
        func adQueue(_ adQueue: APDNativeAdQueue, failedWithError error: Error) {
            adChannel.invokeMethod("onNativeFailedToLoad", arguments: nil)
        }
        
        func nativeAdWillLogImpression(_ nativeAd: APDNativeAd) {
            adChannel.invokeMethod("onNativeShown", arguments: nil)
        }
        
        func nativeAdWillLogUserInteraction(_ nativeAd: APDNativeAd) {
            adChannel.invokeMethod("onNativeClicked", arguments: nil)
        }
        
        func nativeAdDidExpired(_ nativeAd: APDNativeAd) {
            adChannel.invokeMethod("onNativeExpired", arguments: nil)
        }
    }
}
