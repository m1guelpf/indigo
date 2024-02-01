import SwiftUI

struct MissingOpenAIKeyAlert: View {
	var show: Bool

	@State private var isPresented = false

	var body: some View {
		VStack {}.alert(isPresented: $isPresented) {
			Alert(
				title: Text("OpenAI Key Missing"),
				message: Text("To use Indigo, you must provide a valid OpenAI API key. You can get one from their developer portal."),
				primaryButton: .default(Text("Enter Key"), action: {
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
