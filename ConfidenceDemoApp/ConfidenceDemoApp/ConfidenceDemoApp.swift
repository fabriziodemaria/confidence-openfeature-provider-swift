import Confidence
import OpenFeature
import SwiftUI

@main
struct ConfidenceDemoApp: App {
    let esHolder = EventSenderHolder()
    var body: some Scene {
        WindowGroup {
            ContentView(eventSender: esHolder.eventSender)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    self.setup()
                }
        }
    }
}

class EventSenderHolder: ObservableObject {
    @Published var eventSender: ConfidenceEventSender

    init() {
        Confidence.shared.setClientSecret(clientSecret: "oyZhk114S4HIx1xN7cUWxbjfL3IWUK9m")
        eventSender = Confidence.shared.createEventSender(forwardEvaluationContext: true)
    }
}

extension ConfidenceDemoApp {
    func setup() {
        Task {
            let provider = Confidence.shared.providerBuilder()
                .with(initializationStrategy: .fetchAndActivate)
                .build()
            await OpenFeatureAPI.shared.setProviderAndWait(
                provider: provider)
        }
    }
}
