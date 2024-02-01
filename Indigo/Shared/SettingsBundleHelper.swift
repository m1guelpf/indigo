import Foundation

class SettingsBundleHelper {
	struct SettingsBundleKeys {
		static let OpenAIKey = "OPENAI_API_KEY"
		static let AppVersionKey = "version_preference"
		static let BuildVersionKey = "build_preference"
	}

	class func getOpenAIKey() -> Result<String, Error> {
		let key = UserDefaults.standard.string(forKey: SettingsBundleKeys.OpenAIKey)

		if key != nil && key!.starts(with: "sk-") {
			return .success(key!)
		}

		return .failure(NSError(domain: "SettingsBundleHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not found or invalid"]))
	}

	class func setVersionAndBuildNumber() {
		let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
		UserDefaults.standard.set(version, forKey: "version_preference")

		let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
		UserDefaults.standard.set(build, forKey: "build_preference")
	}
}
