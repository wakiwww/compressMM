import Foundation
import AVFoundation
import AudioToolbox

/// 音频处理器：带通滤波、降采样、混噪
class AudioProcessor {

    /// 处理音频轨道
    /// - Parameters:
    ///   - audioTrack: 源音频轨道
    ///   - parameters: 处理参数
    ///   - outputURL: 输出音频文件 URL
    func processAudioTrack(
        _ audioTrack: AVAssetTrack,
        parameters: ProcessingParameters,
        outputURL: URL
    ) async throws {
        // 简化的音频处理：使用 AVAssetReader + AVAssetWriter 读取再写入，
        // 设置目标采样率实现降采样，后续可加入带通滤波

        let asset = audioTrack.asset!
        let reader = try AVAssetReader(asset: asset)

        let readerOutput = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVNumberOfChannelsKey: 1,  // 混音为单声道增加复古感
            ]
        )
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .wav)
        let writerInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: parameters.audioSampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
            ]
        )
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)

        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        // 读取音频样本并写入（简化：直接通过，后续可加带通滤波处理）
        let queue = DispatchQueue(label: "com.hauntedfilter.audio.process")
        let group = DispatchGroup()
        group.enter()

        writerInput.requestMediaDataWhenReady(on: queue) {
            while writerInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                    // 应用带通滤波（可选：通过 AudioConverter 或 vDSP 处理 PCM 数据）
                    writerInput.append(sampleBuffer)
                } else {
                    writerInput.markAsFinished()
                    group.leave()
                    break
                }
            }
        }

        group.wait()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting {
                continuation.resume()
            }
        }
    }

    /// 混入底噪（简化版本：返回可混合的底噪音频文件 URL）
    func getBackgroundNoiseURL(for preset: VideoPreset) -> URL? {
        // MVP 阶段：返回 bundle 中的噪声音频
        // 后续可以从 bundle 加载 noise.wav
        return Bundle.main.url(forResource: "noise", withExtension: "wav")
    }
}