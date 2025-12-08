import UIKit

extension UIColor {
    public convenience init?(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        guard hexSanitized.count == 6 else {
            return nil
        }

        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }

    struct App {
        static let accent = UIColor(hex: "#0166FF")!
        static let secondaryAccent = UIColor.white //  UIColor(named: "StackSecondaryColor")
        static let text = UIColor.darkText // UIColor(named: "StackTextColor")
        
        static var tableBackground: UIColor {
            if #available(iOS 13, *) {
                return .secondarySystemBackground
            } else {
                return .groupTableViewBackground
            }
        }
        
        static var cellBackground: UIColor {
            if #available(iOS 13, *) {
                return .tertiarySystemBackground
            } else {
                return .white
            }
        }
        
        static var green: UIColor {
            if #available(iOS 13, *) {
                return .systemGreen
            } else {
                return .green
            }
        }
        
        static var red: UIColor {
            if #available(iOS 13, *) {
                return .systemRed
            } else {
                return .red
            }
        }
        
        static var background: UIColor {
            if #available(iOS 13, *) {
                return .systemBackground
            } else {
                return .white
            }
        }
        
        static var secondaryBackground: UIColor {
            if #available(iOS 13, *) {
                return .tertiarySystemBackground
            } else {
                return .lightGray
            }
        }
        
        static var label: UIColor {
            return UIColor.App.text
        }
        
        static var secondaryLabel: UIColor {
            if #available(iOS 13, *) {
                return UIColor.secondaryLabel
            } else {
                return UIColor.lightText
            }
        }
    }
}


extension UIFont {
    struct App {
        static let largeTitle = UIFont.systemFont(ofSize: 22, weight: .heavy)
        static let title = UIFont.systemFont(ofSize: 16, weight: .bold)
        static let header = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let primaryLabel = UIFont.systemFont(ofSize: 14, weight: .regular)
        static let secondaryLabel = UIFont.systemFont(ofSize: 12, weight: .light)
    }
}


extension UITableView.Style {
    static var app: UITableView.Style {
        if #available(iOS 13, *) {
            return .insetGrouped
        } else {
            return .grouped
        }
    }
}
