import SwiftUI
import UIKit

enum AdComponents {

    /// The small "Ad" badge
    static func createAdTag() -> UILabel {
        let label = UILabel()
        label.backgroundColor = .white
        label.textColor = UIColor.App.text
        label.textAlignment = .center
        label.font = AppFonts.adTag
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.text = "Ad"
        
        return label
    }

    /// Reusable Title Label
    static func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.darkText
        label.font = AppFonts.header
        label.textAlignment = .left
        return label
    }

    /// Reusable Description/Body Label
    static func createDescriptionLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = AppFonts.primaryLabel
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }

    /// Reusable Icon View
    static func createIconView(radius: CGFloat = 8) -> UIImageView {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.App.secondaryBackground
        imageView.layer.cornerRadius = radius
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    /// Reusable Star Rating Label
    static func createRatingLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.App.onTertiaryBackground
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }

    /// Helper to generate stars string
    static func starString(for rating: NSNumber) -> String {
        let numericRating = rating.intValue
        let fullStars = String(repeating: "★", count: numericRating)
        let emptyStars = String(repeating: "☆", count: max(0, 5 - numericRating))
        return fullStars + emptyStars
    }

    /// Reusable Ad Choices Icon View
    static func createAdChoiceView(for classType: AnyClass, backgroundColor: UIColor? = .clear) -> UIImageView {
        let imageView = UIImageView()
        let bundle = Bundle(for: classType)
        imageView.image = UIImage(named: "ad_choices", in: bundle, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = backgroundColor
        return imageView
    }

    /// Reusable Call to Action (Button-like) Label
    static func createCallToActionLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = UIColor.App.accent
        label.textColor = .white
        label.textAlignment = .center
        label.font = AppFonts.secondaryLabel
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }
}
