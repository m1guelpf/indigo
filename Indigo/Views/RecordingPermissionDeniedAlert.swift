import SwiftUI

struct RecordingPermissionDeniedAlert: View {
	var show: Bool

	@State private var isPresented = false

	var body: some View {
		VStack {}.alert(isPresented: $isPresented) {
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
		}.onChange(of: show) { (_, show) in
			isPresented = show
		}
	}
}
