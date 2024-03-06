import Confidence
import OpenFeature
import SwiftUI

@main
struct ConfidenceDemoApp: App {
    let appData = AppData()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    self.setup(appData: appData)
                }
        }
    }
}

class AppData: ObservableObject {
    @Published var user = ["fdema", "vahidt", "andreask", "nicklasl", "nickyb"].randomElement() ?? "unknown"
    @Published var eventSender: ConfidenceEventSender

    init() {
        Confidence.shared.setClientSecret(clientSecret: "oyZhk114S4HIx1xN7cUWxbjfL3IWUK9m")
        eventSender = Confidence.shared.createEventSender(forwardEvaluationContext: true)
    }
}

extension ConfidenceDemoApp {
    func setup(appData: AppData) {
        Task {
            // Configure the OpenFeature singleton
            let provider = Confidence.shared.providerBuilder()
                .with(initializationStrategy: .fetchAndActivate)
                .build()
            print(">> Setting context with user \(appData.user)")
            let evalContext = MutableContext(
                targetingKey: appData.user,
                structure: MutableStructure())
            await OpenFeatureAPI.shared.setProviderAndWait(
                provider: provider,
                initialContext: evalContext)

        }
    }
}
