import Foundation

typealias EventHTTPResponse = HttpClientResponse<EventResponse>
typealias EventResult = Result<EventHTTPResponse, Error>


public protocol ContextProvider {
    func getCurrent() -> String // TODO Use complex type
}

public class EventSenderClient: EventSender {
    private var httpClient = NetworkClient(region: .eventsEu)
    private let contextProvider: ContextProvider
    private var secret: String

    init(
        secret: String,
        contextProvider: ContextProvider
    ) {
        self.secret = secret
        self.contextProvider = contextProvider
    }

    public func send<T: Codable>(eventName: String, message: T) {
        Task {
            if #available(iOS 15.0, *) {
                let request = EventRequest(
                    clientSecret: secret,
                    events: [Event(
                        eventDefinition: "eventDefinitions/\(eventName)",
                        payload: Payload(message: message, context: Context(context: Context.Evaluation(targeting_key: contextProvider.getCurrent()))),
                        eventTime: Date.now.ISO8601Format())],
                    sendTime: Date.now.ISO8601Format())
                print(">> \(request)")
                let response: EventResult = try await self.httpClient.post(path: ":publish", data: request)
                print(">> \(try response.get().response.statusCode)")
            } else {
                // Fallback on earlier versions
            }
        }
    }
}


struct EventRequest<T: Codable>: Codable {
    var clientSecret: String
    var events: [Event<T>]
    var sendTime: String
}

struct Event<T: Codable>: Codable {
    var eventDefinition: String
    var payload: Payload<T>
    var eventTime: String
}

struct Payload<T: Codable>: Codable {
    var message: T
    var context: Context
}

struct Context: Codable {
    var context: Evaluation

    struct Evaluation: Codable {
        var targeting_key: String
    }
}


struct EventResponse: Decodable { }
