import OpenAI
import SwiftUI
import AVFoundation

enum Stage: Equatable {
	case error
	case ready
	case loading
	case missingAPIKey
	case permissionDenied
}

struct ContentView: View {
	@State private var stage: Stage = .loading
	@State private var conversation: Conversation?

	var isUserSpeaking: Bool {
		conversation?.isUserSpeaking ?? false
	}

	var isModelSpeaking: Bool {
		conversation?.isPlaying ?? false
	}

	var hasError: Bool {
		[.error, .permissionDenied, .missingAPIKey].contains(stage)
	}

	var text: String {
		if isUserSpeaking { return "Listening" }
		if isModelSpeaking { return "Speaking" }
		if stage == .loading { return "Loading..." }
		if hasError { return "Something went wrong" }

		return "Say something"
	}

	var backgroundColor: Color {
		if stage == .loading { return .white }
		if hasError { return Color(hex: "#fecaca") }
		if isModelSpeaking || isUserSpeaking { return .purple }

		return Color(hex: "#F5E6FD")
	}

	var squareColor: Color {
		if hasError { return .red }
		if isUserSpeaking || isModelSpeaking { return Color(hex: "#F5E6FD") }

		return .purple
	}

	var textColor: Color {
		if hasError { return .red }
		if isUserSpeaking || isModelSpeaking { return .white }

		return .black
	}

	var body: some View {
		MissingOpenAIKeyAlert(show: stage == .missingAPIKey)
		RecordingPermissionDeniedAlert(show: stage == .permissionDenied)

		ZStack {
			backgroundColor
				.edgesIgnoringSafeArea(.all)
				.animation(.default, value: stage)

			VStack {
				Spacer()

				Rectangle()
					.fill(squareColor)
					.frame(width: 100, height: 100)
					.scaleEffect(isUserSpeaking || isModelSpeaking ? 1.3 : 1)
					.animation(.default, value: stage)
					.opacity(stage == .loading ? 0.5 : 1)
					.animation(stage == .loading ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : nil, value: stage)
					.sensoryFeedback(trigger: isUserSpeaking) { _, isSpeaking in
						isSpeaking ? .start : .stop
					}

				Spacer()

				Text(text)
					.foregroundColor(textColor)
					.font(.custom("Signifier-Light", size: stage == .error ? 35 : 40))
					.animation(.default, value: stage)
					.transition(.blurReplace)
					.padding(.bottom, 50)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.task { await prepareForRecording() }
		.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
			guard hasError else { return }

			stage = .loading
			Task { await prepareForRecording() }
		}
	}

	func prepareForRecording() async {
		guard let apiKey = SettingsBundleHelper.getOpenAIKey() else {
			stage = .missingAPIKey
			return
		}

		guard await AVAudioApplication.requestRecordPermission() else {
			stage = .permissionDenied
			return
		}

		conversation = Conversation(authToken: apiKey)

		do {
			try conversation!.startListening()
			stage = .ready
		} catch {
			print("Failed to start handling voice: \(error)")
			stage = .error
		}
	}
}

#Preview {
	ContentView()
}
