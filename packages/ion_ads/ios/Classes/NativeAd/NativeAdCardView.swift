import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI

final class NativeAdCardView: UIView {
    var callToActionPosition: CallToActionPosition = .top {
        didSet {
            setupCallToActionConstraints()
        }
    }
    private lazy var adChoiceContainer = AdComponents.createAdChoiceView(for: NativeAdCardView.self)
    private lazy var adTag = AdComponents.createAdTag()
    private lazy var iconImageView = AdComponents.createIconView()
    private lazy var titleTextLabel = AdComponents.createTitleLabel()
    private lazy var descriptionTextLabel = AdComponents.createDescriptionLabel()
    private lazy var callToActionView = AdComponents.createCallToActionLabel()
    private lazy var starRatingView = AdComponents.createRatingLabel()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
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
        // Add all subviews to the main view
        [
            titleTextLabel,
            descriptionTextLabel,
            cardBackgroundView,
            iconImageView,
            callToActionView,
            adTag,
            adChoiceContainer,
            starRatingView
        ].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // The mediaContainer goes inside the cardBackgroundView
        cardBackgroundView.addSubview(mediaContainer)
        mediaContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // --- (Icon, Title, Description, CTA constraints are mostly unchanged) ---
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            iconImageView.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.iconMedium),
            iconImageView.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.iconMedium),

            titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),

            descriptionTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: -2),
            descriptionTextLabel.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),

            // 3. Adjust layout to make space for the rating view
            starRatingView.topAnchor.constraint(equalTo: descriptionTextLabel.bottomAnchor, constant: 4),
            starRatingView.leadingAnchor.constraint(equalTo: descriptionTextLabel.leadingAnchor),
            starRatingView.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -DesignSystem.Spacing.medium),

            // --- (Media, AdTag, AdChoice constraints are unchanged) ---
            cardBackgroundView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            cardBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            cardBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),

            mediaContainer.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor),
            mediaContainer.bottomAnchor.constraint(equalTo: cardBackgroundView.bottomAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: cardBackgroundView.leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: cardBackgroundView.trailingAnchor),

            adChoiceContainer.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor, constant: 10),
            adChoiceContainer.trailingAnchor.constraint(equalTo: cardBackgroundView.trailingAnchor, constant: -DesignSystem.Spacing.medium),
            adChoiceContainer.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeHeight),
            adChoiceContainer.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeHeight),

            adTag.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor, constant: DesignSystem.Spacing.medium),
            adTag.leadingAnchor.constraint(equalTo: cardBackgroundView.leadingAnchor, constant: DesignSystem.Spacing.medium),
            adTag.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeWidth),
            adTag.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.adBadgeHeight)
        ])
        
        setupCallToActionConstraints()
    }
    
    private func setupCallToActionConstraints() {
        for item in [callToActionView] {
            item.removeFromSuperview()
            addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }
    
        var constraints: [NSLayoutConstraint] = [
            callToActionView.heightAnchor.constraint(equalToConstant: DesignSystem.Dimensions.iconMedium),
            callToActionView.widthAnchor.constraint(equalToConstant: DesignSystem.Dimensions.actionButtonWidth)
        ]

        switch callToActionPosition {
        case .top:
            constraints.append(contentsOf: [
                callToActionView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
                callToActionView.leadingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor, constant: DesignSystem.Spacing.medium),
                callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                
                cardBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0),
                cardBackgroundView.heightAnchor.constraint(equalTo: cardBackgroundView.widthAnchor, multiplier: 9/16.0),
                titleTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),
                titleTextLabel.topAnchor.constraint(equalTo: topAnchor, constant: -2),
                descriptionTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8)
            ])
        case .bottom:
            constraints.append(contentsOf: [
                callToActionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
                callToActionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                
                cardBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: callToActionView.topAnchor, constant: -DesignSystem.Spacing.medium),
                cardBackgroundView.heightAnchor.constraint(equalTo: cardBackgroundView.widthAnchor, multiplier: 9/16.0),
                
                titleTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 0),
                titleTextLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                descriptionTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 0)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }
}

extension NativeAdCardView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView }
    func descriptionLabel() -> UILabel { return descriptionTextLabel }
    func mediaContainerView() -> UIView { return mediaContainer }

    func contentRatingLabel() -> UILabel {return starRatingView   }
    func adChoicesView() -> UIView { return adChoiceContainer }
}
