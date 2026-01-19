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
    
    var adChoiceMargin: Double = 0 {
        didSet {
            setupAdChoiceConstraints()
        }
    }

    private lazy var adChoiceContainer = AdComponents.createAdChoiceView(for: NativeAdStoryView.self)
    private lazy var adTag = AdComponents.createAdTag()
    private lazy var iconImageView = AdComponents.createIconView()
    private lazy var titleTextLabel = AdComponents.createTitleLabel()
    private lazy var descriptionTextLabel = AdComponents.createDescriptionLabel()
    private lazy var callToActionView = AdComponents.createCallToActionLabel()
    private lazy var starRatingView = AdComponents.createRatingLabel()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFit
        return view
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
                adChoiceContainer.topAnchor.constraint(equalTo: topAnchor, constant: padding + adChoiceMargin),
                adChoiceContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                adTag.topAnchor.constraint(equalTo: topAnchor, constant: padding + adChoiceMargin),
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
                adTag.topAnchor.constraint(equalTo: topAnchor, constant: padding + adChoiceMargin),
                adTag.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

                // Ad Choice Icon to the left of the adTag
                adChoiceContainer.topAnchor.constraint(equalTo: topAnchor, constant: padding + adChoiceMargin),
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

    func setRating(_ rating: NSNumber) {
        starRatingView.text = AdComponents.starString(for: rating)
        starRatingView.isHidden = rating.intValue == 0
    }
}
