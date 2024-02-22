import Confidence
import OpenFeature
import SwiftUI

@main
struct ConfidenceDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    self.setup()
                }
        }
    }
}

extension ConfidenceDemoApp {
    func setup() {
        Task {
            // Configure the Confidence singleton
            Confidence.shared.setClientSecret(clientSecret: "oyZhk114S4HIx1xN7cUWxbjfL3IWUK9m")

            // Configure the OpenFeature singleton
            let provider = Confidence.shared.providerBuilder()
                .with(initializationStrategy: .fetchAndActivate)
                .build()
            let evalContext = MutableContext(
                targetingKey: "fdema",
                structure: MutableStructure())
            await OpenFeatureAPI.shared.setProviderAndWait(
                provider: provider,
                initialContext: evalContext)

            // Create an EventSender instance
            let eventSender = Confidence.shared.createEventSender(
                forwardEvaluationContext: true) // Automatically adds "targeting_key" in the evaluation context to event context, if available
            // Create a OpenFeatureClient instance
            let openFeatureClient = OpenFeatureAPI.shared.getClient()

            // Resolve a flag
            let flagValue = openFeatureClient.getValue(key: "swift-demoapp.color", defaultValue: "ERROR")
            print(">> \(flagValue)") // "YELLOW"
            // Send an event
            eventSender.send(
                eventName: "button-clicked",
                message: ButtonClicked(button_id: "imaginary-button")
            )
            /*
            Generated request:

             (clientSecret: "oyZhk114S4HIx1xN7cUWxbjfL3IWUK9m",
             sendTime: "2024-03-04T13:22:32Z",
             events: [
                 (
                     eventDefinition: "eventDefinitions/button-clicked",
                     eventTime: "2024-03-04T13:22:32Z",
                     payload: (
                         message: (
                             button_id: "imaginary-button"
                         ),
                         context: (
                             evaluation: (
                                 targeting_key: "fdema"
                             )
                         )
                     )
                 )
             ])*/
        }
    }
}

// How do we support types like Date and Timestamp?
struct ButtonClicked: Codable {
    var button_id: String
}
