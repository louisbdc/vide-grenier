import Foundation

/// Liste locale des utilisateurs bloqués : leurs photos et annonces sont
/// masquées sur l'appareil. Exigence App Store (modération UGC, règle 1.2).
enum BlockStore {
    private static let key = "videgrenier.blockedUsers"

    static func blocked() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func block(_ uid: String) {
        var set = blocked()
        set.insert(uid)
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    static func isBlocked(_ uid: String?) -> Bool {
        guard let uid else { return false }
        return blocked().contains(uid)
    }
}
