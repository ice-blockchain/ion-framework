package io.ion.app

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

class VideoCompressionPlugin() : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "VideoCompression"
        private const val DEFAULT_FRAME_RATE = 30
        private const val DEFAULT_I_FRAME_INTERVAL = 1
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "compressVideo" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val destWidth = call.argument<Int>("destWidth")
                val destHeight = call.argument<Int>("destHeight")
                val codec = call.argument<String>("codec")
                val quality = call.argument<Double>("quality") ?: 0.75

                if (inputPath == null || outputPath == null || destWidth == null ||
                    destHeight == null || codec == null) {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    return
                }

                Thread {
                    try {
                        compressVideo(inputPath, outputPath, destWidth, destHeight, codec, quality)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Compression failed", e)
                        result.error("COMPRESSION_FAILED", e.message, null)
                    }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    private fun compressVideo(
        inputPath: String,
        outputPath: String,
        destWidth: Int,
        destHeight: Int,
        codec: String,
        quality: Double,
    ) {
        val outputFile = File(outputPath)

        if (outputFile.exists()) {
            outputFile.delete()
        }

        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var videoDecoder: MediaCodec? = null
        var videoEncoder: MediaCodec? = null

        try {
            extractor.setDataSource(inputPath)

            var videoTrackIndex = -1
            var audioTrackIndex = -1
            var videoFormat: MediaFormat? = null
            var audioFormat: MediaFormat? = null

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

                when {
                    mime.startsWith("video/") -> {
                        videoTrackIndex = i
                        videoFormat = format
                    }
                    mime.startsWith("audio/") -> {
                        audioTrackIndex = i
                        audioFormat = format
                    }
                }
            }

            if (videoTrackIndex == -1 || videoFormat == null) {
                throw IllegalArgumentException("No video track found")
            }

            val originalWidth = videoFormat.getInteger(MediaFormat.KEY_WIDTH)
            val originalHeight = videoFormat.getInteger(MediaFormat.KEY_HEIGHT)

            val rotation = try {
                videoFormat.getInteger(MediaFormat.KEY_ROTATION)
            } catch (e: Exception) {
                0
            }

            val isRotated = rotation == 90 || rotation == 270
            val adjustedWidth = if (isRotated) destHeight else destWidth
            val adjustedHeight = if (isRotated) destWidth else destHeight

            Log.d(TAG, "Original: ${originalWidth}x${originalHeight}, Target: ${adjustedWidth}x${adjustedHeight}")

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            val outputMime = when (codec) {
                "h264" -> MediaFormat.MIMETYPE_VIDEO_AVC
                "hevc" -> MediaFormat.MIMETYPE_VIDEO_HEVC
                else -> MediaFormat.MIMETYPE_VIDEO_AVC
            }

            val outputFormat = MediaFormat.createVideoFormat(outputMime, adjustedWidth, adjustedHeight)
            val targetBitrate = calculateTargetBitrate(quality)

            outputFormat.setInteger(MediaFormat.KEY_BIT_RATE, targetBitrate)

            outputFormat.setInteger(MediaFormat.KEY_FRAME_RATE, DEFAULT_FRAME_RATE)
            outputFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, DEFAULT_I_FRAME_INTERVAL)
            outputFormat.setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible
            )

            if (codec == "h264") {
                outputFormat.setInteger(
                    MediaFormat.KEY_PROFILE,
                    MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline
                )
            } else if (codec == "hevc") {
                outputFormat.setInteger(
                    MediaFormat.KEY_PROFILE,
                    MediaCodecInfo.CodecProfileLevel.HEVCProfileMain
                )
            }

            val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
            val encoderName = try {
                codecList.findEncoderForFormat(outputFormat)
            } catch (e: Exception) {
                null
            }

            videoEncoder = if (encoderName != null) {
                Log.d(TAG, "Using hardware encoder: $encoderName")
                MediaCodec.createByCodecName(encoderName)
            } else {
                Log.d(TAG, "Using default encoder")
                MediaCodec.createEncoderByType(outputMime)
            }

            val codecInfo = if (encoderName != null) {
                codecList.codecInfos.find { it.name == encoderName }
            } else {
                null
            }

            val capabilities = codecInfo?.getCapabilitiesForType(outputMime)
            val encoderCapabilities = capabilities?.encoderCapabilities

            if (encoderCapabilities != null) {
                val bitrateMode = when {
                    encoderCapabilities.isBitrateModeSupported(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR) -> {
                        Log.d(TAG, "Using Variable Bitrate (VBR) mode")
                        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR
                    }
                    else -> {
                        Log.d(TAG, "Using Constant Bitrate (CBR) mode (fallback)")
                        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR
                    }
                }
                outputFormat.setInteger(MediaFormat.KEY_BITRATE_MODE, bitrateMode)
            }

            videoEncoder.configure(outputFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val encoderSurface = videoEncoder.createInputSurface()
            videoEncoder.start()

            val videoMime = videoFormat.getString(MediaFormat.KEY_MIME)!!
            videoDecoder = MediaCodec.createDecoderByType(videoMime)
            videoDecoder.configure(videoFormat, encoderSurface, null, 0)
            videoDecoder.start()

            var audioOutputTrackIndex = -1
            val videoOutputTrackIndex: Int

            extractor.selectTrack(videoTrackIndex)
            val videoResult = processVideoTrackWithSurface(
                extractor,
                videoDecoder,
                videoEncoder,
                muxer,
                audioTrackIndex != -1 && audioFormat != null
            )
            videoOutputTrackIndex = videoResult.trackIndex

            encoderSurface.release()

            // Copy audio track directly without transcoding (faster, no quality loss)
            if (audioTrackIndex != -1 && audioFormat != null) {
                extractor.unselectTrack(videoTrackIndex)
                extractor.selectTrack(audioTrackIndex)
                extractor.seekTo(0, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

                audioOutputTrackIndex = muxer.addTrack(audioFormat)

                if (!videoResult.muxerStarted) {
                    muxer.start()
                    Log.d(TAG, "Muxer started (video + audio)")

                    writePendingVideoSamples(muxer, videoOutputTrackIndex, videoResult.pendingSamples)
                }

                copyAudioTrack(extractor, muxer, audioOutputTrackIndex)
            }
            muxer.stop()

            if (!outputFile.exists()) {
                throw RuntimeException("Output file was not created")
            }
            val outputSize = outputFile.length()
            Log.d(TAG, "Output file size: ${outputSize / (1024 * 1024)} MB")
            if (outputSize == 0L) {
                throw RuntimeException("Output file is empty")
            }

            Log.d(TAG, "Compression completed successfully")
        } finally {
            extractor.release()
            muxer?.release()
            videoDecoder?.stop()
            videoDecoder?.release()
            videoEncoder?.stop()
            videoEncoder?.release()
        }
    }

    private data class VideoProcessingResult(
        val trackIndex: Int,
        val muxerStarted: Boolean,
        val pendingSamples: List<Pair<ByteBuffer, MediaCodec.BufferInfo>>
    )

    private fun processVideoTrackWithSurface(
        extractor: MediaExtractor,
        videoDecoder: MediaCodec,
        videoEncoder: MediaCodec,
        muxer: MediaMuxer,
        hasAudioTrack: Boolean
    ): VideoProcessingResult {
        Log.d(TAG, "Starting processVideoTrackWithSurface, hasAudioTrack=$hasAudioTrack")
        val videoBufferInfo = MediaCodec.BufferInfo()
        var videoOutputTrackIndex = -1
        var videoInputDone = false
        var videoOutputDone = false
        var muxerStarted = false
        val pendingVideoSamples = mutableListOf<Pair<ByteBuffer, MediaCodec.BufferInfo>>()

        while (!videoOutputDone) {
            if (!videoInputDone) {
                val inputBufferIndex = videoDecoder.dequeueInputBuffer(0)
                if (inputBufferIndex >= 0) {
                    val inputBuffer = videoDecoder.getInputBuffer(inputBufferIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)

                    if (sampleSize < 0) {
                        videoDecoder.queueInputBuffer(
                            inputBufferIndex, 0, 0, 0,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM
                        )
                        videoInputDone = true
                    } else {
                        val presentationTimeUs = extractor.sampleTime
                        videoDecoder.queueInputBuffer(
                            inputBufferIndex, 0, sampleSize,
                            presentationTimeUs, 0
                        )
                        extractor.advance()
                    }
                }
            }

            val videoDecoderStatus = videoDecoder.dequeueOutputBuffer(videoBufferInfo, 0)
            when {
                videoDecoderStatus >= 0 -> {
                    val doRender = videoBufferInfo.size != 0
                    videoDecoder.releaseOutputBuffer(videoDecoderStatus, doRender)

                    if (videoBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        videoEncoder.signalEndOfInputStream()
                    }
                }
            }

            val videoEncoderStatus = videoEncoder.dequeueOutputBuffer(videoBufferInfo, 0)
            when {
                videoEncoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val newFormat = videoEncoder.outputFormat
                    videoOutputTrackIndex = muxer.addTrack(newFormat)
                    if (!hasAudioTrack) {
                        // No audio track, start muxer immediately
                        muxer.start()
                        muxerStarted = true
                        Log.d(TAG, "Muxer started (video only)")
                    } else {
                        Log.d(TAG, "Video track added, waiting for audio track before starting muxer")
                    }
                }
                videoEncoderStatus >= 0 -> {
                    val encodedData = videoEncoder.getOutputBuffer(videoEncoderStatus)!!

                    if (videoBufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        videoBufferInfo.size = 0
                    }

                    if (videoBufferInfo.size != 0) {
                        if (muxerStarted) {
                            encodedData.position(videoBufferInfo.offset)
                            encodedData.limit(videoBufferInfo.offset + videoBufferInfo.size)
                            muxer.writeSampleData(videoOutputTrackIndex, encodedData, videoBufferInfo)
                        } else {
                            // Buffer video samples until muxer is started
                            val bufferCopy = ByteBuffer.allocate(videoBufferInfo.size)
                            encodedData.position(videoBufferInfo.offset)
                            encodedData.limit(videoBufferInfo.offset + videoBufferInfo.size)
                            bufferCopy.put(encodedData)
                            bufferCopy.flip()

                            val infoCopy = MediaCodec.BufferInfo()
                            infoCopy.set(0, videoBufferInfo.size, videoBufferInfo.presentationTimeUs, videoBufferInfo.flags)
                            pendingVideoSamples.add(Pair(bufferCopy, infoCopy))

                            if (pendingVideoSamples.size % 100 == 0) {
                                Log.d(TAG, "Buffered ${pendingVideoSamples.size} video samples")
                            }
                        }
                    }

                    videoEncoder.releaseOutputBuffer(videoEncoderStatus, false)

                    if (videoBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        videoOutputDone = true
                    }
                }
            }
        }

        Log.d(TAG, "Finished processVideoTrackWithSurface, buffered ${pendingVideoSamples.size} samples")
        return VideoProcessingResult(videoOutputTrackIndex, muxerStarted, pendingVideoSamples)
    }

    private fun writePendingVideoSamples(
        muxer: MediaMuxer,
        videoTrackIndex: Int,
        pendingSamples: List<Pair<ByteBuffer, MediaCodec.BufferInfo>>
    ) {
        Log.d(TAG, "Writing ${pendingSamples.size} buffered video samples")
        for ((buffer, bufferInfo) in pendingSamples) {
            buffer.rewind()
            muxer.writeSampleData(videoTrackIndex, buffer, bufferInfo)
        }
        Log.d(TAG, "Finished writing buffered video samples")
    }

    private fun copyAudioTrack(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        audioTrackIndex: Int
    ) {
        Log.d(TAG, "Copying audio track directly")
        val bufferInfo = MediaCodec.BufferInfo()
        val buffer = ByteBuffer.allocate(1024 * 1024)

        while (true) {
            bufferInfo.size = extractor.readSampleData(buffer, 0)
            if (bufferInfo.size < 0) {
                break
            }

            bufferInfo.presentationTimeUs = extractor.sampleTime

            muxer.writeSampleData(audioTrackIndex, buffer, bufferInfo)
            extractor.advance()
        }

        Log.d(TAG, "Finished copying audio track")
    }

    private fun calculateTargetBitrate(quality: Double): Int {
        val baseBitrate = 1_000_000
        val qualityFactor = quality.coerceIn(0.5, 1.0)

        return (baseBitrate * qualityFactor).toInt()
    }
}
