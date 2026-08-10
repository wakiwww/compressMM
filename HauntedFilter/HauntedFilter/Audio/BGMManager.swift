import Foundation
import AVFoundation

/// BGM管理器，负责加载和管理BGM配乐
class BGMManager: ObservableObject {
    @Published private(set) var availableBGM: [BGM] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// 共享实例
    static let shared = BGMManager()

    private let bgmDirectory: URL
    private let fileManager = FileManager.default

    private init() {
        // 获取主bundle中的BGM文件夹路径
        if let bundleURL = Bundle.main.url(forResource: "bgm", withExtension: nil) {
            bgmDirectory = bundleURL
        } else {
            // 如果bundle中没有，使用Documents目录
            bgmDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("bgm")
        }
    }

    /// 加载所有可用的BGM
    func loadAvailableBGM() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // 确保目录存在
            try ensureBGMDirectoryExists()

            // 加载所有音频文件
            let bgmFiles = try fileManager.contentsOfDirectory(
                at: bgmDirectory,
                includingPropertiesForKeys: [.contentTypeKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ).filter { url in
                isAudioFile(url: url)
            }

            // 为每个文件创建BGM模型
            var loadedBGM: [BGM] = []

            for fileURL in bgmFiles {
                if let bgm = await createBGM(from: fileURL) {
                    loadedBGM.append(bgm)
                }
            }

            // 按文件名排序
            loadedBGM.sort { $0.displayName < $1.displayName }

            await MainActor.run {
                self.availableBGM = loadedBGM
                self.isLoading = false
                print("加载了 \(loadedBGM.count) 个BGM配乐")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载BGM失败: \(error.localizedDescription)"
                self.isLoading = false
                print("加载BGM失败: \(error)")
            }
        }
    }

    /// 获取默认的BGM（如果没有选择）
    func defaultBGM() -> BGM? {
        availableBGM.first
    }

    /// 根据名称查找BGM
    func bgm(named name: String) -> BGM? {
        availableBGM.first { $0.name == name }
    }

    /// 获取BGM的URL
    func url(for bgm: BGM) -> URL {
        bgm.url
    }

    /// 确保BGM目录存在
    private func ensureBGMDirectoryExists() throws {
        if !fileManager.fileExists(atPath: bgmDirectory.path) {
            try fileManager.createDirectory(at: bgmDirectory, withIntermediateDirectories: true)
        }
    }

    /// 检查是否为音频文件
    private func isAudioFile(url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let contentType = resourceValues.contentType else {
            return false
        }

        return contentType.conforms(to: .audio)
    }

    /// 从URL创建BGM模型
    private func createBGM(from url: URL) async -> BGM? {
        let fileName = url.deletingPathExtension().lastPathComponent
        let displayName = formatDisplayName(fileName)

        do {
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration).seconds

            // 过滤掉过短或过长的音频（小于1秒或大于10分钟）
            guard duration >= 1.0 && duration <= 600.0 else {
                print("跳过BGM: \(fileName)，时长 \(duration) 秒不符合要求")
                return nil
            }

            return BGM(
                name: fileName,
                displayName: displayName,
                url: url,
                duration: duration
            )
        } catch {
            print("创建BGM失败 \(fileName): \(error)")
            return nil
        }
    }

    /// 格式化显示名称：将文件名转换为友好的显示名称
    private func formatDisplayName(_ fileName: String) -> String {
        let name = fileName.replacingOccurrences(of: "_", with: " ")
        let components = name.components(separatedBy: " ")
        let capitalizedComponents = components.map { $0.prefix(1).capitalized + $0.dropFirst() }
        return capitalizedComponents.joined(separator: " ")
    }
}