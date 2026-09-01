//
//  PlaceAppDirectory.swift
//  ADHD LifeOS
//
//  The open-any-app directory's pure layer (F-AppDirectory-1-Directory). The bundled list
//  lives in `PlaceAppDirectoryBundled.swift`; the remote top-up arrives in block 4 and flows
//  through the same decode + merge defined here.
//

import Foundation

/// One "open INTO something" a directory app offers (a playlist, a route, a chat). The
/// template holds at most ONE `{value}` slot, substituted percent-encoded — anything richer
/// is expressed as a pass-through (empty/slotless template) where E pastes the whole share
/// link and it IS the destination.
struct PlaceAppDestinationTemplate: Equatable, Hashable, Sendable {
    let name: String
    let template: String
    /// Whether this template can take the PLACE's own coordinate as its value — curated with
    /// a flag, never inferred from names, so the lenient remote decode can carry it. The
    /// destination step turns it into a one-tap "Directions to <place>" row.
    let placeCoordinatePrefill: Bool

    init(name: String, template: String, placeCoordinatePrefill: Bool = false) {
        self.name = name
        self.template = template
        self.placeCoordinatePrefill = placeCoordinatePrefill
    }

    var isPassThrough: Bool { !template.contains(Self.slot) }

    /// The resolved link, or `nil` when the value is blank. The value is percent-encoded with
    /// the URL-unreserved set, so "abc 123/xyz" cannot break out of its path segment.
    func resolved(with value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !isPassThrough else { return trimmed }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: Self.unreserved)
        else { return nil }
        return template.replacingOccurrences(of: Self.slot, with: encoded)
    }

    static let slot = "{value}"

    /// RFC 3986 unreserved — deliberately NOT `.urlPathAllowed`, which would let "/" through
    /// and turn one pasted value into extra path segments.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )
}

/// One app the directory can offer. The scheme is the identity — merge keys on it, and a
/// block-1 pick saves it straight into `.openApp` — so an entry without a CONFIDENT published
/// scheme does not belong in the directory at all (it reaches E via block 2's pasted links
/// instead). A wrong scheme teaches E the whole feature lies.
struct PlaceAppDirectoryEntry: Identifiable, Equatable, Hashable, Sendable {
    let scheme: String
    let name: String
    var keywords: [String]
    var universalLinkHosts: [String]
    var destinations: [PlaceAppDestinationTemplate]
    /// Higher ranks list first (within a search tier) — the directory's own sense of "the apps
    /// most people mean". 0 is the unranked long tail.
    var rank: Int
    /// A retired entry: kept in the merged list so a saved action keeps its name, but never
    /// offered by search again. Only remote rows ever set this.
    var hidden: Bool

    init(
        scheme: String, name: String, keywords: [String] = [],
        universalLinkHosts: [String] = [], destinations: [PlaceAppDestinationTemplate] = [],
        rank: Int = 0, hidden: Bool = false
    ) {
        self.scheme = scheme
        self.name = name
        self.keywords = keywords
        self.universalLinkHosts = universalLinkHosts
        self.destinations = destinations
        self.rank = rank
        self.hidden = hidden
    }

    var id: String { scheme }
}

enum PlaceAppDirectory {
    /// Decodes a JSON array of entries LENIENTLY: a malformed entry — or a malformed
    /// destination inside a good entry — is dropped, never fatal. The `.unsupported`
    /// philosophy adapted for a catalogue: one bad remote row must not cost E the directory.
    static func entries(fromJSONArray data: Data) -> [PlaceAppDirectoryEntry] {
        guard let rows = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else { return [] }
        return rows.compactMap(entry(fromObject:))
    }

    /// One entry from one JSON object, or `nil` when it can't be trusted: the scheme must
    /// already be in normalized form (else the `.openApp` it saves could never open) and the
    /// name must survive trimming. Hosts are lowercased once here so matching never has to.
    static func entry(fromObject object: [String: Any]) -> PlaceAppDirectoryEntry? {
        guard let rawScheme = object[WireKey.scheme] as? String,
              let scheme = PlaceActionCatalog.normalizedScheme(rawScheme),
              scheme == rawScheme,
              let rawName = object[WireKey.name] as? String else { return nil }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        return PlaceAppDirectoryEntry(
            scheme: scheme,
            name: name,
            keywords: object[WireKey.keywords] as? [String] ?? [],
            universalLinkHosts: (object[WireKey.universalLinkHosts] as? [String] ?? [])
                .map { $0.lowercased() },
            destinations: (object[WireKey.destinations] as? [[String: Any]] ?? [])
                .compactMap(destination(fromObject:)),
            rank: object[WireKey.rank] as? Int ?? 0,
            hidden: object[WireKey.hidden] as? Bool ?? false
        )
    }

