import UIKit
import Flutter
import Appodeal
import ion_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        Appodeal.registerNativeAdBinder(binderId: "custom",
                                        nativeAdViewBinder: MyCustomNativeAdViewBinder())
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

final class MyCustomNativeAdViewBinder: NSObject, NativeAdViewBinder {
    func bind() -> UIView & APDNativeAdView {
        return NativeAdView()
    }
}

final class NativeAdView: UIView {
    private lazy var adChoiceContainer: UIView = { UIView() }()
    
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
        //        backgroundColor = UIColor.App.secondaryAccent
        layer.cornerRadius = 8
        layoutViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Error")
    }
    
    private func layoutViews() {
        let adTag: UILabel = {
            let label = UILabel()
            label.backgroundColor = UIColor.white
            // label.textColor = UIColor.App.secondaryAccent // Uncomment this line if needed
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
            iconImageView.widthAnchor.constraint(equalToConstant: 70),
            iconImageView.heightAnchor.constraint(equalToConstant: 70),
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

extension NativeAdView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView}
    func descriptionLabel() -> UILabel { return descriptionTextLabel }
    func mediaContainerView() -> UIView { return mediaContainer }
    func adChoicesView() -> UIView { return adChoiceContainer }
}
