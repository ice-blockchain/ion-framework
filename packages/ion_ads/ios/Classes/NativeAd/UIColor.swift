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
        static let cardBackground = UIColor(hex: "#F5F7FF")!
        
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


enum AppFonts {
    static func loadFonts() {
        // A static flag to ensure we only try to register fonts once.
        struct Static { static var once = false }
        if Static.once { return }
        Static.once = true

        // The names of your font files.
        let fontNames = ["NotoSans-Regular.ttf", "NotoSans-Medium.ttf", "NotoSans-SemiBold.ttf", "NotoSans-Bold.ttf"]
        let bundle = Bundle(for: NativeAdCardView.self)

        for fontName in fontNames {
            guard let url = bundle.url(forResource: fontName.components(separatedBy: ".")[0], withExtension: fontName.components(separatedBy: ".")[1]) else {
                print("Failed to find font \(fontName) in bundle")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static let header = UIFont(name: "NotoSans-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
    static let primaryLabel = UIFont(name: "NotoSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .regular)
    
    static let secondaryLabel = UIFont(name: "NotoSans-SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
    
    static let caption3 = UIFont(name: "NotoSans-Bold", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .heavy)
    static let title = UIFont.systemFont(ofSize: 16, weight: .bold)
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