    private static func destination(fromObject object: [String: Any]) -> PlaceAppDestinationTemplate? {
        guard let name = object[WireKey.destinationName] as? String,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let template = object[WireKey.destinationTemplate] as? String,
              template.components(separatedBy: PlaceAppDestinationTemplate.slot).count <= 2
        else { return nil }
        return PlaceAppDestinationTemplate(
            name: name,
            template: template,
            placeCoordinatePrefill: object[WireKey.destinationPrefill] as? Bool ?? false
        )
    }

    /// The directory app claiming a pasted link's host, if any — how "smart custom"
    /// recognises `open.spotify.com/...` as Spotify. Hosts are stored lowercased; the pasted
    /// side is lowercased here so E's keyboard can't defeat the match.
    static func entry(
        claimingHost host: String, in entries: [PlaceAppDirectoryEntry]
    ) -> PlaceAppDirectoryEntry? {
        let needle = host.lowercased()
        return entries.first { $0.universalLinkHosts.contains(needle) }
    }

    /// Remote wins WHOLESALE per scheme — no per-field merging, so a remote row is exactly
    /// what ships. Replaced entries keep their bundled position; remote-only entries append in
    /// remote order. `merge(bundled, []) == bundled` is the pinned identity.
    static func merge(
        bundled: [PlaceAppDirectoryEntry], remote: [PlaceAppDirectoryEntry]
    ) -> [PlaceAppDirectoryEntry] {
        let byScheme = Dictionary(remote.map { ($0.scheme, $0) }, uniquingKeysWith: { _, last in last })
        var merged = bundled.map { byScheme[$0.scheme] ?? $0 }
        let bundledSchemes = Set(bundled.map(\.scheme))
        merged.append(contentsOf: remote.filter { !bundledSchemes.contains($0.scheme) })
        return merged
    }

    /// The remote doc's spelling — snake_case, the tasks convention. Plain constants rather
    /// than `CodingKeys` because the lenient walk reads `[String: Any]`, not a decoder.
    private enum WireKey {
        static let scheme = "scheme"
        static let name = "name"
        static let keywords = "keywords"
        static let universalLinkHosts = "universal_link_hosts"
        static let destinations = "destinations"
        static let rank = "rank"
        static let hidden = "hidden"
        static let destinationName = "name"
        static let destinationTemplate = "template"
        static let destinationPrefill = "place_coordinate_prefill"
    }
}

/// The pure parts of a destination pick — display names and the coordinate prefill value —
/// so the sheet assembles picks from pinned pieces.
enum PlaceAppDestinationPick {
    static func displayName(
        entry: PlaceAppDirectoryEntry, destination: PlaceAppDestinationTemplate
    ) -> String {
        "\(entry.name) — \(destination.name)"
    }

    static func directionsDisplayName(
        entry: PlaceAppDirectoryEntry, placeName: String
    ) -> String {
        "\(entry.name) — Directions to \(placeName)"
    }

    /// "lat,long" at five decimals (~1 m) — the form both Maps apps read as a destination.
    /// The comma percent-encodes inside the template's value slot; both apps decode it.
    static func coordinateValue(_ coordinate: PlaceCoordinate) -> String {
        String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude)
    }
}

/// Ranked search over the directory. The tier order is pinned: a match on the NAME's start
/// beats a match inside the name, beats a keyword, beats the scheme — so what E types can
/// never bury an exact-feeling hit under a keyword coincidence. Hidden entries never surface.
enum PlaceAppDirectorySearch {
    static func filter(
        _ query: String, in entries: [PlaceAppDirectoryEntry]
    ) -> [PlaceAppDirectoryEntry] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let visible = entries.filter { !$0.hidden }
        guard !needle.isEmpty else { return visible.sorted(by: rankThenName) }
        return visible
            .compactMap { entry in tier(of: needle, in: entry).map { (entry, $0) } }
            .sorted { lhs, rhs in
                guard lhs.1 == rhs.1 else { return lhs.1 < rhs.1 }
                return rankThenName(lhs.0, rhs.0)
            }
            .map(\.0)
    }

    private static func tier(of needle: String, in entry: PlaceAppDirectoryEntry) -> Int? {
        let name = entry.name.lowercased()
        if name.hasPrefix(needle) { return 0 }
        if name.contains(needle) { return 1 }
        if entry.keywords.contains(where: { $0.lowercased().contains(needle) }) { return 2 }
        if entry.scheme.contains(needle) { return 3 }
        return nil
    }

    private static func rankThenName(
        _ lhs: PlaceAppDirectoryEntry, _ rhs: PlaceAppDirectoryEntry
    ) -> Bool {
        guard lhs.rank == rhs.rank else { return lhs.rank > rhs.rank }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}
