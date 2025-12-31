import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI

final class NativeAdStoryView: UIView {
    var adChoicePosition: AdChoicePosition = .startTop {
        didSet {
            setupAdChoiceConstraints()
        }
    }

    private lazy var adChoiceContainer: UIImageView = {
        let imageView = UIImageView()
        let bundle = Bundle(for: NativeAdStoryView.self)
        imageView.image = UIImage(named: "ad_choices", in: bundle, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear

        return imageView
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.App.secondaryBackground
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true

        return imageView
    }()

    private lazy var titleTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = AppFonts.header
        label.textAlignment = .left

        return label
    }()

    private lazy var descriptionTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = AppFonts.primaryLabel
        label.numberOfLines = 1
        label.textAlignment = .left

        return label
    }()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var callToActionView: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.App.accent
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = AppFonts.secondaryLabel
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.9)
        view.layer.cornerRadius = 14
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3 // Adjust for darkness (0.0 - 1.0)
        view.layer.shadowOffset = CGSize(width: 0, height: -2) // Negative height moves shadow up
        view.layer.shadowRadius = 4 // Adjust for blurriness
        view.clipsToBounds = true
        return view
    }()

    private lazy var starRatingView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = AppFonts.primaryLabel
        return label
    }()

    private lazy var adTag: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.App.text
        label.textAlignment = .center
        label.font = AppFonts.caption3
        label.layer.cornerRadius = 6
        label.clipsToBounds = true

        label.text = "Ad"
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        AppFonts.loadFonts()

        layoutViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Error")
    }

    private func layoutViews() {
        // 1. Add mediaContainer first so it's the background
        addSubview(mediaContainer)
        mediaContainer.translatesAutoresizingMaskIntoConstraints = false

        // 2. Add the bottom container
        addSubview(bottomContainerView)
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false

        // 3. Add content elements inside the bottom container
        [
            iconImageView,
            titleTextLabel,
            descriptionTextLabel,
            callToActionView,
            starRatingView
        ].forEach {
            bottomContainerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // 4. Add overlays (AdTag, AdChoices) to the main view (on top of media)
//        for item in [adTag, adChoiceContainer] {
//            addSubview(item)
//            item.translatesAutoresizingMaskIntoConstraints = false
//        }

        NSLayoutConstraint.activate([
            // --- Media Container (Fullscreen) ---
            mediaContainer.topAnchor.constraint(equalTo: topAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            mediaContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            // --- Bottom Container ---
            bottomContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bottomContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bottomContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            // No fixed height, let content dictate it + padding

            // --- Icon ---
            iconImageView.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 12),
            iconImageView.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            // Constrain bottom of container to be at least below icon + padding
            bottomContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: iconImageView.bottomAnchor, constant: 12),

            // --- Title ---
            titleTextLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleTextLabel.trailingAnchor.constraint(equalTo: callToActionView.leadingAnchor, constant: -8),

            // --- Description ---
            descriptionTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 2),
            descriptionTextLabel.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),
            descriptionTextLabel.trailingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor),

            // --- Star Rating ---
            starRatingView.topAnchor.constraint(equalTo: descriptionTextLabel.bottomAnchor, constant: 4),
            starRatingView.leadingAnchor.constraint(equalTo: descriptionTextLabel.leadingAnchor),
            // Ensure bottom container wraps this content
            bottomContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: descriptionTextLabel.bottomAnchor, constant: 12),

            // --- Call to Action Button ---
            callToActionView.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor), // Center vertically in the panel
            callToActionView.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -12),
            callToActionView.widthAnchor.constraint(equalToConstant: 100),
            callToActionView.heightAnchor.constraint(equalToConstant: 36)
        ])

        setupAdChoiceConstraints()
    }

    private func setupAdChoiceConstraints() {
        for item in [adTag, adChoiceContainer] {
            item.removeFromSuperview()
            addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Remove from superview to clear constraints held by superview (positioning)
//        adChoiceContainer.removeFromSuperview()
//        adTag.removeFromSuperview()
//
//        // Re-add to view hierarchy
//        addSubview(adChoiceContainer)
//        addSubview(adTag)
//
//        adChoiceContainer.translatesAutoresizingMaskIntoConstraints = false
//        adTag.translatesAutoresizingMaskIntoConstraints = false

//        adChoiceContainer.removeConstraints(adChoiceContainer.constraints)
//        adTag.removeConstraints(adTag.constraints)

        var constraints: [NSLayoutConstraint] = [
            adChoiceContainer.widthAnchor.constraint(equalToConstant: 18),
            adChoiceContainer.heightAnchor.constraint(equalToConstant: 18),
            adTag.widthAnchor.constraint(equalToConstant: 27),
            adTag.heightAnchor.constraint(equalToConstant: 18)
        ]

        let padding: CGFloat = 18.0
        let margin: CGFloat = 8.0

        switch adChoicePosition {
        case .startTop:
            constraints.append(contentsOf: [
                adChoiceContainer.topAnchor.constraint(equalTo: topAnchor, constant: padding),
                adChoiceContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                adTag.topAnchor.constraint(equalTo: topAnchor, constant: padding),
                adTag.leadingAnchor.constraint(equalTo: adChoiceContainer.trailingAnchor, constant: margin)
            ])
        case .startBottom:
            constraints.append(contentsOf: [
                adChoiceContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
                adChoiceContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding)
            ])
        case .endTop:
            constraints.append(contentsOf: [
                // AdTag in Top Right corner
                adTag.topAnchor.constraint(equalTo: topAnchor, constant: padding),
                adTag.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

                // Ad Choice Icon to the left of the adTag
                adChoiceContainer.topAnchor.constraint(equalTo: topAnchor, constant: padding),
                adChoiceContainer.trailingAnchor.constraint(equalTo: adTag.leadingAnchor, constant: -margin)
            ])
        case .endBottom:
            constraints.append(contentsOf: [
                adChoiceContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
                adChoiceContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }
}

extension NativeAdStoryView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView }
    func descriptionLabel() -> UILabel { return descriptionTextLabel }
    func mediaContainerView() -> UIView { return mediaContainer }
    func contentRatingLabel() -> UILabel { return starRatingView }
    func adChoicesView() -> UIView { return adChoiceContainer }
}
