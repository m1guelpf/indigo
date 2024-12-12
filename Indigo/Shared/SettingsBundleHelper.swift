import Foundation

class SettingsBundleHelper {
	enum SettingsBundleKeys {
		static let OpenAIKey = "OPENAI_API_KEY"
		static let AppVersionKey = "version_preference"
		static let BuildVersionKey = "build_preference"
	}

	class func getOpenAIKey() -> String? {
		guard let key = UserDefaults.standard.string(forKey: SettingsBundleKeys.OpenAIKey), key.starts(with: "sk-") else {
			return nil
		}

		return key
	}

	class func setVersionAndBuildNumber() {
		let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
		UserDefaults.standard.set(version, forKey: SettingsBundleKeys.AppVersionKey)

		let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
		UserDefaults.standard.set(build, forKey: SettingsBundleKeys.BuildVersionKey)
	}
}
