import AVFoundation

extension AVAudioPCMBuffer {
	func toData() -> Data? {
		guard let audioBuffer = self.int16ChannelData else { return nil }
		let channelCount = Int(self.format.channelCount)
		let frameLength = self.frameLength
		let samples = audioBuffer.pointee
		let data = Data(bytes: samples, count: Int(frameLength) * channelCount * MemoryLayout<Int16>.size)
		return data
	}
}
