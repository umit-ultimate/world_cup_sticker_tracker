import Foundation

enum AlbumSetupFlag {
    private static let key = "albumSetupCompleted"

    static var isCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
