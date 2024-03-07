import Foundation

public protocol ConfidenceEventSender {
    func send<P: Codable>(eventName: String, message: P)
    func withContext(_ context: EventSenderContext)
}

public struct EventSenderContext: Codable {
    public init(context_id: String, context_data: AnyCodable) {
        self.context_id = context_id
        self.context_data = context_data
    }
    public var context_id: String
    public var context_data: AnyCodable
}

public struct AnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) where T: Codable {
        self.value = value ?? Optional<T>.none as Any
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = Optional<Any>.none as Any
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self.value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let optional as Optional<Any>:
            if optional == nil {
                try container.encodeNil()
            }
        default:
            let context = EncodingError.Context(codingPath: [CodingKey](), debugDescription: "Invalid AnyCodable value")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}
