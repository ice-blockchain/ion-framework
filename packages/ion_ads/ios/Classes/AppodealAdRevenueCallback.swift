import Flutter
import Foundation
import Appodeal

internal final class AppodealAdRevenueCallback {
    
    internal let adChannel: FlutterMethodChannel
    internal let adListener: Listener
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/adrevenue", binaryMessenger: registrar.messenger())
        adListener = Listener(adChannel: adChannel)
    }
    
    internal final class Listener: NSObject, AppodealAdRevenueDelegate {
        
        private let adChannel: FlutterMethodChannel
        
        fileprivate init(adChannel: FlutterMethodChannel) {
            self.adChannel = adChannel
        }
        
        func didReceiveRevenue(forAd ad: AppodealAdRevenue) {
            adChannel.invokeMethod(
                "onAdRevenueReceive",
                arguments: [
                    "adType": ad.adType.rawValue,
                    "networkName": ad.networkName,
                    "demandSource": ad.demandSource,
                    "adUnitName": ad.adUnitName,
                    "placement": ad.placement,
                    "revenue": ad.revenue,
                    "currency": ad.currency,
                    "revenuePrecision" : ad.revenuePrecision
                ]
            )
        }
    }
}
