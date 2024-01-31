import SwiftUI
import OpenAI

@main
struct IndigoApp: App {
    var body: some Scene {
        WindowGroup {
			ContentView()
		}.environment(\.openAI, OpenAI(apiToken: Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as! String))
	}
}

struct OpenAIKey: EnvironmentKey {
	static var defaultValue: OpenAI? = nil
}

extension EnvironmentValues {
	var openAI: OpenAI? {
		get { self[OpenAIKey.self] }
		set { self[OpenAIKey.self] = newValue }
	}
}
