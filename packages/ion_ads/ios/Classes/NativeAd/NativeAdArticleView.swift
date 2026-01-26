import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI

final class NativeAdArticleView: UIView {

    private lazy var adChoiceContainer = AdComponents.createAdChoiceView(for: NativeAdArticleView.self)
    private lazy var adTag = AdComponents.createAdTag()
    private lazy var iconImageView = AdComponents.createIconView()
    private lazy var titleTextLabel = AdComponents.createTitleLabel()
    private lazy var descriptionTextLabel = AdComponents.createDescriptionLabel()
    private lazy var callToActionView = AdComponents.createCallToActionLabel()
    private lazy var starRatingView = AdComponents.createRatingLabel()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private lazy var cardBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private lazy var bottomPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.layer.cornerRadius = 12
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        self.clipsToBounds = true
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(mediaContainer)
        addSubview(bottomPanel)

        addSubview(adTag)
        addSubview(adChoiceContainer)

        bottomPanel.addSubview(iconImageView)
        bottomPanel.addSubview(titleTextLabel)
        bottomPanel.addSubview(descriptionTextLabel)
        bottomPanel.addSubview(starRatingView)
        bottomPanel.addSubview(callToActionView)

        [mediaContainer, bottomPanel, adTag, adChoiceContainer, iconImageView, titleTextLabel, descriptionTextLabel, starRatingView, callToActionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Media at top
            mediaContainer.topAnchor.constraint(equalTo: topAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            //mediaContainer.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.56), // Adjust ratio

            // Overlays on Media
            adTag.topAnchor.constraint(equalTo: mediaContainer.topAnchor, constant: 6),
            adTag.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor, constant: 6),
            adTag.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeWidth),
            adTag.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeHeight),

            adChoiceContainer.topAnchor.constraint(equalTo: mediaContainer.topAnchor, constant: 6),
            adChoiceContainer.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -6),
            adChoiceContainer.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeHeight),
            adChoiceContainer.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeHeight),

            // Bottom Panel
            bottomPanel.topAnchor.constraint(equalTo: mediaContainer.bottomAnchor),
            bottomPanel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomPanel.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),

            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: DesignSystem.Dimensions.iconPadding),
            iconImageView.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.iconMedium),
            iconImageView.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.iconMedium),

            // Title
            titleTextLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor, constant: -2),
            titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: DesignSystem.Spacing.medium),
            titleTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -DesignSystem.Spacing.medium),
            
            // --- Description ---
            descriptionTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: -DesignSystem.Spacing.extraSmall),
            descriptionTextLabel.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),
            descriptionTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -DesignSystem.Spacing.medium),

            // Stars
            starRatingView.bottomAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: -DesignSystem.Spacing.extraSmall),
            starRatingView.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),

            // Button
            callToActionView.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -DesignSystem.Dimensions.iconPadding),
            callToActionView.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor),
            callToActionView.widthAnchor.constraint(equalToConstant: 90),
            callToActionView.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.iconMedium)
        ])
    }
}

extension NativeAdArticleView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView }
    func descriptionLabel() -> UILabel { return descriptionTextLabel }
    func mediaContainerView() -> UIView { return mediaContainer }

    func contentRatingLabel() -> UILabel {return starRatingView   }
    func adChoicesView() -> UIView { return adChoiceContainer }
    
    func setRating(_ rating: NSNumber) {
        let numericRating = rating.intValue
        let hasRating = numericRating > 0

        if hasRating {
            starRatingView.text = AdComponents.starString(for: rating)
        }

        starRatingView.isHidden = !hasRating
        descriptionTextLabel.isHidden = hasRating
    }
}
