import Foundation

/// 应用配置文件 - 包含 App Store 提交所需的 URL 配置
struct AppConfig {

    // MARK: - App Store 提交所需的 URL
    // 重要：在部署 Vercel 网站后更新这些 URL

    /// 技术支持 URL - 用于 App Store 提交
    static let supportURL = "https://reverie-app.com/support"

    /// 营销网址 - 用于 App Store 提交
    static let marketingURL = "https://reverie-app.com"

    /// 隐私政策 URL
    static let privacyPolicyURL = "https://reverie-app.com/privacy"

    /// 使用条款 URL
    static let termsOfUseURL = "https://reverie-app.com/terms"

    // MARK: - 应用信息
    static let appName = "Rêverie"
    static let appVersion = "1.0"
    static let appBuildNumber = "1"

    // MARK: - 联系方式
    static let supportEmail = "support@reverie-app.com"
    static let privacyEmail = "privacy@reverie-app.com"
    static let legalEmail = "legal@reverie-app.com"

    // MARK: - URL 生成方法

    /// 获取技术支持 URL
    static func supportURL() -> URL {
        return URL(string: supportURL)!
    }

    /// 获取营销网址 URL
    static func marketingURL() -> URL {
        return URL(string: marketingURL)!
    }

    /// 获取隐私政策 URL
    static func privacyPolicyURL() -> URL {
        return URL(string: privacyPolicyURL)!
    }

    /// 获取使用条款 URL
    static func termsOfUseURL() -> URL {
        return URL(string: termsOfUseURL)!
    }

    /// 获取支持邮箱 URL
    static func supportEmailURL() -> URL {
        return URL(string: "mailto:\(supportEmail)")!
    }
}