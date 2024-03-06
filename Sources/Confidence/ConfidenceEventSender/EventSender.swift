import Foundation

public protocol ConfidenceEventSender {
    func send<P: Codable>(eventName: String, message: P)
}
