import SwiftUI

@main
struct HauntedFilterApp: App {
    init() {
        // 启动诊断信息
        print("🚀 HauntedFilterApp 初始化")
        print("📱 iOS 版本: \(ProcessInfo.processInfo.operatingSystemVersion)")
        print("💻 开始简化启动以避免崩溃")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    print("✅ ContentView 出现 - 应用启动成功")
                }
        }
    }
}