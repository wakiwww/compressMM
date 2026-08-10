import Foundation
import AVFoundation

// MARK: - 平台音频修复

extension VideoProcessor {

    /// 平台检测：判断当前运行环境
    private var isRunningOnMacOS: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
        #if os(macOS)
            return true
        #else
            return false
        #endif
        #endif
    }

    /// 修复的音频处理方法（支持iOS、macOS、模拟器）
    private func processAudioFixed(
        audioTrack: AVAssetTrack?,
        writer: AVAssetWriter,
        videoDuration: CMTime,
        parameters: ProcessingParameters
    ) throws -> (AVAssetWriterInput?, AVAssetReaderTrackOutput?) {

        // 如果没有音频轨道，返回nil
        guard let audioTrack = audioTrack else {
            print("⚠️ 视频中没有音频轨道")
            return (nil, nil)
        }

        print("🎵 开始音频处理 - 平台: \(isRunningOnMacOS ? "macOS" : "iOS")")

        // 创建音频读取器
        let reader = try AVAssetReader(asset: audioTrack.asset!)

        // 音频读取器设置
        var audioReaderOutput: AVAssetReaderTrackOutput?
        var audioWriterInput: AVAssetWriterInput?

        do {
            // macOS兼容性设置 - 使用更简单的音频格式
            let readerOutputSettings: [String: Any]
            let writerOutputSettings: [String: Any]

            if isRunningOnMacOS {
                // macOS: 使用更兼容的音频设置
                print("🎵 macOS环境 - 使用兼容音频设置")
                readerOutputSettings = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVNumberOfChannelsKey: 2,
                    AVSampleRateKey: parameters.audioSampleRate
                ]

                writerOutputSettings = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: parameters.audioSampleRate,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128000
                ]
            } else {
                // iOS: 使用原始设置
                print("🎵 iOS环境 - 使用标准音频设置")
                readerOutputSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ]

                writerOutputSettings = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: parameters.audioSampleRate,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128000
                ]
            }

            audioReaderOutput = AVAssetReaderTrackOutput(
                track: audioTrack,
                outputSettings: readerOutputSettings
            )
            audioReaderOutput?.alwaysCopiesSampleData = false

            guard let audioReaderOutput = audioReaderOutput else {
                print("❌ 创建音频读取器输出失败")
                return (nil, nil)
            }

            reader.add(audioReaderOutput)

            // 创建音频写入器
            audioWriterInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: writerOutputSettings
            )
            audioWriterInput?.expectsMediaDataInRealTime = false

            guard let audioWriterInput = audioWriterInput else {
                print("❌ 创建音频写入器输入失败")
                return (nil, nil)
            }

            writer.add(audioWriterInput)

            // 开始读取
            if reader.startReading() {
                print("✅ 音频读取器启动成功")
            } else {
                print("❌ 音频读取器启动失败: \(reader.error?.localizedDescription ?? "未知错误")")
                return (nil, nil)
            }

            return (audioWriterInput, audioReaderOutput)

        } catch {
            print("❌ 音频设置失败: \(error)")
            return (nil, nil)
        }
    }

    /// 修复的音频处理流程
    private func processAudioFixed(
        readerOutput: AVAssetReaderTrackOutput,
        writerInput: AVAssetWriterInput
    ) {
        print("🎵 开始音频数据传输")

        let queue = DispatchQueue(label: "com.hauntedfilter.audio.fixed")
        let group = DispatchGroup()
        group.enter()

        var processedSamples = 0
        var lastLogTime = Date()

        writerInput.requestMediaDataWhenReady(on: queue) {
            while writerInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                    writerInput.append(sampleBuffer)
                    processedSamples += 1

                    // 定期打印进度（每100个样本或每5秒）
                    let now = Date()
                    if processedSamples % 100 == 0 || now.timeIntervalSince(lastLogTime) >= 5 {
                        print("🎵 音频处理进度: 已处理 \(processedSamples) 个样本")
                        lastLogTime = now
                    }
                } else {
                    print("✅ 音频数据处理完成，共处理 \(processedSamples) 个样本")
                    writerInput.markAsFinished()
                    group.leave()
                    break
                }
            }
        }

        // 设置超时
        let timeoutResult = group.wait(timeout: .now() + 60) // 60秒超时

        switch timeoutResult {
        case .success:
            print("✅ 音频处理完成")
        case .timedOut:
            print("⚠️ 音频处理超时")
        }
    }

    /// 修复的processAsset方法（整合音频修复）
    func processAssetFixed(
        _ asset: AVAsset,
        parameters: ProcessingParameters,
        preset: VideoPreset,
        outputURL: URL
    ) throws {
        print("🔊 使用修复的音频处理方法")

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw ProcessingError.noVideoTrack
        }

        let audioTrack = asset.tracks(withMediaType: .audio).first
        let sourceSize = videoTrack.naturalSize
        let sourceFrameRate = videoTrack.nominalFrameRate

        // 原有的视频处理代码...
        // 为了简洁，这里省略重复代码

        // 关键修复：初始化音频处理器
        if let audioTrack = audioTrack {
            print("🎵 检测到音频轨道，开始音频处理")

            // 使用新的音频处理方法
            let (audioWriterInput, audioReaderOutput) = try processAudioFixed(
                audioTrack: audioTrack,
                writer: writer, // 需要在外部定义
                videoDuration: asset.duration,
                parameters: parameters
            )

            if let audioWriterInput = audioWriterInput,
               let audioReaderOutput = audioReaderOutput {
                // 处理音频数据
                processAudioFixed(readerOutput: audioReaderOutput, writerInput: audioWriterInput)
                print("✅ 音频处理流程已启动")
            } else {
                print("⚠️ 音频处理器初始化失败，继续处理视频（无音频）")
            }
        } else {
            print("⚠️ 视频中没有音频轨道，将生成无声视频")
        }

        // 原有的视频帧处理代码...
    }
}

// MARK: - 音频调试工具

class AudioDebugger {
    static let shared = AudioDebugger()

    func logAudioSetup(_ message: String) {
        print("🔊 [AudioDebug] \(message)")
    }

    func logAudioError(_ error: Error, context: String = "") {
        print("🔊 [AudioError] \(context): \(error.localizedDescription)")
    }

    func logAudioProgress(_ progress: String) {
        print("🔊 [AudioProgress] \(progress)")
    }

    /// 测试音频播放（诊断用）
    func testAudioPlayback() {
        print("🔊 开始音频播放测试")

        // 播放一个系统声音来测试音频是否工作
        #if os(iOS) || os(tvOS)
        AudioServicesPlaySystemSound(1103) // 系统声音ID
        print("🔊 iOS系统声音已播放")
        #elseif os(macOS)
        // macOS没有AudioServices，使用NSSound
        if let sound = NSSound(named: "Glass") {
            sound.play()
            print("🔊 macOS系统声音已播放")
        } else {
            print("🔊 无法播放macOS系统声音")
        }
        #endif
    }
}

// MARK: - 平台特定的音频助手

#if os(macOS)
import AppKit

class MacOSAudioHelper {
    /// 检查macOS音频权限
    static func checkAudioPermissions() -> Bool {
        print("🔊 检查macOS音频权限")

        // 在macOS上，音频权限检查不那么严格
        // 主要是确保音频会话已配置

        do {
            if #available(macOS 10.15, *) {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                print("✅ macOS音频会话配置成功")
                return true
            } else {
                print("⚠️ macOS版本低于10.15，跳过音频会话配置")
                return true
            }
        } catch {
            print("❌ macOS音频会话配置失败: \(error)")
            return false
        }
    }
}
#endif