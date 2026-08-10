import Foundation
import AVFoundation

/// BGM配乐模型
struct BGM: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let displayName: String
    let url: URL
    let duration: TimeInterval

    /// 获取BGM的时长
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func == (lhs: BGM, rhs: BGM) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// 创建一个适配视频时长的BGM（简化版本）
    /// - Parameters:
    ///   - videoDuration: 视频时长（秒）
    /// - Returns: 返回可能的循环或裁剪后的BGM URL，如果失败返回原始URL
    func adaptedBGM(for videoDuration: TimeInterval) async -> URL? {
        guard videoDuration > 0 else { return nil }

        // 如果BGM时长等于视频时长，直接返回
        if abs(duration - videoDuration) < 0.5 {
            return url
        }

        do {
            // 如果视频时长小于BGM时长，裁剪BGM
            if videoDuration < duration {
                return try await cutBGM(from: url, to: videoDuration)
            }
            // 如果BGM时长小于视频时长，循环BGM
            else {
                return try await loopBGM(from: url, for: videoDuration)
            }
        } catch {
            print("BGM适配失败，返回原始URL: \(error)")
            return url // 返回原始URL作为后备
        }
    }

    /// 裁剪BGM
    private func cutBGM(from sourceURL: URL, to targetDuration: TimeInterval) async throws -> URL {
        guard targetDuration > 0 else { return nil }

        let asset = AVAsset(url: sourceURL)
        let duration = await asset.load(.duration).seconds

        guard targetDuration <= duration else { return nil }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bgm_cut_\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        do {
            let composition = AVMutableComposition()

            // 获取音频轨道
            let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )

            let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first!
            let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: targetDuration, preferredTimescale: 600))

            try compositionAudioTrack?.insertTimeRange(
                timeRange,
                of: sourceAudioTrack,
                at: .zero
            )

            // 导出
            let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetAppleM4A
            )
            exportSession?.outputURL = outputURL
            exportSession?.outputFileType = .m4a
            exportSession?.timeRange = timeRange

            return try await withCheckedThrowingContinuation { continuation in
                exportSession?.exportAsynchronously {
                    switch exportSession?.status {
                    case .completed:
                        continuation.resume(returning: outputURL)
                    case .failed:
                        if let error = exportSession?.error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(throwing: BGMError.cutFailed)
                        }
                    default:
                        continuation.resume(throwing: BGMError.cutFailed)
                    }
                }
            }
        }
    }

    /// 循环BGM
    private func loopBGM(from sourceURL: URL, for targetDuration: TimeInterval) async -> URL? {
        guard targetDuration > 0 else { return nil }

        let asset = AVAsset(url: sourceURL)
        let bgmDuration = await asset.load(.duration).seconds
        guard bgmDuration > 0 else { return nil }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bgm_loop_\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        do {
            let composition = AVMutableComposition()

            // 获取音频轨道
            let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )

            let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first!

            // 计算需要循环的次数
            let loopCount = Int(ceil(targetDuration / bgmDuration))
            var currentTime = CMTime.zero

            for _ in 0..<loopCount {
                let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: bgmDuration, preferredTimescale: 600))
                try compositionAudioTrack?.insertTimeRange(
                    timeRange,
                    of: sourceAudioTrack,
                    at: currentTime
                )
                currentTime = CMTimeAdd(currentTime, CMTime(seconds: bgmDuration, preferredTimescale: 600))
            }

            // 裁剪到目标时长
            let finalTimeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: targetDuration, preferredTimescale: 600))

            // 导出
            let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetAppleM4A
            )
            exportSession?.outputURL = outputURL
            exportSession?.outputFileType = .m4a
            exportSession?.timeRange = finalTimeRange

            return try await withCheckedThrowingContinuation { continuation in
                exportSession?.exportAsynchronously {
                    switch exportSession?.status {
                    case .completed:
                        continuation.resume(returning: outputURL)
                    default:
                        continuation.resume(returning: nil)
                    }
                }
            }
        } catch {
            print("循环BGM失败: \(error)")
            return nil
        }
    }
}