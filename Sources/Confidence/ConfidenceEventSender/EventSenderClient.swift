import Foundation

typealias EventHTTPResponse = HttpClientResponse<EventResponse>
typealias EventResult = Result<EventHTTPResponse, Error>


public protocol ContextProvider {
    func getCurrent() -> String // TODO Use complex type
}

public class EventSenderClient: ConfidenceEventSender {


    public func withContext(_ context: EventSenderContext) {
        self.context.append(context)
    }

    private var context: [EventSenderContext] = []
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
        send(eventName: eventName, message: message, contexts: self.context)
    }
    
    private func send<T: Codable>(eventName: String, message: T, contexts: [EventSenderContext]) {
        Task {
            if #available(iOS 15.0, *) {
                let request = EventRequest(
                    clientSecret: secret,
                    events: [Event(
                        eventDefinition: "eventDefinitions/\(eventName)",
                        payload: Payload(message: message, context: RootContext(evaluation: RootContext.Evaluation(targeting_key: contextProvider.getCurrent()), custom: contexts)),
                        eventTime: Date.now.ISO8601Format())],
                    sendTime: Date.now.ISO8601Format())
                let _: EventResult = try await self.httpClient.post(path: ":publish", data: request)
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
    var context: RootContext
}

struct RootContext: Codable {
    var evaluation: Evaluation
    var custom: [EventSenderContext]

    struct Evaluation: Codable {
        var targeting_key: String
    }
}


struct EventResponse: Decodable { }
