import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI

final class NativeAdChatListView: UIView {
    private lazy var adChoiceContainer: UIImageView = {
        let imageView = UIImageView()
        let bundle = Bundle(for: NativeAdChatListView.self)
        imageView.image = UIImage(named: "ad_choices", in: bundle, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.App.cardBackground

        return imageView
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.App.secondaryBackground
        imageView.layer.cornerRadius = 14
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
        label.numberOfLines = 2
        label.textAlignment = .left

        return label
    }()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var callToActionView: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.App.accent
        label.textColor = .clear
        label.textAlignment = .center
        label.font = AppFonts.secondaryLabel
        label.layer.cornerRadius = 10
        label.clipsToBounds = true

        let icon = UIImageView()
        let bundle = Bundle(for: NativeAdChatListView.self)
        icon.image = UIImage(named: "ad_download", in: bundle, compatibleWith: nil)
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        label.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: label.centerYAnchor, constant: -2),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])

        return label
    }()

    private lazy var cardBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private lazy var starRatingView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = AppFonts.primaryLabel
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
        let adTag: UILabel = {
            let label = UILabel()
            label.backgroundColor = UIColor.App.cardBackground
            label.textColor = UIColor.App.text
            label.textAlignment = .center
            label.font = AppFonts.caption3
            label.layer.cornerRadius = 6
            label.clipsToBounds = true

            label.text = "Ad"
            return label
        }()

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
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),

            titleTextLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),

            adChoiceContainer.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 0),
            adChoiceContainer.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),
            adChoiceContainer.widthAnchor.constraint(equalToConstant: 18),
            adChoiceContainer.heightAnchor.constraint(equalToConstant: 18),

            adTag.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 0),
            adTag.leadingAnchor.constraint(equalTo: adChoiceContainer.trailingAnchor, constant: 4),
            adTag.widthAnchor.constraint(equalToConstant: 27),
            adTag.heightAnchor.constraint(equalToConstant: 18),

            descriptionTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 0),
            descriptionTextLabel.leadingAnchor.constraint(equalTo: adTag.trailingAnchor, constant: 4),
            descriptionTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),

            // 3. Adjust layout to make space for the rating view
            starRatingView.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 0),
            starRatingView.leadingAnchor.constraint(equalTo: adTag.trailingAnchor, constant: 4),
            starRatingView.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),

            callToActionView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            // callToActionView.leadingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor, constant: 10),
            callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            callToActionView.heightAnchor.constraint(equalToConstant: 32),
            callToActionView.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}

extension NativeAdChatListView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView }
    func descriptionLabel() -> UILabel { return descriptionTextLabel }

    func contentRatingLabel() -> UILabel { return starRatingView }
    func adChoicesView() -> UIView { return adChoiceContainer }
}
