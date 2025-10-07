import Flutter
import UIKit
import AVFoundation
import VideoToolbox

public class VideoCompressionPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ion/video_compression", binaryMessenger: registrar.messenger())
        let instance = VideoCompressionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "compressVideo":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let destWidth = args["destWidth"] as? Int,
                  let destHeight = args["destHeight"] as? Int,
                  let codec = args["codec"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for compressVideo", details: nil))
                return
            }

            // Optional parameters with defaults
            let quality = args["quality"] as? Double ?? 0.6
            let realtime = args["realtime"] as? Bool ?? true

            let codecType: CMVideoCodecType
            switch codec {
            case "h264":
                codecType = kCMVideoCodecType_H264
            case "hevc":
                codecType = kCMVideoCodecType_HEVC
            default:
                result(FlutterError(code: "INVALID_CODEC", message: "Unsupported codec: \(codec)", details: nil))
                return
            }

            let options = CompressionOptions(
                destWidth: destWidth,
                destHeight: destHeight,
                pixelFormat: kCVPixelFormatType_32BGRA,
                codec: codecType,
                quality: quality,
                realtime: realtime
            )

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.compressVideo(inputPath: inputPath, outputPath: outputPath, options: options)
                    DispatchQueue.main.async { result(nil) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "COMPRESSION_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func compressVideo(inputPath: String, outputPath: String, options: CompressionOptions) throws {
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        try? FileManager.default.removeItem(at: outputURL)

        let asset = AVAsset(url: inputURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoCompressionPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }

        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // Video Reader
        let videoReaderSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: options.pixelFormat
        ]
        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        reader.add(videoReaderOutput)

        // Get the preferred transform for rotation
        let preferredTransform = videoTrack.preferredTransform

        // Adjust width and height for vertical videos
        let isVertical = abs(preferredTransform.a) < 1e-3 && abs(preferredTransform.d) < 1e-3
        let adjustedWidth = isVertical ? options.destHeight : options.destWidth
        let adjustedHeight = isVertical ? options.destWidth : options.destHeight

        // Codec settings
        let hevcProfileLevel = kVTProfileLevel_HEVC_Main_AutoLevel as String
        let h264ProfileLevel = AVVideoProfileLevelH264HighAutoLevel

        var compressionProperties: [String: Any] = [
            AVVideoQualityKey: options.quality,  // VBR encoding: 0.0 = lowest quality, 1.0 = highest quality
            AVVideoProfileLevelKey: options.codec == kCMVideoCodecType_H264 ? h264ProfileLevel : hevcProfileLevel
        ]

        // Add HEVC-specific settings
        if options.codec == kCMVideoCodecType_HEVC {
            compressionProperties[AVVideoExpectedSourceFrameRateKey] = 30
        }

        let videoWriterSettings: [String: Any] = [
            AVVideoCodecKey: options.codec == kCMVideoCodecType_H264 ? AVVideoCodecType.h264 : AVVideoCodecType.hevc,
            AVVideoWidthKey: adjustedWidth,
            AVVideoHeightKey: adjustedHeight,
            AVVideoCompressionPropertiesKey: compressionProperties
        ]

        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterSettings)
        videoWriterInput.expectsMediaDataInRealTime = options.realtime
        videoWriterInput.transform = preferredTransform

        let videoAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: options.pixelFormat,
                kCVPixelBufferWidthKey as String: adjustedWidth,
                kCVPixelBufferHeightKey as String: adjustedHeight
            ]
        )
        writer.add(videoWriterInput)

        // Audio Reader/Writer
        var audioReaderOutput: AVAssetReaderTrackOutput?
        var audioWriterInput: AVAssetWriterInput?

        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            let audioOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM
            ]
            audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioOutputSettings)
            if let audioOutput = audioReaderOutput {
                reader.add(audioOutput)
            }

            let audioWriterSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]
            audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterSettings)
            audioWriterInput?.expectsMediaDataInRealTime = options.realtime
            if let audioInput = audioWriterInput {
                writer.add(audioInput)
            }
        }

        guard reader.startReading() else {
            throw NSError(domain: "VideoCompressionPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reader failed: \(reader.error?.localizedDescription ?? "Unknown")"])
        }

        guard writer.startWriting() else {
            throw NSError(domain: "VideoCompressionPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Writer failed: \(writer.error?.localizedDescription ?? "Unknown")"])
        }

        writer.startSession(atSourceTime: .zero)

        let dispatchGroup = DispatchGroup()

        // VIDEO
        dispatchGroup.enter()
        let videoQueue = DispatchQueue(label: "videoQueue")
        videoWriterInput.requestMediaDataWhenReady(on: videoQueue) {
            while videoWriterInput.isReadyForMoreMediaData {
                guard let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() else {
                    videoWriterInput.markAsFinished()
                    dispatchGroup.leave()
                    break
                }
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                _ = videoAdaptor.append(pixelBuffer, withPresentationTime: time)
            }
        }

        // AUDIO
        if let audioOutput = audioReaderOutput, let audioInput = audioWriterInput {
            dispatchGroup.enter()
            let audioQueue = DispatchQueue(label: "audioQueue")
            audioInput.requestMediaDataWhenReady(on: audioQueue) {
                while audioInput.isReadyForMoreMediaData {
                    guard let sampleBuffer = audioOutput.copyNextSampleBuffer() else {
                        audioInput.markAsFinished()
                        dispatchGroup.leave()
                        break
                    }
                    _ = audioInput.append(sampleBuffer)
                }
            }
        }

        dispatchGroup.wait()

        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            if writer.status != .completed {
                print("Writer failed: \(writer.error?.localizedDescription ?? "Unknown")")
            }
            semaphore.signal()
        }
        semaphore.wait()

        if writer.status != .completed {
            throw NSError(domain: "VideoCompressionPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: writer.error?.localizedDescription ?? "Unknown export error"])
        }
    }
}

struct CompressionOptions {
    var destWidth: Int
    var destHeight: Int
    var pixelFormat: OSType
    var codec: CMVideoCodecType
    var quality: Double
    var realtime: Bool
}
