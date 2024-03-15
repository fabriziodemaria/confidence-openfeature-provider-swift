import SwiftUI
import OpenFeature
import Combine
import Confidence

struct ContentView: View {
    @StateObject var status = Status()
    @StateObject var text = DisplayText()
    @StateObject var errorText = ErrorMessageText()
    @StateObject var color = FlagColor()
    let eventSender: ConfidenceEventSender
    let ofClient: Client
    @State var userId = UUID().uuidString

    init(eventSender: ConfidenceEventSender) {
        eventSender.withContext(EventSenderContext(
            context_id: "page_id",
            context_data: AnyCodable("home_screen")))
        self.eventSender = eventSender
        self.ofClient = OpenFeatureAPI
            .shared
            .getClient()
        let evalContext = MutableContext(
            targetingKey: userId,
            structure: MutableStructure())
        userId = userId
        OpenFeatureAPI.shared.setEvaluationContext(evaluationContext: evalContext)
    }

    var body: some View {
        if case .ready = status.state {
            VStack {
                Image("confidence_text")
                    .resizable()
                    .scaledToFit()
                    .padding(40)
                Text("👋 You are \n \(Text(userId).foregroundColor(color.color))")
                    .multilineTextAlignment(.center)
                Button(action: {
                    userId = UUID.init().uuidString
                    let evalContext = MutableContext(
                        targetingKey: userId,
                        structure: MutableStructure())
                    Task {
                        let _ = OpenFeatureAPI.shared.observe().sink { e in
                            if (e == .ready) {
                                updateFlagColor()
                            }
                        }
                        OpenFeatureAPI.shared.setEvaluationContext(evaluationContext: evalContext)
                    }
                }) {
                    Image(systemName: "person.line.dotted.person")
                        .imageScale(.large)
                        .foregroundColor(color.color)
                        .padding(5)
                }
                Text(text.text)
                    .padding(10)
                Button(action: {
                    eventSender.send(eventName: "button-clicked", message: ButtonClicked(button_id: "flag-icon"))
                }) {
                    Image(systemName: "flag")
                        .imageScale(.large)
                        .foregroundColor(color.color)
                        .padding(5)
                }
                .padding(20)
                Text(errorText.text)
            }.onAppear {
                updateFlagColor()
            }
        } else if case .error(let error) = status.state {
            VStack {
                Text("Provider Error")
                Text(error?.localizedDescription ?? "An unknow error has occured.")
                    .foregroundColor(.red)
            }
        } else {
            VStack {
                ProgressView()
            }
        }
    }

    private func updateFlagColor() {
        let resolveDetails = OpenFeatureAPI
            .shared
            .getClient()
            .getStringDetails(key: "swift-demoapp.color", defaultValue: "ERROR")
        if resolveDetails.value == "Green" {
            color.color = .green
        } else if resolveDetails.value == "Yellow" {
            color.color = .yellow
        } else {
            color.color = .red
        }
        errorText.text = resolveDetails.errorMessage ?? ""
        text.text = "👇 Tap the flag to send metrics👇"
    }
}

class Status: ObservableObject {
    enum State {
        case unknown
        case ready
        case error(Error?)
    }

    var cancellable: AnyCancellable?

    @Published var state: State = .unknown

    init() {
        cancellable = OpenFeatureAPI.shared.observe().sink { [weak self] event in
            if event == .ready {
                DispatchQueue.main.async {
                    self?.state = .ready
                }
            }
            if event == .error {
                DispatchQueue.main.async {
                    self?.state = .error(nil)
                }
            }
        }
    }
}

class DisplayText: ObservableObject {
    @Published var text = ""
}

class ErrorMessageText: ObservableObject {
    @Published var text = ""
}


class FlagColor: ObservableObject {
    @Published var color: Color = .black
}

struct ButtonClicked: Codable {
    var button_id: String
}
