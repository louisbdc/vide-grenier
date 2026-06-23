import Foundation

/// Photo prise dans les allées, déjà floutée (visages + plaques) sur le
/// téléphone avant tout envoi. Telle que renvoyée par l'API.
struct EventPhoto: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    let url: String
    let authorId: String
    let createdAt: Date
}
