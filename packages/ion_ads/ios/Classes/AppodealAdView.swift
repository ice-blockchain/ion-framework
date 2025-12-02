import Appodeal
import Flutter
import Foundation

internal final class AppodealAdView: NSObject, FlutterPlatformView {
    
    private let frame: CGRect
    private let viewId: Int64
    private let args: [String: Any]
    private let listener: Listener
    
    private var adView: APDBannerView?
    
    init(frame: CGRect,
         viewId: Int64,
         args: [String: Any],
         mrecChannel: FlutterMethodChannel,
         bannerChannel: FlutterMethodChannel) {
        self.frame = frame
        self.viewId = viewId
        self.args = args
        listener = Listener(mrecChannel: mrecChannel, bannerChannel: bannerChannel)
    }
    
    func view() -> UIView {
        getOrSetupBannerAdView()
    }
    
    func dispose() {}
    
    private func getOrSetupBannerAdView() -> APDBannerView {
        if let adView = adView {
            return adView
        }
        let adView: APDBannerView!
        if (adSize == kAPDAdSize320x50) {
            adView = APDBannerView(size: adSize)
        } else if (adSize == kAPDAdSize300x250) {
            adView = APDMRECView(size: adSize)
        } else {
            assertionFailure("Banner type doesn't support")
            adView = APDBannerView(size: adSize)
        }
        self.adView = adView
        adView.delegate = listener
        adView.rootViewController = UIApplication.shared.keyWindow?.rootViewController
        adView.frame = frame.width == 0 ? CGRect(x: 0, y: 0, width: 1, height: 1) : frame
        adView.placement = args["placement"] as? String ?? "default"
        adView.autocache = Appodeal.isAutocacheEnabled(AppodealAdType.banner)
        adView.usesSmartSizing = false
        adView.loadAd()
        return adView
    }
    
    private var adSize: CGSize {
        let adSize = args["adSize"] as! [String: Any]
        let adSizeName = adSize["name"] as! String
        switch adSizeName {
        case "BANNER":
            return kAPDAdSize320x50
        case "MEDIUM_RECTANGLE":
            return kAPDAdSize300x250
        default:
            assertionFailure("Banner type doesn't support")
        }
        let width = adSize["width"] as? Int ?? 0
        let height = adSize["height"] as? Int ?? 0
        return CGSize(width: width, height: height)
    }
    
    private final class Listener: NSObject, APDBannerViewDelegate {
        
        private let mrecChannel: FlutterMethodChannel
        private let bannerChannel: FlutterMethodChannel
        
        fileprivate init(mrecChannel: FlutterMethodChannel,
                         bannerChannel: FlutterMethodChannel) {
            self.mrecChannel = mrecChannel
            self.bannerChannel = bannerChannel
        }
        
        func bannerViewDidLoadAd(_ bannerView: APDBannerView, isPrecache precache: Bool) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                mrecChannel.invokeMethod("onMrecLoaded", arguments: ["isPrecache": precache])
            } else {
                bannerChannel.invokeMethod("onBannerLoaded", arguments: ["isPrecache": precache])
            }
        }
        
        func bannerView(_ bannerView: APDBannerView, didFailToLoadAdWithError error: Error) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                mrecChannel.invokeMethod("onMrecFailedToLoad", arguments: nil)
            } else {
                bannerChannel.invokeMethod("onBannerFailedToLoad", arguments: nil)
            }
        }
        
        func bannerViewDidShow(_ bannerView: APDBannerView) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                mrecChannel.invokeMethod("onMrecShown", arguments: nil)
            } else {
                bannerChannel.invokeMethod("onBannerShown", arguments: nil)
            }
        }
        
        func bannerViewExpired(_ bannerView: APDBannerView) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                mrecChannel.invokeMethod("onMrecExpired", arguments: nil)
            } else {
                bannerChannel.invokeMethod("onBannerClicked", arguments: nil)
            }
        }
        
        func bannerViewDidInteract(_ bannerView: APDBannerView) {
            if (bannerView.adSize == kAPDAdSize300x250) {
                mrecChannel.invokeMethod("onMrecClicked", arguments: nil)
            } else {
                bannerChannel.invokeMethod("onBannerClicked", arguments: nil)
            }
        }
    }
}
