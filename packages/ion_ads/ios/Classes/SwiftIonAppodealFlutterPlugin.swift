import Appodeal
import AVFoundation
import Flutter
import UIKit

public class SwiftIonAppodealFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftIonAppodealFlutterPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: instance.channel)
        registrar.addMethodCallDelegate(instance, channel: instance.adRevenueCallback.adChannel)
        registrar.addMethodCallDelegate(instance, channel: instance.interstitial.adChannel)
        registrar.addMethodCallDelegate(instance, channel: instance.rewardedVideo.adChannel)
        registrar.addMethodCallDelegate(instance, channel: instance.banner.adChannel)
        registrar.addMethodCallDelegate(instance, channel: instance.mrec.adChannel)
        registrar.addMethodCallDelegate(instance, channel: instance.native.adChannel)
        registrar.register(AppodealAdViewFactory( mrecChannel: instance.mrec.adChannel, bannerChannel: instance.banner.adChannel),
                           withId: "appodeal_flutter/banner_view")
        registrar.register(AppodealNativeAdViewFactory(nativeAdChannel: instance.native.adChannel),
                           withId: "appodeal_flutter/native_view")
    }
    
    let channel: FlutterMethodChannel
    
    private let consentManager: AppodealConsentManager
    private let adRevenueCallback: AppodealAdRevenueCallback
    
    private let interstitial: AppodealInterstitial
    private let rewardedVideo: AppodealRewarded
    private let banner: AppodealBanner
    private let mrec: AppodealMrec
    private let native: AppodealNative
    
    private init(registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "appodeal_flutter", binaryMessenger: registrar.messenger())
        consentManager = AppodealConsentManager(registrar: registrar)
        adRevenueCallback = AppodealAdRevenueCallback(registrar: registrar)
        interstitial = AppodealInterstitial(registrar: registrar)
        rewardedVideo = AppodealRewarded(registrar: registrar)
        banner = AppodealBanner(registrar: registrar)
        mrec = AppodealMrec(registrar: registrar)
        native = AppodealNative(registrar: registrar)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setTestMode": setTestMode(call, result)
        case "isTestMode": isTestMode(call, result)
        case "setLogLevel": setLogLevel(call, result)
        case "initialize": initialize(call, result)
        case "isInitialized": isInitialized(call, result)
        case "setAutoCache": setAutoCache(call, result)
        case "isAutoCacheEnabled": isAutoCacheEnabled(call, result)
        case "cache": cache(call, result)
        case "isLoaded": isLoaded(call, result)
        case "isPrecache": isPrecache(call, result)
        case "canShow": canShow(call, result)
        case "getPredictedEcpm": getPredictedEcpm(call, result)
        case "show": show(call, result)
        case "hide": hide(call, result)
        // Extra logic
        case "setSmartBanners": setSmartBanners(call, result)
        case "isSmartBanners": isSmartBanners(call, result)
        case "setTabletBanners": setTabletBanners(call, result)
        case "isTabletBanners": isTabletBanners(call, result)
        case "setBannerAnimation": setBannerAnimation(call, result)
        case "isBannerAnimation": isBannerAnimation(call, result)
        case "setBannerRotation": setBannerRotation(call, result)
        case "disableNetwork": disableNetwork(call, result)
        case "setChildDirectedTreatment": setChildDirectedTreatment(call, result)
        case "isChildDirectedTreatment": isChildDirectedTreatment(call, result)
        case "setUserId": setUserId(call, result)
        case "getUserId": getUserId(call, result)
        case "setCustomFilter": setCustomFilter(call, result)
        case "setExtraData": setExtraData(call, result)
        case "getPlatformSdkVersion": getPlatformSdkVersion(call, result)
        case "getAvailableNativeAdsCount": getAvailableNativeAdsCount(call, result)
        case "getNativeAd": getNativeAd(call, result)
        // Services logic
        case "logEvent": logEvent(call, result)
        case "validateInAppPurchase": validateInAppPurchase(call, result)
        // Bidon self hosted
        case "setBidonEndpoint": setBidonEndpoint(call, result)
        case "getBidonEndpoint": getBidonEndpoint(call, result)
        default: result(FlutterMethodNotImplemented)
        }
    }
    
    private func setTestMode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        isTestModeEnabled = args["isTestMode"] as! Bool
        Appodeal.setTestingEnabled(isTestModeEnabled)
        result(nil)
    }
    
    private func isTestMode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(isTestModeEnabled)
    }
    
    private func setLogLevel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let logLevel = args["logLevel"] as! Int
        switch logLevel {
        case 1: Appodeal.setLogLevel(APDLogLevel.debug)
        case 2: Appodeal.setLogLevel(APDLogLevel.verbose)
        default: Appodeal.setLogLevel(APDLogLevel.off)
        }
        result(nil)
    }
    
    private func initialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let appKey = args["appKey"] as! String
        let sdkVersion = args["sdkVersion"] as! String
        let types = args["adTypes"] as! Int
        let adTypes = AppodealAdType(rawValue: types)
        Appodeal.setInterstitialDelegate(interstitial.adListener)
        Appodeal.setRewardedVideoDelegate(rewardedVideo.adListener)
        Appodeal.setBannerDelegate(banner.adListener)
        Appodeal.setSmartBannersEnabled(isSmartBannerEnabled)
        Appodeal.setPreferredBannerAdSize(isTabletBannerEnabled ? kAppodealUnitSize_728x90 : kAPDAdSize320x50)
        Appodeal.setFramework(APDFramework.flutter, version: sdkVersion)
        Appodeal.setInitializationDelegate(self)
        Appodeal.initialize(withApiKey: appKey, types: adTypes)
        Appodeal.setAdRevenueDelegate(adRevenueCallback.adListener)
        result(nil)
    }
    
    private func isInitialized(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        result(Appodeal.isInitialized(for: adType))
    }
    
    private func setAutoCache(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        let autoCache = args["isAutoCache"] as! Bool
        Appodeal.setAutocache(autoCache, types: adType)
        result(nil)
    }
    
    private func isAutoCacheEnabled(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        result(Appodeal.isAutocacheEnabled(_: adType))
    }
    
    private func cache(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        Appodeal.cacheAd(adType)
        native.load()
        result(nil)
    }
    
    private func isLoaded(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealShowStyle(rawValue: args["adType"] as! Int)
        result(Appodeal.isReadyForShow(with: adType))
    }
    
    private func isPrecache(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        result(Appodeal.isPrecacheAd(_: adType))
    }
    
    private func canShow(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        let placement = args["placement"] as! String
        result(Appodeal.canShow(adType, forPlacement: placement))
    }
    
    private func getPredictedEcpm(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        result(Appodeal.predictedEcpm(for: adType))
    }
    
    private func show(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let adType = AppodealShowStyle(rawValue: args["adType"] as! Int)
        let placement = args["placement"] as! String
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        result(Appodeal.showAd(adType, forPlacement: placement, rootViewController: rootViewController))
    }
    
    private func hide(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        Appodeal.hideBanner()
        result(nil)
    }
    
    private func setSmartBanners(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        isSmartBannerEnabled = args["isSmartBannersEnabled"] as! Bool
        Appodeal.setSmartBannersEnabled(isSmartBannerEnabled)
        result(nil)
    }
    
    private func isSmartBanners(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(Appodeal.isSmartBannersEnabled())
    }
    
    private func setTabletBanners(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        isTabletBannerEnabled = args["isTabletBannerEnabled"] as! Bool
        Appodeal.setPreferredBannerAdSize(isTabletBannerEnabled ? kAppodealUnitSize_728x90 : kAPDAdSize320x50)
        result(nil)
    }
    
    private func isTabletBanners(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(isTabletBannerEnabled)
    }
    
    private func setBannerAnimation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        isBannerAnimationEnabled = args["isBannerAnimationEnabled"] as! Bool
        Appodeal.setBannerAnimationEnabled(isBannerAnimationEnabled)
        result(nil)
    }
    
    private func isBannerAnimation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(isBannerAnimationEnabled)
    }
    
    private func setBannerRotation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let leftBannerRotation = args["leftBannerRotation"] as! Int
        let rightBannerRotation = args["rightBannerRotation"] as! Int
        Appodeal.setBannerLeftRotationAngleDegrees(CGFloat(leftBannerRotation), rightRotationAngleDegrees: CGFloat(rightBannerRotation))
        result(nil)
    }
    
    private func disableNetwork(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let network = args["network"] as! String
        let adType = AppodealAdType(rawValue: args["adType"] as! Int)
        Appodeal.disableNetwork(for: adType, name: network)
        result(nil)
    }
    
    private func setChildDirectedTreatment(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        isChildDirectedTreatmentEnabled = args["isChildDirectedTreatment"] as! Bool
        Appodeal.setChildDirectedTreatment(isChildDirectedTreatmentEnabled)
        result(nil)
    }
    
    private func isChildDirectedTreatment(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(isChildDirectedTreatmentEnabled)
    }
    
    private func setUserId(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let userId = args["userId"] as! String
        Appodeal.setUserId(userId)
        result(nil)
    }
    
    private func getUserId(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(Appodeal.userId())
    }
    
    private func setCustomFilter(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let key = args["name"] as! String
        let value = args["value"]
        Appodeal.setCustomStateValue(value, forKey: key)
        result(nil)
    }
    
    private func setExtraData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let key = args["key"] as! String
        let value = args["value"]
        Appodeal.setExtrasValue(value, forKey: key)
        result(nil)
    }
    
    private func getPlatformSdkVersion(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(Appodeal.getVersion())
    }

    private func getAvailableNativeAdsCount(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(native.currentAdCount)
    }

    private func getNativeAd(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        // 3. Fetch native ads from the Appodeal SDK
        guard let nativeAd = native.getNativeAd() else {
            // If no ad is available, return nil to Flutter
            result(nil)
            return
        }

        // 4. Build the dictionary to send back to Flutter
        let nativeAdMap: [String: Any?] = [
            "title": nativeAd.title,
            "description": nativeAd.descriptionText,
            "callToAction": nativeAd.callToActionText,
            "rating": nativeAd.starRating,
            "adProvider": nativeAd.contentRating,
            "predictedEcpm": nativeAd.predictedEcpm,
            "isInitialized": Appodeal.isInitialized(for: .nativeAd),
            "isContainsVideo": nativeAd.isContainsVideo,
            "mediaAssets": parseMediaAssetsToMap(nativeAd: nativeAd)
        ]

        native.adChannel.invokeMethod("onLog", arguments: "getNativeAd: \(nativeAdMap)")

        // 5. Return the dictionary as the result
        result(nativeAdMap)
    }

    private func parseMediaAssetsToMap(nativeAd: APDNativeAd) -> [String: [String: Any?]?] {
        var assetsMap: [String: [String: Any?]?] = [:]

        if let icon = nativeAd.iconImage {
            assetsMap["icon"] = [
                "value": icon.url?.absoluteString,
                "width": icon.image?.size.width,
                "height": icon.image?.size.height,
                "type": icon.description // Assuming type is always image for icon
            ]
        }

        if let image = nativeAd.mainImage {
            assetsMap["mainImage"] = [
                "value": image.url?.absoluteString,
                "width": image.image?.size.width,
                "height": image.image?.size.height,
                "type": image.description
            ]
        }

        // Note: APDNativeAd doesn't have a direct video asset property like the Android SDK.
        // Video ads are typically handled through the APDMediaView.
        // If you have a specific way to get video URL, it should be added here.

        return assetsMap
    }
    
    // Services logic
    
    private func logEvent(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let eventName = args["eventName"] as! String
        let params = args["params"] as! [String: Any]
        let maskNumber = args["service"] as? NSNumber

        let analyticsServicesFlag = maskNumber.map {
            APDAnalyticsService(rawValue: UInt($0.uint64Value))
        } ?? []

        Appodeal.trackEvent(eventName,
                            customParameters: params,
                            analytics: analyticsServicesFlag)
        result(nil)
    }
    
    private func validateInAppPurchase(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let type = args["type"] as! Int
        let orderId = args["orderId"] as! String
        let price = args["price"] as! String
        let currency = args["currency"] as! String
        let transactionId = args["transactionId"] as! String
        let additionalParameters = args["additionalParameters"] as! [String: String]
        
        if let purchaseType = APDPurchaseType(rawValue: UInt(type)) {
            Appodeal.validateAndTrack(
                inAppPurchase: orderId,
                type: purchaseType,
                price: price,
                currency: currency,
                transactionId: transactionId,
                additionalParameters: additionalParameters,
                success: { [weak self] _ in
                    self?.channel.invokeMethod("onInAppPurchaseValidateSuccess", arguments: nil)
                },
                failure: { [weak self] error in
                    let args: [String: [String?]] = ["errors": [error?.localizedDescription]]
                    self?.channel.invokeMethod("onInAppPurchaseValidateFail", arguments: args)
                }
            )
        } else {
            channel.invokeMethod("onInAppPurchaseValidateFail", arguments: nil)
        }
        result(nil)
    }

    private func setBidonEndpoint(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let endpoint = args["endpoint"] as! String
        Appodeal.setBidonEndpoint(endpoint)
        result(nil)
    }

    private func getBidonEndpoint(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let endpoint = Appodeal.getBidonEndpoint()
        result(endpoint)
    }
}

private var isTestModeEnabled: Bool = false
private var isSmartBannerEnabled: Bool = false
private var isTabletBannerEnabled: Bool = false
private var isBannerAnimationEnabled: Bool = false
private var isChildDirectedTreatmentEnabled: Bool = false
