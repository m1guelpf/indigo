import SwiftUI

@main
struct IndigoApp: App {
    var body: some Scene {
        WindowGroup {
			ContentView().onAppear {
				SettingsBundleHelper.setVersionAndBuildNumber()
			}
		}
	}
}
