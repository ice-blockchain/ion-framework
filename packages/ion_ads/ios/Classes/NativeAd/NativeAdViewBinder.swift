import Appodeal

/**
 Protocol for a native ad view binder.
 
 A type conforming to this protocol is responsible for binding native ad views.
 */
@objc public protocol NativeAdViewBinder {
    func bind() -> (UIView & APDNativeAdView)
}
