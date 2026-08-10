import Foundation
import AVFoundation
import SwiftUI

/// 音频调试工具和测试
class AudioDebugTest: ObservableObject {
    @Published var testLogs: [String] = []
    @Published var isTesting = false
    @Published var testResults: [String: String] = [:]

    static let shared = AudioDebugTest()

    /// 运行完整的音频调试测试套件
    func runFullAudioDebugTest(for videoURL: URL) async {
        await MainActor.run {
            self.isTesting = true
            self.testLogs.removeAll()
            self.testResults.removeAll()
        }

        await log("🔊 开始音频调试测试...")
        await log("📹 测试视频: \(videoURL.lastPathComponent)")

        // 测试1: 检查视频资产
        await testVideoAsset(videoURL)

        // 测试2: 检查音频轨道
        await testAudioTracks(videoURL)

        // 测试3: 检查音频处理能力
        await testAudioProcessing()

        // 测试4: 检查音频播放
        await testAudioPlayback()

        await MainActor.run {
            self.isTesting = false
            self.log("✅ 音频调试测试完成")
        }
    }

    // MARK: - 测试方法

    private func testVideoAsset(_ videoURL: URL) async {
        await log("🧪 测试1: 检查视频资产...")

        let asset = AVAsset(url: videoURL)

        do {
            // 检查资产是否可读
            let loadable = try await asset.load(.isReadable)
            await log("✅ 资产可加载: \(loadable)")

            // 检查持续时间
            let duration = try await asset.load(.duration)
            await log("⏱️ 视频时长: \(duration.seconds)秒")

            // 检查轨道
            let tracks = try await asset.load(.tracks)
            await log("📊 总轨道数: \(tracks.count)")

            testResults["test1_asset_loaded"] = "✅"
            testResults["test1_duration"] = "\(duration.seconds)秒"
            testResults["test1_track_count"] = "\(tracks.count)"

        } catch {
            await log("❌ 资产检查失败: \(error.localizedDescription)")
            testResults["test1_asset_loaded"] = "❌ \(error.localizedDescription)"
        }
    }

    private func testAudioTracks(_ videoURL: URL) async {
        await log("🧪 测试2: 检查音频轨道...")

        let asset = AVAsset(url: videoURL)

        do {
            let tracks = try await asset.loadTracks(withMediaType: .audio)

            await log("🎵 检测到的音频轨道: \(tracks.count)")

            if tracks.isEmpty {
                await log("❌ 没有找到音频轨道！")
                await log("⚠️ 提示: 请确保测试视频本身有声音")

                // 检查是否有其他音频轨道类型
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                await log("📊 视频轨道: \(videoTracks.count), 音频轨道: \(audioTracks.count)")

                testResults["test2_audio_tracks"] = "❌ 未发现音频轨道"
                return
            }

            for (index, track) in tracks.enumerated() {
                let formatDescriptions = try await track.load(.formatDescriptions) as? [CMFormatDescription]
                var formatInfo = "未知格式"

                if let format = formatDescriptions?.first,
                   let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee {
                    formatInfo = String(format: "%.0f Hz, %.0f声道",
                                      audioDesc.mSampleRate,
                                      audioDesc.mChannelsPerFrame)
                }

                await log("🎵 音频轨道 \(index+1): \(formatInfo)")
            }

            testResults["test2_audio_tracks"] = "✅ 找到 \(tracks.count) 个音频轨道"

        } catch {
            await log("❌ 音频轨道检查失败: \(error.localizedDescription)")
            testResults["test2_audio_tracks"] = "❌ \(error.localizedDescription)"
        }
    }

