import Foundation
import CoreLocation

/// Catégorie d'événement, alignée sur l'ontologie DATAtourisme (`SaleEvent`).
enum SaleEventKind: String, Codable, CaseIterable, Sendable {
    case videGrenier
    case brocante
    case marcheAuxPuces
    case braderie
    case marche
    case autre

    var label: String {
        switch self {
        case .videGrenier: return "Vide-grenier"
        case .brocante: return "Brocante"
        case .marcheAuxPuces: return "Marché aux puces"
        case .braderie: return "Braderie"
        case .marche: return "Marché"
        case .autre: return "Événement"
        }
    }
}

/// Provenance de la fiche : open data institutionnel ou créée dans l'app.
enum SaleEventSource: String, Codable, Sendable {
    case dataTourisme
    case crowdsourced
}

/// Un événement de vente au déballage géolocalisé, décodé depuis l'API.
///
/// Modèle immuable : les valeurs d'énumération inconnues retombent sur des
/// valeurs sûres et les tags non reconnus sont ignorés (tolérance au schéma).
struct SaleEvent: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    let name: String
    let kind: SaleEventKind
    let latitude: Double
    let longitude: Double
    let startsAt: Date
    let endsAt: Date?
    let address: String?
    let recurrenceDays: [String]
    let source: SaleEventSource
    let liveStatus: EventLiveStatus
    let topTags: [InventoryTag]
    let photoCount: Int
    let authorId: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, kind, latitude, longitude, startsAt, endsAt
        case address, recurrenceDays, source, liveStatus, topTags, photoCount, authorId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = SaleEventKind(rawValue: try c.decode(String.self, forKey: .kind)) ?? .autre
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        startsAt = try c.decode(Date.self, forKey: .startsAt)
        endsAt = try c.decodeIfPresent(Date.self, forKey: .endsAt)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        recurrenceDays = (try? c.decode([String].self, forKey: .recurrenceDays)) ?? []
        source = SaleEventSource(rawValue: (try? c.decode(String.self, forKey: .source)) ?? "") ?? .crowdsourced
        liveStatus = EventLiveStatus(rawValue: (try? c.decode(String.self, forKey: .liveStatus)) ?? "") ?? .scheduled
        let tagStrings = (try? c.decode([String].self, forKey: .topTags)) ?? []
        topTags = tagStrings.compactMap(InventoryTag.init(rawValue:))
        photoCount = (try? c.decode(Int.self, forKey: .photoCount)) ?? 0
        authorId = try? c.decodeIfPresent(String.self, forKey: .authorId)
    }
}
