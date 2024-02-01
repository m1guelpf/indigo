import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
	var onFinished: (() -> Void)?
	var audioPlayer: AVAudioPlayer?

	func onFinished(_ cb: @escaping () -> Void) {
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
		onFinished?()
	}
}
