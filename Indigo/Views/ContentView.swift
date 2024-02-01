import OpenAI
import SwiftUI
import AVFoundation

enum Stage: Equatable {
	case initializing;
	case missingAPIKey;
	case permissionDenied;
	case idle;
	case recording;
	case processing;
	case responding;
	case error;
}

struct ContentView: View {
	@State private var openAI: OpenAI!
	@State private var audioPlayer = AudioPlayer()
	@State private var audioRecorder: AVAudioRecorder!

	@State private var messages: [Chat] = []
	@State private var stage = Stage.initializing

    var body: some View {
		MissingOpenAIKeyAlert(show: stage == .missingAPIKey)
		RecordingPermissionDeniedAlert(show: stage == .permissionDenied)

		ZStack {
			Color(stage == .error ? Color(hex: "#fecaca") : [.recording, .responding].contains(stage) ? Color.purple : Color(hex: "#F5E6FD"))
				.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
				.animation(.default, value: stage)

			VStack {
				Spacer()

				Rectangle()
					.fill(stage == .error ? Color.red : [.recording, .responding].contains(stage) ?  Color(hex: "#F5E6FD") : Color.purple)
					.frame(width: 100, height: 100)
					.scaleEffect([.recording, .responding].contains(stage) ? 1.3 : 1)
					.animation(.default, value: stage)
					.opacity(stage == .processing ? 0.5 : 1)
					.animation(stage == .processing ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : nil, value: stage)

				Spacer()

				Text(stage == .error ? "Something went wrong" : stage == .recording ? "Listening" : stage == .responding ? "Speaking" : stage == .processing ? "Thinking" : "Tap to speak")
					.foregroundColor(stage == .error ? Color.red : [.recording, .responding].contains(stage) ? .white : .black)
					.font(.custom("Signifier-Light", size: stage == .error ? 35 : 40))
					.animation(.default, value: stage)
					.padding(.bottom, 50)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.onTapGesture {
			Task {
				await handleStateChange()
			}
		}
		.task {
			await prepareForRecording()
		}
		.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
			Task {
				if [.missingAPIKey, .permissionDenied].contains(stage) {
					stage = .initializing
					await prepareForRecording()
				}
			}
		}
	}

	func prepareForRecording() async {
		self.audioPlayer.onFinished() {
			stage = .idle
		}

		do {
			openAI = OpenAI(apiToken: try SettingsBundleHelper.getOpenAIKey().get())
		} catch {
			self.stage = .missingAPIKey
			return
		}

		let session = AVAudioSession.sharedInstance()

		do {
			try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
			try session.setActive(true)

			let allowed = await AVAudioApplication.requestRecordPermission()
			if !allowed {
				self.stage = .permissionDenied
				return
			}

			let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
			audioRecorder = try AVAudioRecorder(url: paths[0].appendingPathComponent("recording.m4a"), settings: [
				AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
				AVSampleRateKey: 12000,
				AVNumberOfChannelsKey: 1,
				AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
			])
			audioRecorder.prepareToRecord()

			self.stage = .idle
		} catch {
			self.stage = .error
		}
	}

	func handleStateChange() async {
		switch stage {
			// Start the recording
			case .idle:
				audioRecorder.record()
				stage = .recording

			// Stop the recording and transcribe it
			case .recording:
				audioRecorder.stop()
				stage = .processing

				do {
					let transcription = try await openAI.audioTranscriptions(query: AudioTranscriptionQuery(file: try Data(contentsOf: audioRecorder.url), fileName: "recording.m4a", model: .whisper_1))
					messages.append(Chat(role: .user, content: transcription.text))

					let completion = try await openAI.chats(query: ChatQuery(model: "gpt-4-turbo-preview", messages: messages))
					let response = completion.choices.first!.message
					messages.append(response)

					let tts = try await openAI.audioCreateSpeech(query: AudioSpeechQuery(model: .tts_1, input: response.content!, voice: .echo, responseFormat: .aac, speed: 1))

					stage = .responding
					self.audioPlayer.play(audio: tts.audioData!)
				} catch {
					self.stage = .error
					print("Could not process response: \(error)")
				}

			// Interrupt the response
			case .responding:
				stage = .idle
				self.audioPlayer.stop()

			// Nothing to do here
			case .processing, .initializing, .permissionDenied, .missingAPIKey, .error:
				break
		}
	}
}

#Preview {
    ContentView()
}
