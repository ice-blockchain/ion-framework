import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI


final class AppodealNativeAdView: NSObject, FlutterPlatformView {
    private let nativeAdChannel: FlutterMethodChannel
    private let frame: CGRect
    private let viewId: Int64
    private let args: [String: Any]

    private var containerView: UIView
    private var nativeAdQueue: APDNativeAdQueue!
    private var nativeArray: [APDNativeAd] = []

    private let category = "AppodealNativeAdView"

    init(nativeAdChannel: FlutterMethodChannel, frame: CGRect, viewId: Int64, args: [String: Any]) {
        self.frame = frame
        self.viewId = viewId
        self.args = args
        self.nativeAdChannel = nativeAdChannel

        self.containerView = UIView(frame: frame)
        super.init()

        logToFlutter("Initializing with frame: \(frame.debugDescription)")
        loadAndPrepareAd()
    }
    
    func logToFlutter(_ message: String) {
        nativeAdChannel.invokeMethod("onLog", arguments: message)
    }

    func view() -> UIView {
        return containerView
    }

    private func loadAndPrepareAd() {
        let placement = args["placement"] as? String ?? "default"
        logToFlutter("Loading ad for placement: \(placement)")

        // Setup the ad queue
        nativeAdQueue = APDNativeAdQueue()
        nativeAdQueue.settings = APDNativeAdSettings.default()
        nativeAdQueue.settings.adViewClass = NativeAdCardView.self
        nativeAdQueue.settings.autocacheMask = [.icon, .media]
        nativeAdQueue.settings.type = .auto
        nativeAdQueue.delegate = self

        nativeAdQueue.loadAd()
    }

//    private func getOrSetupNativeAdView() -> UIView {
//        let options = args["options"] as? [String: Any] ?? [:]
//        let placement = args["placement"] as? String ?? "default"
//        let nativeAdType = options["nativeAdType"] as? Int ?? -1
//        let binderId = options["binderId"] as? String ?? "custom"
//
//        return NativeView()

//        if let binder = nativeAdViewBinders[binderId] {
//            return binder.bind()
//        } else {
//            print("Native Ad type doesn't support or missing options: \(options), placement: \(placement), nativeAdType: \(nativeAdType), nativeAdViewBinders: \(nativeAdViewBinders)")
//            return NativeView()
//        }
//    }

    private func setupAdView() {
        guard let nativeAd = nativeArray.first else {
            logToFlutter("Error: setupAdView called but no ad is available in the array.")
            return
        }
        logToFlutter("Setting up ad view...")
        nativeAd.delegate = self

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            logToFlutter("Error: Could not get rootViewController.")
            return
        }

        do {
            // Get the ad view from the SDK, configured with our NativeView class.
            let adView = try nativeAd.getViewForPlacement("default", withRootViewController: rootViewController)
            logToFlutter("Successfully created native ad view.")

            adView.frame = containerView.bounds
            containerView.addSubview(adView)
        } catch {
            logToFlutter("Error getting native ad view: \(error.localizedDescription)")
        }
    }

    func dispose() {
        logToFlutter("Dispose called. Cleaning up resources.")

        // Clean up resources
        containerView.subviews.forEach { $0.removeFromSuperview() }
        nativeArray.removeAll()
    }
}

extension AppodealNativeAdView: APDNativeAdQueueDelegate, APDNativeAdPresentationDelegate {
    func adQueueAdIsAvailable(_ adQueue: APDNativeAdQueue, ofCount count: UInt) {
        guard nativeArray.isEmpty else { return }

        let ads = adQueue.getNativeAds(ofCount: 1)
        if !ads.isEmpty {
            logToFlutter("Successfully retrieved 1 ad from the queue.")
            nativeArray.append(contentsOf: ads)
            // Now that the ad data is available, create and display the view on the main thread.
            DispatchQueue.main.async {
                self.setupAdView()
            }
        }
    }

    func adQueueDidFail(toLoadAd adQueue: APDNativeAdQueue) {
        logToFlutter("Native ad queue failed to load ad.")
    }
}
