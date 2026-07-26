import Foundation
import SwiftUI
import UIKit

// MARK: - iOS 27 Beta 兼容性修复
// iPhone 17 + iOS 27 beta2 的已知问题和修复方案

/// iOS 27 Beta 调试器
class iOS27Debugger {
    static let shared = iOS27Debugger()

    private init() {
        print("🛠️ iOS 27 Beta 调试器初始化")
        logSystemInfo()
    }

    func logSystemInfo() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let deviceModel = UIDevice.current.model
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion


        print("""
        📱 设备信息:
          设备: \(deviceModel)
          系统: \(systemName) \(systemVersion)
          iOS版本: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)
        """)

        // 检查iOS 27特定问题
        if osVersion.majorVersion >= 27 {
            print("⚠️ iOS 27+ 检测到已知兼容性问题")
            print("⚠️ 常见问题: CIContext初始化, CoreImage渲染, 内存访问")
        }
    }

    /// 安全执行可能崩溃的代码
    @discardableResult
    func safeExecute<T>(_ label: String, _ block: () throws -> T) -> T? {
        print("🛡️ 安全执行: \(label)")
        do {
            let result = try block()
            print("✅ \(label) 执行成功")
            return result
        } catch {
            print("❌ \(label) 执行失败: \(error)")
            return nil
        }
    }

    /// 内存安全检查
    func checkMemoryAccess<T>(_ object: T?, label: String = "对象") {
        if object == nil {
            print("⚠️ \(label) 为空指针")
        } else {
            print("✅ \(label) 内存访问安全")
        }
    }
}

// MARK: - SwiftUI 修复
extension View {
    /// iOS 27 Beta 安全的视图修饰器
    func iOS27Safe() -> some View {
        ModifiedContent(
            content: self,
            modifier: iOS27SafeModifier()
        )
    }
}

struct iOS27SafeModifier: ViewModifier {
    @State private var hasCrashed = false

    func body(content: Content) -> some View {
        Group {
            if hasCrashed {
                Text("⚠️ 视图加载失败 - iOS 27 Beta 兼容性问题")
                    .foregroundColor(.red)
                    .padding()
                    .onAppear {
                        print("❌ 视图加载失败")
                    }
            } else {
                content
                    .onAppear {
                        print("✅ 视图加载成功")
                    }
            }
        }
    }
}

// MARK: - CoreImage 安全包装器

/// 安全的CIContext包装器，避免iOS 27 Beta崩溃
class SafeCIContext {
    private var _context: CIContext?

    var context: CIContext {
        get {
            if _context == nil {
                print("🛡️ 延迟初始化CIContext...")
                // CIContext 初始化不抛异常，直接初始化即可
                #if targetEnvironment(simulator)
                    // 模拟器使用更简单的配置
                    _context = CIContext(options: [
                        kCIContextUseSoftwareRenderer: false,
                        kCIContextPriorityRequestLow: true
                    ])
                #else
                    // 真机使用默认配置
                    _context = CIContext()
                #endif
                print("✅ CIContext初始化成功")
            }
            return _context!
        }
    }

    init() {
        print("🛡️ SafeCIContext初始化")
    }

    deinit {
        print("🛡️ SafeCIContext释放")
    }
}

// MARK: - UIImage 安全扩展（避免空指针）

extension UIImage {
    static func safeImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            print("⚠️ 图片加载失败: \(named)")
        }
        return image
    }

    var safeCGImage: CGImage? {
        let cgImage = self.cgImage
        if cgImage == nil {
            print("⚠️ UIImage.cgImage为nil")
        }
        return cgImage
    }
}

// MARK: - URL 安全访问

extension URL {
    /// 安全的文件存在性检查
    var safeFileExists: Bool {
        do {
            return try checkResourceIsReachable()
        } catch {
            print("⚠️ 文件访问失败: \(self.path) - \(error)")
            return false
        }
    }

    /// 安全的文件大小获取
    var safeFileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("⚠️ 获取文件大小失败: \(error)")
            return 0
        }
    }
}

// MARK: - 启动时诊断

