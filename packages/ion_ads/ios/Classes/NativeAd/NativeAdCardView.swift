import Appodeal
import Flutter
import Foundation
import os.log
import SwiftUI
import SwiftSVG

final class NativeAdCardView: UIView {
    private lazy var adChoiceContainer: UIImageView = {
        let imageView = UIImageView()
        let bundle = Bundle(for: NativeAdCardView.self)
        
        if let svgUrl = bundle.url(forResource: "ad_choices", withExtension: "svg") {
            do {
                let svgData = try Data(contentsOf: svgUrl)
                imageView.image = UIImage(data: svgData)
            } catch {
                print("Error loading SVG: \(error)")
                if #available(iOS 13.0, *) {
                    imageView.image = UIImage(systemName: "info.circle")
                }
            }
        }

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .lightGray
        imageView.backgroundColor = UIColor.white
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true

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
        label.font = UIFont.App.header
        label.textAlignment = .left

        return label
    }()

    private lazy var descriptionTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.App.primaryLabel
        label.numberOfLines = 2
        label.textAlignment = .left

        return label
    }()

    private lazy var mediaContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9
        view.clipsToBounds = true
        return view
    }()

    private lazy var callToActionView: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.App.accent
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private lazy var cardBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9
        view.clipsToBounds = true
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private lazy var starRatingView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 12)
        // The SDK will automatically hide this if there's no rating, so we don't need to.
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

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
            label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
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
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            titleTextLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),

            descriptionTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor),
            descriptionTextLabel.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),
            descriptionTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),

            // 3. Adjust layout to make space for the rating view
            starRatingView.topAnchor.constraint(equalTo: descriptionTextLabel.bottomAnchor, constant: 4),
            starRatingView.leadingAnchor.constraint(equalTo: descriptionTextLabel.leadingAnchor),
            starRatingView.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),

            callToActionView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            callToActionView.leadingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor, constant: 10),
            callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            callToActionView.heightAnchor.constraint(equalToConstant: 33),
            callToActionView.widthAnchor.constraint(equalToConstant: 120),

            // --- (Media, AdTag, AdChoice constraints are unchanged) ---
            cardBackgroundView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 0),
            cardBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            cardBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            cardBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0),
            cardBackgroundView.heightAnchor.constraint(equalTo: cardBackgroundView.widthAnchor, multiplier: 9.0/16.0),

            mediaContainer.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor),
            mediaContainer.bottomAnchor.constraint(equalTo: cardBackgroundView.bottomAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: cardBackgroundView.leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: cardBackgroundView.trailingAnchor),

            adChoiceContainer.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor, constant: 8),
            adChoiceContainer.trailingAnchor.constraint(equalTo: cardBackgroundView.trailingAnchor, constant: -8),
            adChoiceContainer.widthAnchor.constraint(equalToConstant: 18),
            adChoiceContainer.heightAnchor.constraint(equalToConstant: 18),

            adTag.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor, constant: 8),
            adTag.leadingAnchor.constraint(equalTo: cardBackgroundView.leadingAnchor, constant: 8),
            adTag.widthAnchor.constraint(equalToConstant: 27),
            adTag.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
}

extension NativeAdCardView: APDNativeAdView {
    func titleLabel() -> UILabel { return titleTextLabel }
    func iconView() -> UIImageView { return iconImageView }
    func callToActionLabel() -> UILabel { return callToActionView }
    func descriptionLabel() -> UILabel { return descriptionTextLabel }
    func mediaContainerView() -> UIView { return mediaContainer }

    func contentRatingLabel() -> UILabel {return starRatingView   }


    //    static func nib() -> UINib {
    //            //return UINib.init(nibName: "Native", bundle: Bundle.main)
    //        }
}
