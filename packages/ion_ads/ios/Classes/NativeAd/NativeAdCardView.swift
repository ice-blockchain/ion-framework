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
    
    private lazy var adChoiceContainer: UIImageView = {
        let imageView = UIImageView()
        let bundle = Bundle(for: NativeAdCardView.self)
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
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = AppFonts.secondaryLabel
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
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
            label.backgroundColor = UIColor.white
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
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            titleTextLabel.topAnchor.constraint(equalTo: topAnchor, constant: -4),
            titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),

            descriptionTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: -2),
            descriptionTextLabel.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor),
            descriptionTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),

            // 3. Adjust layout to make space for the rating view
            starRatingView.topAnchor.constraint(equalTo: descriptionTextLabel.bottomAnchor, constant: 4),
            starRatingView.leadingAnchor.constraint(equalTo: descriptionTextLabel.leadingAnchor),
            starRatingView.trailingAnchor.constraint(lessThanOrEqualTo: callToActionView.leadingAnchor, constant: -8),

//            callToActionView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
//            callToActionView.leadingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor, constant: 10),
//            callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
//            callToActionView.heightAnchor.constraint(equalToConstant: 32),
//            callToActionView.widthAnchor.constraint(equalToConstant: 100),

            // --- (Media, AdTag, AdChoice constraints are unchanged) ---
            cardBackgroundView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            cardBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            cardBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            //cardBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0),
            //cardBackgroundView.heightAnchor.constraint(equalTo: cardBackgroundView.widthAnchor, multiplier: 10.0/16.0),

            mediaContainer.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor),
            mediaContainer.bottomAnchor.constraint(equalTo: cardBackgroundView.bottomAnchor),
            mediaContainer.leadingAnchor.constraint(equalTo: cardBackgroundView.leadingAnchor),
            mediaContainer.trailingAnchor.constraint(equalTo: cardBackgroundView.trailingAnchor),

            adChoiceContainer.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor, constant: 10),
            adChoiceContainer.trailingAnchor.constraint(equalTo: cardBackgroundView.trailingAnchor, constant: -8),
            adChoiceContainer.widthAnchor.constraint(equalToConstant: 18),
            adChoiceContainer.heightAnchor.constraint(equalToConstant: 18),

            adTag.topAnchor.constraint(equalTo: cardBackgroundView.topAnchor, constant: 8),
            adTag.leadingAnchor.constraint(equalTo: cardBackgroundView.leadingAnchor, constant: 8),
            adTag.widthAnchor.constraint(equalToConstant: 27),
            adTag.heightAnchor.constraint(equalToConstant: 18)
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
            callToActionView.heightAnchor.constraint(equalToConstant: 32),
            callToActionView.widthAnchor.constraint(equalToConstant: 100)
        ]

        let padding: CGFloat = 8.0

        switch callToActionPosition {
        case .top:
            constraints.append(contentsOf: [
                callToActionView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
                callToActionView.leadingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor, constant: padding),
                callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                
                cardBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: 0),
                cardBackgroundView.heightAnchor.constraint(equalTo: cardBackgroundView.widthAnchor, multiplier: 10.0/16.0),
            ])
        case .bottom:
            constraints.append(contentsOf: [
                callToActionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
                callToActionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                callToActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                
                cardBackgroundView.bottomAnchor.constraint(lessThanOrEqualTo: callToActionView.topAnchor, constant: -padding),
                cardBackgroundView.heightAnchor.constraint(equalTo: cardBackgroundView.widthAnchor, multiplier: 16.0/9.0),
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

    //    static func nib() -> UINib {
    //            //return UINib.init(nibName: "Native", bundle: Bundle.main)
    //        }
}