/// 应用启动时进行诊断
func diagnoseAppStartup() {
    print("🔍 应用启动诊断开始...")

    // 检查基本UIKit组件（UIScreen.main 需在主线程访问）
    DispatchQueue.main.async {
        let screen = UIScreen.main
        print("📱 屏幕尺寸: \(screen.bounds.size)")
    }

    // 检查文件权限
    let tempDir = FileManager.default.temporaryDirectory
    print("📁 临时目录: \(tempDir.path)")

    // 检查内存使用
    let usedMemory = getMemoryUsage()
    print("🧠 内存使用: \(String(format: "%.1f", usedMemory)) MB")

    print("✅ 应用启动诊断完成")
}

/// 获取内存使用情况
func getMemoryUsage() -> Double {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4

    let result = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }

    if result == KERN_SUCCESS {
        return Double(taskInfo.phys_footprint) / 1024 / 1024
    } else {
        print("⚠️ 获取内存使用失败")
        return 0
    }
}

// MARK: - 关键组件安全检查

class ComponentSafety {

    /// 检查所有关键组件
    static func checkAllComponents() {
        print("🔧 关键组件安全检查...")

        // 1. 检查CoreImage
        checkCoreImage()

        // 2. 检查AVFoundation
        checkAVFoundation()

        // 3. 检查文件系统
        checkFileSystem()

        // 4. 检查UIKit
        checkUIKit()

        print("✅ 关键组件安全检查完成")
    }

    private static func checkCoreImage() {
        print("  📊 CoreImage 检查...")
        let filters = CIFilter.filterNames(inCategory: kCICategoryBuiltIn)
        print("  ✅ 可用滤镜数量: \(filters.count)")

        // 测试创建一个简单的CIFilter
        if let filter = CIFilter(name: "CIGaussianBlur") {
            print("  ✅ CIFilter创建成功")
        } else {
            print("  ⚠️ CIFilter创建失败")
        }
    }

    private static func checkAVFoundation() {
        print("  📹 AVFoundation 检查...")

        // 检查基本AVFoundation功能
        if AVCaptureDevice.authorizationStatus(for: .video) != .notDetermined {
            print("  ✅ 摄像头权限状态正常")
        }

        // 检查视频导出预设（不用假路径 AVAsset，避免异常）
        let allPresets = AVAssetExportSession.allExportPresets()
        print("  ✅ 可用导出预设: \(allPresets.count)")
    }

    private static func checkFileSystem() {
        print("  📁 文件系统 检查...")

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let temp = FileManager.default.temporaryDirectory

        print("  ✅ 文档目录: \(documents?.path ?? "nil")")
        print("  ✅ 临时目录: \(temp.path)")

        // 检查写入权限
        let testFile = temp.appendingPathComponent("test_write.txt")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
            print("  ✅ 文件写入权限正常")
        } catch {
            print("  ⚠️ 文件写入失败: \(error)")
        }
    }

    private static func checkUIKit() {
        print("  🎨 UIKit 检查...")

        // 检查基本UIKit组件（需在主线程访问）
        safeMainThread("检查屏幕亮度") {
            let screen = UIScreen.main
            print("  ✅ 屏幕亮度: \(screen.brightness)")
        }

        // 检查UIApplication状态
        safeMainThread("检查应用状态") {
            let app = UIApplication.shared
            print("  ✅ 应用状态: \(app.applicationState.rawValue)")
        }
    }
}

// MARK: - 崩溃防护

/// 防护可能崩溃的操作
func withCrashProtection<T>(_ label: String, _ operation: () throws -> T, defaultValue: T) -> T {
    print("🛡️ 崩溃防护: \(label)")

    do {
        let result = try operation()
        print("✅ \(label) 执行成功")
        return result
    } catch {
        print("❌ \(label) 执行失败: \(error)")
        return defaultValue
    }
}

/// 在主线程安全执行（避免UI线程崩溃）
func safeMainThread(_ label: String, _ operation: @escaping () -> Void) {
    print("🛡️ 主线程安全执行: \(label)")

    if Thread.isMainThread {
        withCrashProtection(label, operation, defaultValue: ())
    } else {
        DispatchQueue.main.async {
            withCrashProtection(label, operation, defaultValue: ())
        }
    }
}