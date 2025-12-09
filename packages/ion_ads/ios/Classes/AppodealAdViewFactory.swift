import Flutter
import Foundation
import Appodeal

internal class AppodealAdViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private let bannerChannel: FlutterMethodChannel
    private let mrecChannel: FlutterMethodChannel
    
    internal init(mrecChannel: FlutterMethodChannel, bannerChannel: FlutterMethodChannel) {
        self.mrecChannel = mrecChannel
        self.bannerChannel = bannerChannel
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        AppodealAdView(
            frame: frame,
            viewId: viewId,
            args: args as? [String: Any] ?? [:],
            mrecChannel: mrecChannel,
            bannerChannel: bannerChannel
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

internal class AppodealNativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private let nativeAdChannel: FlutterMethodChannel
    
    internal init(nativeAdChannel: FlutterMethodChannel) {
        self.nativeAdChannel = nativeAdChannel
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        AppodealNativeAdView(
            nativeAdChannel: nativeAdChannel,
            frame: frame,
            viewId: viewId,
            args: args as? [String: Any] ?? [:]
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}
