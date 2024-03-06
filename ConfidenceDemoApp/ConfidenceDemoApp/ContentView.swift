import SwiftUI
import OpenFeature
import Combine
import Confidence

struct ContentView: View {
    @StateObject var status = Status()
    @StateObject var text = DisplayText()
    @StateObject var errorText = ErrorMessageText()
    @StateObject var color = FlagColor()
    @EnvironmentObject var appData: AppData

    var body: some View {
        if case .ready = status.state {
            VStack {
                Text("You are \(appData.user) 👋")
                    .padding(10)
                Button(action: {
                    appData.eventSender.send(eventName: "button-clicked", message: ButtonClicked(button_id: "flag-icon"))
                }) {
                    Image(systemName: "flag")
                        .imageScale(.large)
                        .foregroundColor(color.color)
                        .padding(5)
                }
                Text(text.text)
                .padding(CGFloat(exactly: 10.0) ?? 10)
                Text(errorText.text)
            }.onAppear {
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
                text.text = "Tap the flag 👆"
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
