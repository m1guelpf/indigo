import OpenAI
import SwiftUI
import AVFoundation


enum Stage: Equatable {
	case initializing;
	case permissionDenied;
	case idle;
	case recording;
	case processing;
	case responding;
}

struct ContentView: View {
	@Environment(\.openAI) var openAI: OpenAI!;

	@State private var stage = Stage.initializing
	@State private var messages: [Chat] = []
	@State private var audioPlayer = AudioPlayer()
	@State private var audioRecorder: AVAudioRecorder!
	
	var isPermissionDenied: Binding<Bool> {
		Binding(
			get: { self.stage == .permissionDenied },
			set: { _ in }
		)
	}

    var body: some View {
		ZStack {
			Color([.recording, .responding].contains(stage) ? Color.purple : Color(hex: "#F5E6FD"))
				.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
				.animation(.default, value: stage)

			VStack {
				Spacer()
				
				Rectangle()
					.fill([.recording, .responding].contains(stage) ?  Color(hex: "#F5E6FD") : Color.purple)
					.frame(width: 100, height: 100)
					.scaleEffect([.recording, .responding].contains(stage) ? 1.3 : 1)
					.animation(.default, value: stage)
					.opacity(stage == .processing ? 0.5 : 1)
					.animation(stage == .processing ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : nil, value: stage)
				
				Spacer()
				
				Text(stage == .recording ? "Listening" : stage == .responding ? "Speaking" : stage == .processing ? "Thinking" : "Tap to speak")
					.foregroundColor([.recording, .responding].contains(stage) ? .white : .black)
					.font(.custom("Signifier-Light", size: 40))
					.animation(.default, value: stage)
					.padding(.bottom, 50)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.onAppear {
			prepareForRecording()
		}.alert(isPresented: isPermissionDenied) {
			Alert(
				title: Text("Microphone access denied"),
				message: Text("Indigo needs access to your microphone to transcribe your speech. Please enable access in the Settings app."),
				primaryButton: .default(Text("Open Settings"), action: {
					if let settingsURL = URL(string: UIApplication.openSettingsURLString),
					   UIApplication.shared.canOpenURL(settingsURL) {
						UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
					}
				}),
				secondaryButton: .destructive(Text("Exit App"), action: {
					exit(0)
				})
			)
			
		}
		.onTapGesture {
			switch stage {
				// Start the recording
				case .idle:
					audioRecorder.record()
					stage = .recording
					break;

				// Stop the recording and transcribe it
				case .recording:
					audioRecorder.stop()
					stage = .processing
					do {
						openAI.audioTranscriptions(query: AudioTranscriptionQuery(file: try Data(contentsOf: audioRecorder.url), fileName: "recording.m4a", model: .whisper_1)) { result in
							do {
								messages.append(Chat(role: .user, content: try result.get().text))

								openAI.chats(query: ChatQuery(model: "gpt-4-turbo-preview", messages: messages)) { result in
									do {
										messages.append(try result.get().choices.first!.message)
										let response = messages.last!.content!
										
										openAI.audioCreateSpeech(query: AudioSpeechQuery(model: .tts_1, input: response, voice: .echo, responseFormat: .aac, speed: 1)) { result in
											do {
												stage = .responding

												self.audioPlayer.play(audio: try result.get().audioData!)
											} catch {
												print("Could not create speech. \(error)")
											}
										}
									} catch {
										print("Could not get chat response. \(error)")
									}
								}
							} catch {
								print("Could not transcribe recording. \(error)")
							}
						}
					} catch {
						print("Could not load recording: \(error)")
					}
					break;

				// Interrupt the response
				case .responding:
					self.audioPlayer.stop()
					stage = .idle
					break

				// Nothing to do here
				case .processing, .initializing, .permissionDenied:
					break
			}
		}
	}
	
	func prepareForRecording() {
		self.audioPlayer.onFinished() {_ in
			stage = .idle
		}
		
		let session = AVAudioSession.sharedInstance()
		
		do {
			try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
			try session.setActive(true)
			AVAudioApplication.requestRecordPermission { allowed in
				if !allowed {
					self.stage = .permissionDenied
				}
			}

			audioRecorder = try AVAudioRecorder(url: getDocumentsDirectory().appendingPathComponent("recording.m4a"), settings: [
				AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
				AVSampleRateKey: 12000,
				AVNumberOfChannelsKey: 1,
				AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
			])
			audioRecorder.prepareToRecord()

			if self.stage != .permissionDenied {
				self.stage = .idle
			}
		} catch {
			print("Could not prepare recording")
		}
	}
	
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
	var onFinished: ((Bool) -> Void)?
	var audioPlayer: AVAudioPlayer?
	
	func onFinished(_ cb: @escaping (Bool) -> Void) {
		self.onFinished = cb
	}
	
	func play(audio: Data) {
		let audioPlayer = try! AVAudioPlayer(data: audio)
		audioPlayer.delegate = self

		self.audioPlayer = audioPlayer
		audioPlayer.play()
	}
	
	func stop() {
		self.audioPlayer?.stop()
	}

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		onFinished?(flag)
	}
}

#Preview {
    ContentView()
}
