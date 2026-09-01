//
//  PlaceActionModels.swift
//  ADHD LifeOS
//

import Foundation

/// Which crossing an action belongs to. Every action picks exactly one — an arrival action
/// never speaks on the way out, the `arrivalMessage`/`departureMessage` contract.
enum PlaceActionDirection: String, Codable, Equatable, Sendable, CaseIterable {
    case arrival
    case departure
}

/// A JSON-ish payload value, kept ONLY so an unsupported action survives a round trip through a
/// build that doesn't know its kind. E's device routinely lags main (see the device-build-lag
/// record): an older build editing a place re-encodes the whole document, and without this a
/// newer build's action would come back stripped of its payload — silently broken by an edit
/// that never touched it.
enum PlaceActionValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Bool before Double: both JSON and Firestore surface booleans as values a lenient
        // number decode could swallow, and `true` re-encoded as `1.0` is corruption.
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Payload value is not a string, number, or bool."
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        }
    }
}

/// One thing a place does when E crosses its fence (the Place Actions arc, E's 2026-08-31 spec).
///
/// The kind list is an OPEN catalogue — E: "all of the above and likely more" — so the wire
/// format is built for kinds this build has never heard of: a flat snake_case object with a
/// `kind` discriminator, and anything unrecognised (unknown kind, or a known kind whose payload
/// is broken) degrades to `.unsupported` carrying the raw payload for verbatim re-encode. A
/// place must NEVER fail to decode because one action is from the future.
struct PlaceAction: Codable, Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// Opens another app via its URL scheme — executes from a notification tap only; iOS
        /// forbids launching another app from a background wake.
        case openApp(scheme: String, displayName: String)
        case openURL(urlString: String)
        /// Pre-fills a message to the predefined contact. The final Send tap is Apple's floor —
        /// no third-party app may auto-send.
        case textContact(contactName: String, phoneNumber: String, messageBody: String)
        /// `nil` minutes means "use E's default sprint setting", resolved at execution time so a
        /// Settings change doesn't strand stale minutes on every place.
        case startSprint(minutes: Int?)
        case createCapture(text: String)
        case journalLine(body: String)
        /// An in-app destination, kept as a raw token here — the routing enum is execution's
        /// concern (block 3), and a token this model can't route still round-trips.
        case openScreen(screen: String)
        /// A kind this build doesn't know, or a known kind whose required payload was missing.
        /// The payload rides along untouched so a newer build gets its action back intact.
        case unsupported(rawKind: String, payload: [String: PlaceActionValue])
    }

    let id: UUID
    var direction: PlaceActionDirection
    var kind: Kind
    /// Fields a NEWER build wrote onto a kind this build knows (the F-AppDirectory-1 encoder
    /// fix). `.unsupported` already preserves unknown KINDS; without this, a known kind that
    /// grew an optional field would have it silently stripped by an older build's re-save.
    /// Empty for `.unsupported` — there the whole payload already rides in the case itself.
    var extraPayload: [String: PlaceActionValue]

    init(
        id: UUID, direction: PlaceActionDirection, kind: Kind,
        extraPayload: [String: PlaceActionValue] = [:]
    ) {
        self.id = id
        self.direction = direction
        self.kind = kind
        self.extraPayload = extraPayload
    }

    // MARK: - Wire format

    /// Reserved keys — everything else on the object is kind payload.
    private enum ReservedKey: String {
        case id
        case direction
        case kind
    }

    private enum KindName: String {
        case openApp = "open_app"
        case openURL = "open_url"
        case textContact = "text_contact"
        case startSprint = "start_sprint"
        case createCapture = "create_capture"
        case journalLine = "journal_line"
        case openScreen = "open_screen"
    }

    private enum PayloadKey: String {
        case scheme
        case displayName = "display_name"
        case url
        case contactName = "contact_name"
        case phoneNumber = "phone_number"
        case messageBody = "message_body"
        case minutes
        case captureText = "capture_text"
        case journalBody = "journal_body"
        case screen
    }

    /// String-backed key so decode can walk EVERY field on the object — required for capturing
    /// an unknown kind's payload, which by definition has keys this build cannot enumerate.
    private struct DynamicKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
        init(_ key: ReservedKey) { stringValue = key.rawValue }
        init(_ key: PayloadKey) { stringValue = key.rawValue }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        id = try container.decode(UUID.self, forKey: DynamicKey(.id))
        direction = try container.decode(PlaceActionDirection.self, forKey: DynamicKey(.direction))
        let rawKind = try container.decode(String.self, forKey: DynamicKey(.kind))
        kind = Self.decodeKind(rawKind, from: container)
        if case .unsupported = kind {
            extraPayload = [:]
        } else {
            extraPayload = Self.capturePayload(
                from: container, excluding: Self.typedPayloadKeys(forRawKind: rawKind)
            )
        }
    }

    /// A known kind with its payload intact decodes typed; anything else — unknown kind, or a
    /// required field missing/undecodable — degrades to `.unsupported` rather than throwing.
    /// Throwing here would fail the whole PLACE, and a place must survive one broken action.
    private static func decodeKind(
        _ rawKind: String, from container: KeyedDecodingContainer<DynamicKey>
    ) -> Kind {
        guard let name = KindName(rawValue: rawKind),
              let typed = typedKind(name, from: container) else {
            return .unsupported(rawKind: rawKind, payload: capturePayload(from: container))
        }
        return typed
    }

    private static func typedKind(
        _ name: KindName, from container: KeyedDecodingContainer<DynamicKey>
    ) -> Kind? {
        switch name {
        case .openApp:
            guard let scheme = string(.scheme, container),
                  let displayName = string(.displayName, container) else { return nil }
            return .openApp(scheme: scheme, displayName: displayName)
        case .textContact:
            guard let contact = string(.contactName, container),
                  let phone = string(.phoneNumber, container),
                  let body = string(.messageBody, container) else { return nil }
            return .textContact(contactName: contact, phoneNumber: phone, messageBody: body)
        case .startSprint:
            // Absent minutes is a VALID payload (use the default setting) — only a present but
            // undecodable value degrades to unsupported. Two steps because `try?` FLATTENS the
            // nested optional (SE-0230), which makes `decodeIfPresent` unable to tell those
            // two cases apart.
            guard container.contains(DynamicKey(.minutes)) else {
                return .startSprint(minutes: nil)
            }
            guard let minutes = try? container.decode(Int.self, forKey: DynamicKey(.minutes)) else {
                return nil
            }
            return .startSprint(minutes: minutes)
        case .openURL, .createCapture, .journalLine, .openScreen:
            return singleStringKind(name, from: container)
        }
    }

    /// The kinds whose whole payload is one string field.
    private static func singleStringKind(
        _ name: KindName, from container: KeyedDecodingContainer<DynamicKey>
    ) -> Kind? {
        switch name {
        case .openURL: return string(.url, container).map { .openURL(urlString: $0) }
        case .createCapture: return string(.captureText, container).map { .createCapture(text: $0) }
        case .journalLine: return string(.journalBody, container).map { .journalLine(body: $0) }
        case .openScreen: return string(.screen, container).map { .openScreen(screen: $0) }
        case .openApp, .textContact, .startSprint: return nil
        }
    }

    private static func string(
        _ key: PayloadKey, _ container: KeyedDecodingContainer<DynamicKey>
    ) -> String? {
        try? container.decodeIfPresent(String.self, forKey: DynamicKey(key))
    }

    /// Everything on the object except the reserved trio and `excluding`, as far as it can be
    /// represented. A value that is neither string, number, nor bool (a nested map, say) is
    /// dropped — the preservation guarantee covers flat payloads, which is what every shipped
    /// kind writes.
    private static func capturePayload(
        from container: KeyedDecodingContainer<DynamicKey>,
        excluding excluded: Set<String> = []
    ) -> [String: PlaceActionValue] {
        var payload: [String: PlaceActionValue] = [:]
        for key in container.allKeys
        where ReservedKey(rawValue: key.stringValue) == nil && !excluded.contains(key.stringValue) {
            if let value = try? container.decode(PlaceActionValue.self, forKey: key) {
                payload[key.stringValue] = value
            }
        }
        return payload
    }

    /// The keys a kind's TYPED payload owns — and only its own: another kind's key appearing on
    /// this kind is a stranger and must be captured, not skipped, so excluding all of
    /// `PayloadKey` here would be wrong.
    private static func typedPayloadKeys(forRawKind rawKind: String) -> Set<String> {
        guard let name = KindName(rawValue: rawKind) else { return [] }
        let keys: [PayloadKey]
        switch name {
        case .openApp: keys = [.scheme, .displayName]
        case .openURL: keys = [.url]
        case .textContact: keys = [.contactName, .phoneNumber, .messageBody]
        case .startSprint: keys = [.minutes]
        case .createCapture: keys = [.captureText]
        case .journalLine: keys = [.journalBody]
        case .openScreen: keys = [.screen]
        }
        return Set(keys.map(\.rawValue))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        try container.encode(id, forKey: DynamicKey(.id))
        try container.encode(direction, forKey: DynamicKey(.direction))
        switch kind {
        case .openApp(let scheme, let displayName):
            try container.encode(KindName.openApp.rawValue, forKey: DynamicKey(.kind))
            try container.encode(scheme, forKey: DynamicKey(.scheme))
            try container.encode(displayName, forKey: DynamicKey(.displayName))
        case .openURL(let urlString):
            try container.encode(KindName.openURL.rawValue, forKey: DynamicKey(.kind))
            try container.encode(urlString, forKey: DynamicKey(.url))
        case .textContact(let contactName, let phoneNumber, let messageBody):
            try container.encode(KindName.textContact.rawValue, forKey: DynamicKey(.kind))
            try container.encode(contactName, forKey: DynamicKey(.contactName))
            try container.encode(phoneNumber, forKey: DynamicKey(.phoneNumber))
            try container.encode(messageBody, forKey: DynamicKey(.messageBody))
        case .startSprint(let minutes):
            try container.encode(KindName.startSprint.rawValue, forKey: DynamicKey(.kind))
            try container.encodeIfPresent(minutes, forKey: DynamicKey(.minutes))
        case .createCapture(let text):
            try container.encode(KindName.createCapture.rawValue, forKey: DynamicKey(.kind))
            try container.encode(text, forKey: DynamicKey(.captureText))
        case .journalLine(let body):
            try container.encode(KindName.journalLine.rawValue, forKey: DynamicKey(.kind))
            try container.encode(body, forKey: DynamicKey(.journalBody))
        case .openScreen(let screen):
            try container.encode(KindName.openScreen.rawValue, forKey: DynamicKey(.kind))
            try container.encode(screen, forKey: DynamicKey(.screen))
        case .unsupported(let rawKind, let payload):
            try container.encode(rawKind, forKey: DynamicKey(.kind))
            for (key, value) in payload {
                try container.encode(value, forKey: DynamicKey(stringValue: key))
            }
        }
        try encodeExtraPayload(into: &container)
    }

    /// Extras fill gaps, never overwrite: a key colliding with the reserved trio or with the
    /// kind's own typed payload is skipped, so a hand-built collision cannot corrupt the typed
    /// fields. `.unsupported` writes nothing here — its whole payload lives in the case.
    private func encodeExtraPayload(
        into container: inout KeyedEncodingContainer<DynamicKey>
    ) throws {
        if case .unsupported = kind { return }
        let occupied = Self.typedPayloadKeys(forRawKind: wireKindName)
        for (key, value) in extraPayload
        where ReservedKey(rawValue: key) == nil && !occupied.contains(key) {
            try container.encode(value, forKey: DynamicKey(stringValue: key))
        }
    }

    private var wireKindName: String {
        switch kind {
        case .openApp: return KindName.openApp.rawValue
        case .openURL: return KindName.openURL.rawValue
        case .textContact: return KindName.textContact.rawValue
        case .startSprint: return KindName.startSprint.rawValue
        case .createCapture: return KindName.createCapture.rawValue
        case .journalLine: return KindName.journalLine.rawValue
        case .openScreen: return KindName.openScreen.rawValue
        case .unsupported(let rawKind, _): return rawKind
        }
    }
}