    private func testAudioProcessing() async {
        await log("🧪 测试3: 检查音频处理能力...")

        // 创建临时音频文件来测试处理能力
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio_test_\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        // 使用AVAssetReader/Writer测试
        let testVideoURL = URL(fileURLWithPath: "/System/Library/Audio/UISounds/begin_video_record.caf")
        let testAsset = AVAsset(url: testVideoURL)

        do {
            // 尝试创建一个简单的音频写入器
            guard let writer = try? AVAssetWriter(outputURL: tempURL, fileType: .m4a) else {
                await log("❌ 无法创建音频写入器")
                testResults["test3_audio_writer"] = "❌ 写入器创建失败"
                return
            }

            // 尝试创建音频写入器输入
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000
            ]

            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = false

            if writer.canAdd(audioInput) {
                writer.add(audioInput)
                await log("✅ 音频写入器设置成功")
                testResults["test3_audio_writer"] = "✅ 写入器配置正常"
            } else {
                await log("❌ 无法添加音频输入")
                testResults["test3_audio_writer"] = "❌ 输入不可用"
            }

            // 清理临时文件
            try? FileManager.default.removeItem(at: tempURL)

        } catch {
            await log("❌ 音频处理测试失败: \(error.localizedDescription)")
            testResults["test3_audio_processing"] = "❌ \(error.localizedDescription)"
        }
    }

    private func testAudioPlayback() async {
        await log("🧪 测试4: 检查音频播放...")

        // 播放一个系统声音
        #if os(iOS)
        AudioServicesPlaySystemSound(1103) // 标准系统声音
        await log("🔊 播放了系统声音 #1103")

        // 检查音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            await log("✅ 音频会话配置成功")
            testResults["test4_audio_session"] = "✅ 配置正常"
        } catch {
            await log("❌ 音频会话配置失败: \(error.localizedDescription)")
            testResults["test4_audio_session"] = "❌ \(error.localizedDescription)"
        }
        #else
        await log("⚠️ 非iOS环境，跳过系统声音测试")
        testResults["test4_audio_session"] = "⚠️ 跳过（非iOS）"
        #endif

        testResults["test4_playback_test"] = "🔊 系统声音已播放"
    }

    // MARK: - 简化测试

    /// 运行快速音频检查
    func quickAudioCheck(for videoURL: URL) async -> Bool {
        await log("🔍 快速音频检查...")

        let asset = AVAsset(url: videoURL)

        do {
            // 快速检查是否有音频轨道
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            await log("🎵 音频轨道数: \(audioTracks.count)")

            if audioTracks.isEmpty {
                await log("❌ 警告: 视频没有音频轨道")
                return false
            }

            // 检查第一个音频轨道的格式
            let track = audioTracks.first!
            let formatDescriptions = try await track.load(.formatDescriptions) as? [CMFormatDescription]

            await log("✅ 视频包含音频轨道")
            return true

        } catch {
            await log("❌ 快速检查失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 获取音频轨道信息
    func getAudioTrackInfo(for videoURL: URL) async -> [String: Any] {
        var info: [String: Any] = [:]

        do {
            let asset = AVAsset(url: videoURL)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)

            info["track_count"] = audioTracks.count

            if !audioTracks.isEmpty {
                if let formatDescriptions = try await audioTracks.first?.load(.formatDescriptions) as? [CMFormatDescription],
                   let format = formatDescriptions.first,
                   let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee {
                    info["sample_rate"] = audioDesc.mSampleRate
                    info["channels"] = audioDesc.mChannelsPerFrame
                    info["format"] = "Linear PCM"
                }
            }

        } catch {
            info["error"] = error.localizedDescription
        }

        return info
    }

    /// 测试音频合并的简化版本
    func testSimpleAudioMerge(testVideoURL: URL) async -> Bool {
        await log("🔄 测试音频合并...")

        // 创建一个简化的测试
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio_merge_test_\(UUID().uuidString)")
            .appendingPathExtension("mp4")

        // 测试是否能够正常写入
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            await log("❌ 无法创建视频写入器")
            return false
        }

        // 尝试添加音频输入
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]

        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = false

        let canAddAudio = writer.canAdd(audioInput)
        await log("✅ 音频写入器测试: \(canAddAudio ? "支持音频" : "不支持音频")")

        // 清理临时文件
        try? FileManager.default.removeItem(at: outputURL)

        return canAddAudio
    }

    // MARK: - 日志工具

    private func log(_ message: String) async {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"

        await MainActor.run {
            self.testLogs.append(logMessage)
            print(logMessage)
        }
    }
}

// MARK: - 调试视图

struct AudioDebugView: View {
    @StateObject private var debugger = AudioDebugTest.shared
    @State private var selectedVideoURL: URL?

    var body: some View {
        List {
            Section("音频调试控制") {
                Button(action: {
                    Task {
                        await debugger.runFullAudioDebugTest(for: URL(fileURLWithPath: "/tmp/test.mp4"))
                    }
                }) {
                    Label("运行完整测试", systemImage: "play.circle")
                }
                .disabled(debugger.isTesting)

                if debugger.isTesting {
                    ProgressView()
                        .padding()
                }
            }

            if !debugger.testLogs.isEmpty {
                Section("测试日志") {
                    ForEach(debugger.testLogs, id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            if !debugger.testResults.isEmpty {
                Section("测试结果") {
                    ForEach(debugger.testResults.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(value)
                                .font(.caption)
                                .foregroundColor(value.hasPrefix("❌") ? .red :
                                                value.hasPrefix("⚠️") ? .orange : .green)
                        }
                    }
                }
            }
        }
        .navigationTitle("音频调试")
    }
}