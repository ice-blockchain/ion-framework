import UIKit

extension UIColor {
    struct App {
        static let accent = UIColor.lightGray
        static let secondaryAccent = UIColor.systemBlue //  UIColor(named: "StackSecondaryColor")
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
