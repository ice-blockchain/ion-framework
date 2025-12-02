import Appodeal
import Flutter
import Foundation

internal final class AppodealNativeAdView: NSObject, FlutterPlatformView {
    
    private let frame: CGRect
    private let viewId: Int64
    private let args: [String: Any]
    
    private var nativeAdView: UIView?
    
    init(frame: CGRect,viewId: Int64,args: [String: Any]) {
        self.frame = frame
        self.viewId = viewId
        self.args = args
    }
    
    func view() -> UIView {
        getOrSetupNativeAdView()
    }
    
    private func getOrSetupNativeAdView() -> UIView {
        if let nativeAdView = nativeAdView {
            return nativeAdView
        }

        let options = args["options"] as? [String: Any] ?? [:]
        let placement = args["placement"] as? String ?? "default"
        let nativeAdType = options["nativeAdType"] as? Int ?? -1
        let binderId = options["binderId"] as? String ?? "custom"
        
    
        print("GetOrSetupNativeAdView options: \(options), placement: \(placement), nativeAdType: \(nativeAdType), nativeAdViewBinders: \(nativeAdViewBinders)")

        if let binder = nativeAdViewBinders["custom"] {
            return binder.bind()
        } else {
            print("Native Ad type doesn't support or missing options: \(options), placement: \(placement), nativeAdType: \(nativeAdType), nativeAdViewBinders: \(nativeAdViewBinders)")
            return UIView()
        }
    }
    
    func dispose() {
        nativeAdView = nil
    }
}
