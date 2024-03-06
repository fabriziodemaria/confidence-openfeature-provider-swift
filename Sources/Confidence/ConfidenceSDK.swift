import Foundation
import OpenFeature

public protocol ConfidenceProtocol {
    func providerBuilder() -> ConfidenceFeatureProvider.Builder
    func createEventSender(forwardEvaluationContext: Bool) -> ConfidenceEventSender
}

// ContextProvider is defined in the EventSedner sub-module
public final class EvaluationContextProvider: ContextProvider {
    public func getCurrent() -> String {
        OpenFeatureAPI.shared.getEvaluationContext()?.getTargetingKey() ?? ""
    }
}

public class Confidence: ConfidenceProtocol {
    private var clientSecret: String?

    static public let shared = Confidence()

    public init() {
    }

    public func setClientSecret(clientSecret: String) {
        self.clientSecret = clientSecret
    }

    public func providerBuilder() -> ConfidenceFeatureProvider.Builder {
        // TODO Emit listenable error events if client secret is not set
        return ConfidenceFeatureProvider.Builder(
            credentials: ConfidenceClientCredentials.clientSecret(secret: clientSecret ?? ""))
    }

    // Should this be a singleton instead?
    public func createEventSender(forwardEvaluationContext: Bool = false) -> ConfidenceEventSender {
        // TODO Emit listenable error events if client secret is not set
        return EventSenderClient(secret: clientSecret ?? "", contextProvider: EvaluationContextProvider())
    }
}
