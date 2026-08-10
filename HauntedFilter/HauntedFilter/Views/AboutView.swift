import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    // URLs from AppConfig for App Store submission
    private let supportURL = AppConfig.supportURL()
    private let marketingURL = AppConfig.marketingURL()
    private let privacyPolicyURL = AppConfig.privacyPolicyURL()
    private let termsOfUseURL = AppConfig.termsOfUseURL()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Info Section
                    appInfoSection

                    // Support Links Section
                    supportLinksSection

                    // Legal Links Section
                    legalLinksSection

                    // App Version
                    versionSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("关于")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            #endif
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rêverie")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("引领画质新潮流")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "#888888"))

            Divider()
                .background(Color(hex: "#1C1C1C"))

            Text("Rêverie 是一款创新视频处理工具，通过先进的算法为您的视频添加独特的艺术效果。")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#888888"))
                .lineSpacing(4)
        }
    }

    // MARK: - Support Links Section

    private var supportLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支持与联系")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Divider()
                .background(Color(hex: "#1C1C1C"))

            Link(destination: supportURL) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("技术支持")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        Text("获取帮助和故障排除")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#888888"))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.vertical, 8)
            }

            Link(destination: marketingURL) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("官方网站")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        Text("了解更多功能和更新")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#888888"))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Legal Links Section

    private var legalLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("法律信息")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Divider()
                .background(Color(hex: "#1C1C1C"))

            Link(destination: privacyPolicyURL) {
                HStack {
                    Text("隐私政策")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.vertical, 8)
            }

            Link(destination: termsOfUseURL) {
                HStack {
                    Text("使用条款")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Version Section

    private var versionSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("版本 \(AppConfig.appVersion) (\(AppConfig.appBuildNumber))")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#888888"))

            Text("© 2024 \(AppConfig.appName)")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#888888"))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AboutView()
}