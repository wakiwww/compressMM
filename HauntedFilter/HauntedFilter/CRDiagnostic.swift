import Foundation
import OSLog
import AVFoundation
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

/// 崩溃恢复和诊断系统
class CRDiagnostic {
    static let shared = CRDiagnostic()
    private let logger = Logger(subsystem: "com.hauntedfilter.diagnostic", category: "app")

    /// 启动诊断
    func startDiagnostic() {
        print("🔍 CRDiagnostic 启动 - 诊断开始")
        logger.log("🔍 CRDiagnostic 启动")

        // 记录启动信息
        recordSystemInfo()

        // 检查关键组件
        checkCriticalComponents()
    }

    /// 记录系统信息
    private func recordSystemInfo() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"

        logger.log("系统版本: \(osVersionString)")

        print("📱 系统信息:")
        print("  - 版本: \(osVersionString)")
        print("  - 处理器核心: \(ProcessInfo.processInfo.processorCount)")
        print("  - 内存: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB")
        print("  - 系统运行时间: \(ProcessInfo.processInfo.systemUptime)s")

        #if canImport(UIKit)
        let device = UIDevice.current
        logger.log("设备: \(device.name)")
        logger.log("模型: \(device.model)")
        logger.log("系统名称: \(device.systemName)")

        print("  - 设备: \(device.name)")
        print("  - 型号: \(device.model)")
        print("  - 系统: \(device.systemName)")
        #else
        print("  - 环境: macOS 原生")
        #endif
    }

    /// 检查关键组件
    private func checkCriticalComponents() {
        print("🔧 检查关键组件...")

        // 检查 Core Image 可用性
        checkCoreImage()

        // 检查 AVFoundation 可用性
        checkAVFoundation()

        // 检查文件访问权限
        checkFileAccess()
    }

    /// 检查 Core Image
    private func checkCoreImage() {
        print("🎨 检查 Core Image...")

        var success = false
        var errorMessage: String? = nil

        // 使用非常安全的初始化方式
        do {
            var context: CIContext?

            // 尝试多种初始化方式
            #if os(iOS)
            if #available(iOS 15.0, *) {
                context = try? CIContext(options: [CIContextOption.workingColorSpace: NSNull()])
            } else {
                context = CIContext()
            }
            #else
            context = CIContext()
            #endif

            if context != nil {
                success = true
                print("  ✅ CIContext 创建成功")
                logger.log("✅ CIContext 创建成功")
            } else {
                errorMessage = "CIContext 返回 nil"
            }
        }

        // 检查可用的 CIFilter
        let filterNames = CIFilter.filterNames(inCategory: nil)
        if !filterNames.isEmpty {
            print("  ✅ 可用的 CIFilter 数量: \(filterNames.count)")
            logger.log("ℹ️ 可用的 CIFilter 数量: \(filterNames.count)")
        } else {
            print("  ⚠️ 没有找到可用的 CIFilter")
            logger.log("⚠️ 没有找到可用的 CIFilter")
        }
    }

    /// 检查 AVFoundation
    private func checkAVFoundation() {
        print("🎬 检查 AVFoundation...")

        // 检查是否能创建基础对象
        do {
            // 1. AVAsset 测试
            let testAsset = AVAsset(url: URL(fileURLWithPath: "/tmp/test.mp4"))
            print("  ✅ AVAsset 创建测试完成")
            logger.log("✅ AVAsset 创建测试完成")

            // 2. AVAssetWriter 测试（简化）
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test_writer_\(UUID().uuidString)")
                .appendingPathExtension("mp4")

            if let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) {
                print("  ✅ AVAssetWriter 创建测试完成")
                logger.log("✅ AVAssetWriter 创建测试完成")

                // 尝试创建视频输入
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 640,
                    AVVideoHeightKey: 480
                ]

                let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                if writer.canAdd(input) {
                    writer.add(input)
                    print("  ✅ 视频输入添加测试完成")
                    logger.log("✅ 视频输入添加测试完成")
                } else {
                    print("  ⚠️ 无法添加视频输入")
                    logger.log("⚠️ 无法添加视频输入")
                }
            } else {
                print("  ⚠️ AVAssetWriter 创建失败（可能正常）")
                logger.log("⚠️ AVAssetWriter 创建失败")
            }

        } catch {
            print("  ❌ AVFoundation 测试失败: \(error)")
            logger.error("❌ AVFoundation 测试失败: \(error.localizedDescription)")
        }
    }

    /// 检查文件访问权限
    private func checkFileAccess() {
        print("📁 检查文件访问权限...")

        let tempDir = FileManager.default.temporaryDirectory
        print("  - 临时目录: \(tempDir.path)")

        // 检查是否能创建临时文件
        do {
            let testURL = tempDir.appendingPathComponent("cr_diagnostic_test.txt")
            let testData = "Test Data".data(using: .utf8)!

            try testData.write(to: testURL)

            // 读取检查
            if FileManager.default.fileExists(atPath: testURL.path) {
                print("  ✅ 文件读写测试通过")
                logger.log("✅ 文件读写测试通过")

                // 清理测试文件
                try? FileManager.default.removeItem(at: testURL)
            } else {
                print("  ❌ 文件读取检查失败")
                logger.log("❌ 文件读取检查失败")
            }

        } catch {
            print("  ❌ 文件写入测试失败: \(error)")
            logger.error("❌ 文件写入测试失败: \(error.localizedDescription)")
        }
    }

    /// 安全执行（捕获异常）
    func safeExecute<T>(_ action: () throws -> T, fallback: T, context: String) -> T {
        do {
            print("⚡ 安全执行: \(context)")
            let result = try action()
            logger.log("✅ 安全执行成功: \(context)")
            return result
        } catch {
            logger.error("❌ 安全执行失败 - \(context): \(error.localizedDescription)")
            print("  ❌ \(context) 失败: \(error)")
            return fallback
        }
    }

    /// 记录启动完成
    func logAppLaunchCompleted() {
        logger.log("🚀 应用启动完成")
        print("🚀 应用启动完成")
    }

    /// 记录错误
    func logError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? "\(error)" : "\(context): \(error)"
        logger.error("🚨 \(message)")
        print("🚨 \(message)")
    }

    /// 记录信息
    func logInfo(_ message: String) {
        logger.log("ℹ️ \(message)")
        print("ℹ️ \(message)")
    }
}