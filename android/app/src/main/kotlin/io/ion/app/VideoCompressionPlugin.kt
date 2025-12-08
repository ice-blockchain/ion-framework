package io.ion.app

import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import android.util.Log
import android.view.Surface
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Semaphore

class VideoCompressionPlugin() : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "VideoCompression"
        private const val DEFAULT_FRAME_RATE = 30
        private const val DEFAULT_I_FRAME_INTERVAL = 1
        private val compressionSemaphore = Semaphore(2, true)
        
        // Maximum resolution limits for different device types
        private const val MAX_RESOLUTION_OPPO = 1920 * 1080 // 1080p for OPPO devices
        private const val MAX_RESOLUTION_DEFAULT = 3840 * 2160 // 4K for other devices
        private const val MAX_RESOLUTION_MEMORY_LIMITED = 1920 * 1080 // For high-res videos
        
        // Error codes
        private const val ERROR_NO_MEMORY = -12
        private const val ERROR_BAD_VALUE = -38
    }
    
    private val isOppoDevice: Boolean by lazy {
        Build.MANUFACTURER.equals("OPPO", ignoreCase = true) ||
        Build.BRAND.equals("OPPO", ignoreCase = true) ||
        Build.MANUFACTURER.equals("OnePlus", ignoreCase = true) ||
        Build.BRAND.equals("OnePlus", ignoreCase = true)
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
                    destHeight == null || codec == null
                ) {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    return
                }

                Thread {
                    compressionSemaphore.acquire()
                    try {
                        Log.d(TAG, "Starting compression: $inputPath (${compressionSemaphore.availablePermits()} slots remaining)")
                        compressVideo(inputPath, outputPath, destWidth, destHeight, codec, quality)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Compression failed", e)
                        result.error("COMPRESSION_FAILED", e.message, null)
                    } finally {
                        compressionSemaphore.release()
                        Log.d(TAG, "Compression completed: $inputPath (${compressionSemaphore.availablePermits()} slots available)")
                    }
                }.start()
            }

            "extractThumbnail" -> {
                val videoPath = call.argument<String>("videoPath")
                val outputPath = call.argument<String>("outputPath")
                // Handle both Int and Long from Dart
                val timeUsValue = call.argument<Any>("timeUs")
                val timeUs: Long = when (timeUsValue) {
                    is Int -> timeUsValue.toLong()
                    is Long -> timeUsValue
                    else -> 1000000L // Default to 1 second
                }

                if (videoPath == null || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    return
                }

                Thread {
                    try {
                        extractThumbnail(videoPath, outputPath, timeUs)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Thumbnail extraction failed", e)
                        result.error("THUMBNAIL_EXTRACTION_FAILED", e.message, null)
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

        val metadata = extractVideoMetadata(inputPath, destWidth, destHeight)
        transcodeVideo(inputPath, outputPath, metadata, codec, quality)
    }

    private fun extractVideoMetadata(
        inputPath: String,
        destWidth: Int,
        destHeight: Int
    ): VideoMetadata {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(inputPath)

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

                if (mime.startsWith("video/")) {
                    val width = format.getInteger(MediaFormat.KEY_WIDTH)
                    val height = format.getInteger(MediaFormat.KEY_HEIGHT)
                    val rotation = try {
                        format.getInteger(MediaFormat.KEY_ROTATION)
                    } catch (e: Exception) {
                        0
                    }

                    return VideoMetadata(width, height, rotation, format, mime)
                }
            }

            throw IllegalArgumentException("No video track found")
        } finally {
            extractor.release()
        }
    }

    private fun transcodeVideo(
        inputPath: String,
        outputPath: String,
        metadata: VideoMetadata,
        codec: String,
        quality: Double
    ) {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var videoDecoder: MediaCodec? = null
        var videoEncoder: MediaCodec? = null

        try {
            extractor.setDataSource(inputPath)

            var videoTrackIndex = -1
            var audioTrackIndex = -1
            var audioFormat: MediaFormat? = null

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

                when {
                    mime.startsWith("video/") -> videoTrackIndex = i
                    mime.startsWith("audio/") -> {
                        audioTrackIndex = i
                        audioFormat = format
                    }
                }
            }

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxer.setOrientationHint(metadata.rotation)

            val encoderConfig = createEncoderConfig(metadata, codec, quality)
            videoEncoder = createVideoEncoder(encoderConfig)

            val encoderSurface = videoEncoder.createInputSurface()
            videoEncoder.start()

            // Create decoder with fallback for high-resolution videos
            videoDecoder = createVideoDecoder(metadata.mime, metadata.format, encoderSurface)
            videoDecoder.start()

            extractor.selectTrack(videoTrackIndex)
            val videoResult = processVideoTrack(
                extractor,
                videoDecoder,
                videoEncoder,
                muxer,
                audioTrackIndex != -1 && audioFormat != null
            )

            encoderSurface.release()

            // Copy audio track directly without transcoding
            if (audioTrackIndex != -1 && audioFormat != null) {
                extractor.unselectTrack(videoTrackIndex)
                extractor.selectTrack(audioTrackIndex)
                extractor.seekTo(0, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

                val audioOutputTrackIndex = muxer.addTrack(audioFormat)

                if (!videoResult.muxerStarted) {
                    muxer.start()
                    Log.d(TAG, "Muxer started (video + audio)")
                    writePendingVideoSamples(
                        muxer,
                        videoResult.trackIndex,
                        videoResult.pendingSamples
                    )
                }

                copyAudioTrack(extractor, muxer, audioOutputTrackIndex)
            }

            muxer.stop()

            val outputFile = File(outputPath)
            if (!outputFile.exists() || outputFile.length() == 0L) {
                throw RuntimeException("Output file was not created or is empty")
            }

            Log.d(
                TAG,
                "Compression completed successfully. Output size: ${outputFile.length() / (1024 * 1024)} MB"
            )
        } finally {
            extractor.release()
            muxer?.release()
            videoDecoder?.stop()
            videoDecoder?.release()
            videoEncoder?.stop()
            videoEncoder?.release()
        }
    }

    private fun createEncoderConfig(
        metadata: VideoMetadata,
        codec: String,
        quality: Double
    ): EncoderConfig {
        val isRotated = metadata.rotation == 90 || metadata.rotation == 270
        var targetWidth = if (isRotated) metadata.height else metadata.width
        var targetHeight = if (isRotated) metadata.width else metadata.height

        // Validate and adjust resolution to avoid upscaling and memory issues
        val (validatedWidth, validatedHeight) = validateResolution(
            targetWidth, 
            targetHeight, 
            metadata.width, 
            metadata.height
        )
        targetWidth = validatedWidth
        targetHeight = validatedHeight

        val outputMime = when (codec) {
            "h264" -> MediaFormat.MIMETYPE_VIDEO_AVC
            "hevc" -> MediaFormat.MIMETYPE_VIDEO_HEVC
            else -> MediaFormat.MIMETYPE_VIDEO_AVC
        }

        Log.d(TAG, "Encoder config: ${targetWidth}x${targetHeight}, codec=$codec, quality=$quality, isOppo=$isOppoDevice")

        return EncoderConfig(targetWidth, targetHeight, outputMime, codec, quality)
    }
    
    /**
     * Validates resolution and adjusts if needed to avoid codec failures.
     * - Prevents upscaling (uses original resolution if target is larger)
     * - Limits resolution based on device capabilities
     * - Ensures dimensions are even (required by some codecs)
     */
    private fun validateResolution(
        targetWidth: Int,
        targetHeight: Int,
        originalWidth: Int,
        originalHeight: Int
    ): Pair<Int, Int> {
        var width = targetWidth
        var height = targetHeight
        
        // Don't upscale - use original resolution if target is larger
        if (width > originalWidth || height > originalHeight) {
            Log.w(TAG, "Target resolution ($width x $height) exceeds original ($originalWidth x $originalHeight), using original")
            width = originalWidth
            height = originalHeight
        }
        
        // Check for very high resolution videos (like 3240x2160) that cause memory issues
        val pixelCount = width * height
        val maxPixels = when {
            pixelCount > MAX_RESOLUTION_MEMORY_LIMITED -> MAX_RESOLUTION_MEMORY_LIMITED
            isOppoDevice -> MAX_RESOLUTION_OPPO
            else -> MAX_RESOLUTION_DEFAULT
        }
        
        if (pixelCount > maxPixels) {
            val scale = Math.sqrt(maxPixels.toDouble() / pixelCount)
            width = (width * scale).toInt()
            height = (height * scale).toInt()
            Log.w(TAG, "Resolution too high, downscaled to $width x $height (max pixels: $maxPixels)")
        }
        
        // Ensure dimensions are even (required by H.264 codec)
        width = (width / 2) * 2
        height = (height / 2) * 2
        
        return Pair(width, height)
    }

    private fun getSupportedH264Profile(
        mime: String,
        width: Int,
        height: Int
    ): Int {
        val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
        
        // For OPPO devices, prefer MAIN over HIGH profile to avoid configuration failures
        val profiles = if (isOppoDevice) {
            listOf(
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain to "MAIN",
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline to "BASELINE",
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh to "HIGH"
            )
        } else {
            listOf(
                MediaCodecInfo.CodecProfileLevel.AVCProfileHigh to "HIGH",
                MediaCodecInfo.CodecProfileLevel.AVCProfileMain to "MAIN",
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline to "BASELINE"
            )
        }
        
        for ((profile, profileName) in profiles) {
            val testFormat = MediaFormat.createVideoFormat(mime, width, height)
            testFormat.setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
            )
            testFormat.setInteger(MediaFormat.KEY_PROFILE, profile)
            
            val encoderName = codecList.findEncoderForFormat(testFormat)
            if (encoderName != null) {
                Log.d(TAG, "Device supports H.264 $profileName profile")
                return profile
            }
        }
        
        Log.w(TAG, "No H.264 profile found, falling back to BASELINE")
        return MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline
    }

    private fun createVideoEncoder(config: EncoderConfig): MediaCodec {
        // Try hardware encoder first with fallback to software encoder
        return try {
            createHardwareEncoder(config)
        } catch (e: MediaCodec.CodecException) {
            Log.w(TAG, "Hardware encoder failed (${e.errorCode}), trying software encoder", e)
            try {
                createSoftwareEncoder(config)
            } catch (e2: Exception) {
                Log.e(TAG, "Software encoder also failed", e2)
                throw RuntimeException("Failed to create video encoder: ${e.message}", e)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error creating encoder, trying software fallback", e)
            try {
                createSoftwareEncoder(config)
            } catch (e2: Exception) {
                Log.e(TAG, "Software encoder fallback failed", e2)
                throw RuntimeException("Failed to create video encoder: ${e.message}", e)
            }
        }
    }
    
    private fun createHardwareEncoder(config: EncoderConfig): MediaCodec {
        val format = createEncoderFormat(config)
        
        val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
        val encoderName = codecList.findEncoderForFormat(format)

        if (encoderName == null) {
            throw RuntimeException("No hardware encoder found for format")
        }

        Log.d(TAG, "Using hardware encoder: $encoderName")
        val encoder = MediaCodec.createByCodecName(encoderName)
        
        // Try to configure with retry logic for profile fallback
        try {
            applyEncoderCapabilities(encoderName, config.mime, format)
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        } catch (e: MediaCodec.CodecException) {
            encoder.release()
            // If configuration fails, try with lower profile
            if (config.codec == "h264" && e.errorCode == ERROR_BAD_VALUE) {
                Log.w(TAG, "Encoder configuration failed, retrying with lower profile")
                return createHardwareEncoderWithProfileFallback(config, encoderName)
            }
            throw e
        }

        return encoder
    }
    
    private fun createHardwareEncoderWithProfileFallback(
        config: EncoderConfig,
        encoderName: String
    ): MediaCodec {
        val profiles = listOf(
            MediaCodecInfo.CodecProfileLevel.AVCProfileMain to "MAIN",
            MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline to "BASELINE"
        )
        
        for ((profile, profileName) in profiles) {
            try {
                val format = createEncoderFormat(config)
                format.setInteger(MediaFormat.KEY_PROFILE, profile)
                
                val encoder = MediaCodec.createByCodecName(encoderName)
                applyEncoderCapabilities(encoderName, config.mime, format)
                encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                Log.d(TAG, "Successfully configured encoder with $profileName profile")
                return encoder
            } catch (e: MediaCodec.CodecException) {
                Log.w(TAG, "Failed to configure with $profileName profile: ${e.errorCode}")
                // Continue to next profile
            }
        }
        
        throw RuntimeException("Failed to configure encoder with any profile")
    }
    
    private fun createSoftwareEncoder(config: EncoderConfig): MediaCodec {
        Log.d(TAG, "Using software encoder")
        val format = createEncoderFormat(config)
        
        // For software encoder, use BASELINE profile which is most compatible
        if (config.codec == "h264") {
            format.setInteger(
                MediaFormat.KEY_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline
            )
        }
        
        val encoder = MediaCodec.createEncoderByType(config.mime)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        
        return encoder
    }
    
    private fun createEncoderFormat(config: EncoderConfig): MediaFormat {
        val format = MediaFormat.createVideoFormat(config.mime, config.width, config.height)

        // Bitrate calculation - use lower bitrate for OPPO devices to avoid issues
        val baseBitrate = calculateTargetBitrate(config.width, config.height, DEFAULT_FRAME_RATE, config.quality)
        val bitrate = if (isOppoDevice) {
            (baseBitrate * 0.85).toInt() // Reduce bitrate by 15% for OPPO devices
        } else {
            baseBitrate
        }
        
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        format.setInteger(MediaFormat.KEY_FRAME_RATE, DEFAULT_FRAME_RATE)
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, DEFAULT_I_FRAME_INTERVAL)
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
        )

        when (config.codec) {
            "h264" -> {
                val supportedProfile = getSupportedH264Profile(config.mime, config.width, config.height)
                format.setInteger(MediaFormat.KEY_PROFILE, supportedProfile)
            }

            "hevc" -> format.setInteger(
                MediaFormat.KEY_PROFILE,
                MediaCodecInfo.CodecProfileLevel.HEVCProfileMain
            )
        }
        
        return format
    }

    private fun applyEncoderCapabilities(
        encoderName: String?,
        mime: String,
        format: MediaFormat
    ) {
        if (encoderName == null) return

        val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
        val codecInfo = codecList.codecInfos.find { it.name == encoderName } ?: return
        val capabilities = codecInfo.getCapabilitiesForType(mime)?.encoderCapabilities ?: return

        val supportsVbr = capabilities.isBitrateModeSupported(MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)

        val bitrateMode = when {
            supportsVbr -> {
                Log.d(TAG, "Selecting Variable Bitrate (VBR) mode")
                MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR
            }

            else -> {
                Log.d(TAG, "Selecting Constant Bitrate (CBR) mode")
                MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR
            }
        }
        format.setInteger(MediaFormat.KEY_BITRATE_MODE, bitrateMode)
    }

    private fun processVideoTrack(
        extractor: MediaExtractor,
        videoDecoder: MediaCodec,
        videoEncoder: MediaCodec,
        muxer: MediaMuxer,
        hasAudioTrack: Boolean
    ): VideoProcessingResult {
        Log.d(TAG, "Processing video track, hasAudioTrack=$hasAudioTrack")

        val bufferInfo = MediaCodec.BufferInfo()
        var videoOutputTrackIndex = -1
        var inputDone = false
        var outputDone = false
        var muxerStarted = false
        val pendingSamples = mutableListOf<Pair<ByteBuffer, MediaCodec.BufferInfo>>()

        while (!outputDone) {
            // Feed input to decoder
            if (!inputDone) {
                val inputBufferIndex = videoDecoder.dequeueInputBuffer(0)
                if (inputBufferIndex >= 0) {
                    val inputBuffer = videoDecoder.getInputBuffer(inputBufferIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)

                    if (sampleSize < 0) {
                        videoDecoder.queueInputBuffer(
                            inputBufferIndex, 0, 0, 0,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM
                        )
                        inputDone = true
                    } else {
                        videoDecoder.queueInputBuffer(
                            inputBufferIndex, 0, sampleSize,
                            extractor.sampleTime, 0
                        )
                        extractor.advance()
                    }
                }
            }

            // Process decoder output (renders to encoder surface)
            val decoderStatus = videoDecoder.dequeueOutputBuffer(bufferInfo, 0)
            if (decoderStatus >= 0) {
                val doRender = bufferInfo.size != 0
                videoDecoder.releaseOutputBuffer(decoderStatus, doRender)

                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    videoEncoder.signalEndOfInputStream()
                }
            }

            // Process encoder output
            val encoderStatus = videoEncoder.dequeueOutputBuffer(bufferInfo, 0)
            when {
                encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    videoOutputTrackIndex = muxer.addTrack(videoEncoder.outputFormat)
                    if (!hasAudioTrack) {
                        muxer.start()
                        muxerStarted = true
                        Log.d(TAG, "Muxer started (video only)")
                    } else {
                        Log.d(TAG, "Video track added, waiting for audio")
                    }
                }

                encoderStatus >= 0 -> {
                    val encodedData = videoEncoder.getOutputBuffer(encoderStatus)!!

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size != 0) {
                        if (muxerStarted) {
                            encodedData.position(bufferInfo.offset)
                            encodedData.limit(bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(videoOutputTrackIndex, encodedData, bufferInfo)
                        } else {
                            // Buffer samples until muxer starts
                            val bufferCopy = ByteBuffer.allocate(bufferInfo.size)
                            encodedData.position(bufferInfo.offset)
                            encodedData.limit(bufferInfo.offset + bufferInfo.size)
                            bufferCopy.put(encodedData)
                            bufferCopy.flip()

                            val infoCopy = MediaCodec.BufferInfo()
                            infoCopy.set(
                                0,
                                bufferInfo.size,
                                bufferInfo.presentationTimeUs,
                                bufferInfo.flags
                            )
                            pendingSamples.add(Pair(bufferCopy, infoCopy))
                        }
                    }

                    videoEncoder.releaseOutputBuffer(encoderStatus, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }
        }

        Log.d(TAG, "Video processing complete, buffered ${pendingSamples.size} samples")
        return VideoProcessingResult(videoOutputTrackIndex, muxerStarted, pendingSamples)
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
    }

    private fun copyAudioTrack(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        audioTrackIndex: Int
    ) {
        Log.d(TAG, "Copying audio track")
        val bufferInfo = MediaCodec.BufferInfo()
        val buffer = ByteBuffer.allocate(1024 * 1024)

        while (true) {
            bufferInfo.size = extractor.readSampleData(buffer, 0)
            if (bufferInfo.size < 0) break

            bufferInfo.presentationTimeUs = extractor.sampleTime
            muxer.writeSampleData(audioTrackIndex, buffer, bufferInfo)
            extractor.advance()
        }

        Log.d(TAG, "Audio track copied")
    }

    /**
     * Creates a video decoder with fallback mechanism for high-resolution videos.
     * Tries hardware decoder first, falls back to software decoder if memory issues occur.
     */
    private fun createVideoDecoder(
        mime: String,
        format: MediaFormat,
        surface: Surface
    ): MediaCodec {
        return try {
            // Try hardware decoder first
            val decoder = MediaCodec.createDecoderByType(mime)
            try {
                decoder.configure(format, surface, null, 0)
                Log.d(TAG, "Hardware decoder configured successfully")
                decoder
            } catch (e: MediaCodec.CodecException) {
                decoder.release()
                if (e.errorCode == ERROR_NO_MEMORY || e.errorCode == ERROR_BAD_VALUE) {
                    Log.w(TAG, "Hardware decoder failed (${e.errorCode}), trying software decoder", e)
                    // Fallback to software decoder
                    val softwareDecoder = MediaCodec.createDecoderByType(mime)
                    softwareDecoder.configure(format, surface, null, 0)
                    Log.d(TAG, "Software decoder configured successfully")
                    softwareDecoder
                } else {
                    throw e
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create video decoder", e)
            throw RuntimeException("Failed to create video decoder: ${e.message}", e)
        }
    }
    
    private fun calculateTargetBitrate(width: Int, height: Int, frameRate: Int, quality: Double): Int {
        val bpp = 0.08 // bits per pixel for h264 balanced quality
        val qualityFactor = quality.coerceIn(0.5, 1.0)
        val bitrate = (width.toLong() * height.toLong() * frameRate * bpp * qualityFactor).toLong()
        // Clamp between 1 Mbps and 10 Mbps for stability
        val min = 1_000_000L
        val max = 10_000_000L
        return bitrate.coerceIn(min, max).toInt()
    }

    private fun extractThumbnail(videoPath: String, outputPath: String, timeUs: Long) {
        val retriever = MediaMetadataRetriever()
        var outputStream: FileOutputStream? = null
        try {
            retriever.setDataSource(videoPath)
            val bitmap = retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            
            if (bitmap == null) {
                throw RuntimeException("Failed to extract frame at time $timeUs")
            }

            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            outputStream = FileOutputStream(outputFile)
            
            // Save as WebP with quality 80
            bitmap.compress(Bitmap.CompressFormat.WEBP, 80, outputStream)
            outputStream.flush()
            
            if (!outputFile.exists() || outputFile.length() == 0L) {
                throw RuntimeException("Output file was not created or is empty")
            }
            
            Log.d(TAG, "Thumbnail extracted successfully: $outputPath")
        } finally {
            outputStream?.close()
            retriever.release()
        }
    }

    private data class VideoMetadata(
        val width: Int,
        val height: Int,
        val rotation: Int,
        val format: MediaFormat,
        val mime: String
    )

    private data class EncoderConfig(
        val width: Int,
        val height: Int,
        val mime: String,
        val codec: String,
        val quality: Double
    )

    private data class VideoProcessingResult(
        val trackIndex: Int,
        val muxerStarted: Boolean,
        val pendingSamples: List<Pair<ByteBuffer, MediaCodec.BufferInfo>>
    )
}
