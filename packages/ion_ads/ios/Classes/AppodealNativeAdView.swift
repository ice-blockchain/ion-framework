import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI

enum CompatibleLogger {
    private static let subsystem = "com.ion.ads"

    static func log(_ message: String, category: String) {
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: subsystem, category: category)
            logger.log("\(message)")
        } else {
            os_log("%@", log: OSLog(subsystem: subsystem, category: category), type: .default, message)
        }
    }

    static func error(_ message: String, category: String) {
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: subsystem, category: category)
            logger.error("\(message)")
        } else {
            os_log("%@", log: OSLog(subsystem: subsystem, category: category), type: .error, message)
        }
    }
}

final class AppodealNativeAdView: NSObject, FlutterPlatformView {
    private let frame: CGRect
    private let viewId: Int64
    private let args: [String: Any]

    private var containerView: UIView
    private var nativeAdQueue: APDNativeAdQueue!
    private var nativeArray: [APDNativeAd] = []

    private let category = "AppodealNativeAdView"

    init(frame: CGRect, viewId: Int64, args: [String: Any]) {
        self.frame = frame
        self.viewId = viewId
        self.args = args

        self.containerView = UIView(frame: frame)
        super.init()

        CompatibleLogger.log("Initializing with frame: \(frame.debugDescription)", category: category)
        loadAndPrepareAd()
    }

    func view() -> UIView {
        return containerView
    }

    private func loadAndPrepareAd() {
        let placement = args["placement"] as? String ?? "default"
        CompatibleLogger.log("Loading ad for placement: \(placement)", category: category)

        // Setup the ad queue
        nativeAdQueue = APDNativeAdQueue()
        nativeAdQueue.settings = APDNativeAdSettings.default()
        nativeAdQueue.settings.adViewClass = NativeView.self
        nativeAdQueue.settings.autocacheMask = [.icon, .media]
        nativeAdQueue.settings.type = .auto
        nativeAdQueue.delegate = self

        nativeAdQueue.loadAd()
    }

    private func getOrSetupNativeAdView() -> UIView {
        let options = args["options"] as? [String: Any] ?? [:]
        let placement = args["placement"] as? String ?? "default"
        let nativeAdType = options["nativeAdType"] as? Int ?? -1
        let binderId = options["binderId"] as? String ?? "custom"

        return NativeView()

//        if let binder = nativeAdViewBinders[binderId] {
//            return binder.bind()
//        } else {
//            print("Native Ad type doesn't support or missing options: \(options), placement: \(placement), nativeAdType: \(nativeAdType), nativeAdViewBinders: \(nativeAdViewBinders)")
//            return NativeView()
//        }
    }

    private func setupAdView() {
        guard let nativeAd = nativeArray.first else {
            CompatibleLogger.error("Error: setupAdView called but no ad is available in the array.", category: category)
            return
        }
        CompatibleLogger.log("Setting up ad view...", category: category)
        nativeAd.delegate = self

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            CompatibleLogger.error("Error: Could not get rootViewController.", category: category)
            return
        }

        do {
            // Get the ad view from the SDK, configured with our NativeView class.
            let adView = try nativeAd.getViewForPlacement("default", withRootViewController: rootViewController)
            CompatibleLogger.log("Successfully created native ad view.", category: category)

            adView.frame = containerView.bounds
            containerView.addSubview(adView)
        } catch {
            CompatibleLogger.error("Error getting native ad view: \(error.localizedDescription)", category: category)
        }
    }

    func dispose() {
        CompatibleLogger.log("Dispose called. Cleaning up resources.", category: category)

        // Clean up resources
        containerView.subviews.forEach { $0.removeFromSuperview() }
        nativeArray.removeAll()
    }
}

extension AppodealNativeAdView: APDNativeAdQueueDelegate, APDNativeAdPresentationDelegate {
    func adQueueAdIsAvailable(_ adQueue: APDNativeAdQueue, ofCount count: UInt) {
        CompatibleLogger.log("Ad queue has \(count) ad(s) available.", category: category)
        guard nativeArray.isEmpty else { return }

        let ads = adQueue.getNativeAds(ofCount: 1)
        if !ads.isEmpty {
            CompatibleLogger.log("Successfully retrieved 1 ad from the queue.", category: category)
            nativeArray.append(contentsOf: ads)
            // Now that the ad data is available, create and display the view on the main thread.
            DispatchQueue.main.async {
                self.setupAdView()
            }
        }
    }

    func adQueueDidFail(toLoadAd adQueue: APDNativeAdQueue) {
        CompatibleLogger.error("Native ad queue failed to load ad.", category: category)
    }
}

final class NativeView: UIView {
    private lazy var adChoiceContainer: UIView = .init()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.App.secondaryBackground
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private lazy var titleTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.App.header
        label.textAlignment = .center
        return label
    }()

    private lazy var descriptionTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.App.primaryLabel
        label.numberOfLines = 3
        return label
    }()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private lazy var callToActionView: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.App.accent
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.layer.cornerRadius = 8
        label.layer.shadowColor = UIColor.App.accent.cgColor
        label.layer.shadowRadius = 5
        label.layer.shadowOpacity = 0.35
        label.layer.shadowOffset = .zero
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.App.secondaryAccent
        layer.cornerRadius = 8
        layoutViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Error")
    }

    private func layoutViews() {
        let adTag: UILabel = {
            let label = UILabel()
            label.backgroundColor = UIColor.white
            label.textColor = UIColor.App.text
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            label.text = "Ad"
            return label
        }()

        [
            titleTextLabel,
            descriptionTextLabel,
            mediaContainer,
            iconImageView,
            callToActionView,
            adChoiceContainer,
            adTag
        ].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Icon
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            // Ad tag
            adTag.widthAnchor.constraint(equalToConstant: 24),
            adTag.heightAnchor.constraint(equalToConstant: 18),
            adTag.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            adTag.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            // Title
            titleTextLabel.heightAnchor.constraint(equalTo: iconImageView.heightAnchor),
            titleTextLabel.leftAnchor.constraint(equalTo: iconImageView.rightAnchor, constant: -8),
            titleTextLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            titleTextLabel.rightAnchor.constraint(equalTo: rightAnchor),
            // Media view
            mediaContainer.widthAnchor.constraint(equalTo: widthAnchor, constant: -16),
            mediaContainer.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 9 / 16, constant: -9),
            mediaContainer.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            mediaContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            // Description
            descriptionTextLabel.topAnchor.constraint(equalTo: mediaContainer.bottomAnchor, constant: 8),
            descriptionTextLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            descriptionTextLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            // Call to action label
            callToActionView.widthAnchor.constraint(equalToConstant: 120),
            callToActionView.heightAnchor.constraint(equalToConstant: 33),
            callToActionView.topAnchor.constraint(equalTo: descriptionTextLabel.bottomAnchor, constant: 8),
            callToActionView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            callToActionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            // Ad Choice
            adChoiceContainer.heightAnchor.constraint(equalToConstant: 24),
            adChoiceContainer.widthAnchor.constraint(equalToConstant: 24),
            adChoiceContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            adChoiceContainer.leftAnchor.constraint(equalTo: leftAnchor, constant: 8)
        ])
    }
}

extension NativeView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView }
    func descriptionLabel() -> UILabel { return descriptionTextLabel }
    func mediaContainerView() -> UIView { return mediaContainer }
    func adChoicesView() -> UIView { return adChoiceContainer }

//    static func nib() -> UINib {
//            //return UINib.init(nibName: "Native", bundle: Bundle.main)
//        }
}
