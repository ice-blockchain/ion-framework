package io.ion.app

import android.app.Application
import android.content.Context
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import android.util.Size
import androidx.core.net.toFile
import androidx.core.net.toUri
import androidx.fragment.app.Fragment
import com.banuba.sdk.arcloud.data.source.ArEffectsRepositoryProvider
import com.banuba.sdk.arcloud.di.ArCloudKoinModule
import com.banuba.sdk.audiobrowser.di.AudioBrowserKoinModule
import com.banuba.sdk.audiobrowser.domain.AudioBrowserMusicProvider
import com.banuba.sdk.core.AspectRatio
import com.banuba.sdk.core.data.TrackData
import com.banuba.sdk.core.domain.DraftConfig
import com.banuba.sdk.core.ui.ContentFeatureProvider
import com.banuba.sdk.effectplayer.adapter.BanubaEffectPlayerKoinModule
import com.banuba.sdk.export.di.VeExportKoinModule
import com.banuba.sdk.export.data.ExportParamsProvider
import com.banuba.sdk.export.data.ExportParams
import com.banuba.sdk.core.VideoResolution
import com.banuba.sdk.ve.effects.Effects
import com.banuba.sdk.ve.domain.VideoRangeList
import com.banuba.sdk.ve.effects.music.MusicEffect
import com.banuba.sdk.playback.di.VePlaybackSdkKoinModule
import com.banuba.sdk.ve.data.EditorAspectSettings
import com.banuba.sdk.ve.di.VeSdkKoinModule
import com.banuba.sdk.ve.flow.di.VeFlowKoinModule
import com.banuba.sdk.veui.data.EditorConfig
import com.banuba.sdk.veui.di.VeUiSdkKoinModule
import com.banuba.sdk.veui.domain.CoverProvider
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module

class VideoEditorModule {

    fun initialize(
        application: Application,
        videoAspectRatio: Double?,
        maxVideoDurationMs: Long? = 60_000,
        coverSelectionEnabled: Boolean = true,
    ) {
        // Check if Koin is already started to avoid KoinAppAlreadyStartedException
        if (GlobalContext.getOrNull() == null) {
            startKoin {
                androidContext(application)
                allowOverride(true)

                // IMPORTANT! order of modules is required
                modules(
                    VeSdkKoinModule().module,
                    VeExportKoinModule().module,
                    VePlaybackSdkKoinModule().module,

                    // Use AudioBrowserKoinModule ONLY if your contract includes this feature.
                    AudioBrowserKoinModule().module,

                    // IMPORTANT! ArCloudKoinModule should be set before TokenStorageKoinModule to get effects from the cloud
                    ArCloudKoinModule().module,

                    VeUiSdkKoinModule().module,
                    VeFlowKoinModule().module,
                    BanubaEffectPlayerKoinModule().module,

                    // Sample integration module
                    SampleIntegrationVeKoinModule(
                        videoAspectRatio,
                        maxVideoDurationMs,
                        coverSelectionEnabled,
                    ).module,
                )
            }
        } else {
            // Koin is already started, just load the additional modules
            GlobalContext.get().loadModules(listOf(
                SampleIntegrationVeKoinModule(
                    videoAspectRatio,
                    maxVideoDurationMs,
                    coverSelectionEnabled,
                ).module
            ))
        }
    }
}

/**
 * All dependencies mentioned in this module will override default
 * implementations provided in VE UI SDK.
 * Some dependencies has no default implementations. It means that
 * these classes fully depends on your requirements
 */
private class SampleIntegrationVeKoinModule(
    videoAspectRatio: Double?,
    maxVideoDurationMs: Long? = 60_000,
    coverSelectionEnabled: Boolean = true,
) {
    val module = module {
        single<ArEffectsRepositoryProvider>(createdAtStart = true) {
            ArEffectsRepositoryProvider(
                arEffectsRepository = get(named("backendArEffectsRepository")),
            )
        }

        factory {
            DraftConfig.DISABLED
        }

        // Audio Browser provider implementation.
        single<ContentFeatureProvider<TrackData, Fragment>>(
            named("musicTrackProvider")
        ) {
            AudioBrowserMusicProvider()
        }

        single<CoverProvider>(createdAtStart = true) {
            if (coverSelectionEnabled) CoverProvider.EXTENDED else CoverProvider.NONE
        }

        single(createdAtStart = true) {
            EditorConfig(
                aspectSettings = if (videoAspectRatio != null) EditorAspectSettings.detectAspectSettings(
                    videoAspectRatio
                ) else null,
                maxTotalVideoDurationMs = maxVideoDurationMs ?: 60_000,
            )
        }

        factory<ExportParamsProvider> {
            CustomExportParamsProvider(
                exportDir = get(named("exportDir")),
                context = get(),
            )
        }
    }
}

class CustomExportParamsProvider(
    private val exportDir: Uri,
    private val context: Context,
) : ExportParamsProvider {

    companion object {
        private const val TAG = "CustomExportParams"
        
        // Fallback limits if codec capabilities cannot be queried
        // These are conservative defaults that should work on most devices
        private const val FALLBACK_MAX_EXPORT_HEIGHT = 2160
        private const val FALLBACK_MAX_EXPORT_WIDTH = 3840
    }

    override fun provideExportParams(
        effects: Effects,
        videoRangeList: VideoRangeList,
        musicEffects: List<MusicEffect>,
        videoVolume: Float
    ): List<ExportParams> {
        val exportSessionDir = exportDir.toFile().apply {
            deleteRecursively()
            mkdirs()
        }

        Log.d(TAG, "provideExportParams: Starting export resolution calculation")
        Log.d(TAG, "provideExportParams: Video range list size = ${videoRangeList.data.size}")

        // Calculate safe export resolution based on source video dimensions
        val safeResolution = calculateSafeResolution(videoRangeList)

        Log.d(TAG, "provideExportParams: Final resolution selected = $safeResolution")

        val exportVideo = ExportParams.Builder(safeResolution)
            .effects(effects)
            .fileName("export_video")
            .videoRangeList(videoRangeList)
            .destDir(exportSessionDir)
            .musicEffects(musicEffects)
            .volumeVideo(videoVolume)
            .build()

        return listOf(exportVideo)
    }

    /**
     * Calculates a safe export resolution by checking the source video dimensions
     * against actual device MediaCodec capabilities to avoid configuration errors.
     * 
     * The error occurs when videos exceed device MediaCodec capabilities (e.g., 3240x2160).
     * This method queries the actual codec capabilities and scales down only if necessary.
     */
    private fun calculateSafeResolution(videoRangeList: VideoRangeList): VideoResolution {
        Log.d(TAG, "calculateSafeResolution: Starting resolution calculation")
        
        // Try to get video dimensions from the first video range
        val firstVideoRange = videoRangeList.data.firstOrNull()
        if (firstVideoRange == null) {
            Log.w(TAG, "calculateSafeResolution: No video range found, using Original")
            return VideoResolution.Original
        }
        
        val sourceUri = firstVideoRange.sourceUri
        if (sourceUri == null) {
            Log.w(TAG, "calculateSafeResolution: No source URI found, using Original")
            return VideoResolution.Original
        }
        
        Log.d(TAG, "calculateSafeResolution: Source URI = $sourceUri")
        
        val videoSize = getVideoSize(sourceUri)
        if (videoSize == null) {
            Log.w(TAG, "calculateSafeResolution: Could not extract video size, using Original")
            return VideoResolution.Original
        }
        
        val originalWidth = videoSize.width
        val originalHeight = videoSize.height
        
        Log.d(TAG, "calculateSafeResolution: Original video dimensions = ${originalWidth}x${originalHeight}")
        
        // Query actual device codec capabilities
        val codecLimits = getCodecCapabilities()

        val maxWidth = codecLimits.maxWidth
        val maxHeight = codecLimits.maxHeight
        
        Log.d(TAG, "calculateSafeResolution: Device codec limits - maxWidth=$maxWidth, maxHeight=$maxHeight")
        
        // If video is within device capabilities, use original resolution
        if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
            Log.d(TAG, "calculateSafeResolution: Video is within device capabilities, using Original resolution")
            return VideoResolution.Original
        }
        
        Log.w(TAG, "calculateSafeResolution: Video exceeds device capabilities (${originalWidth}x${originalHeight} > ${maxWidth}x${maxHeight}), scaling down")
        
        // Video exceeds device capabilities - calculate safe dimensions maintaining aspect ratio
        val aspectRatio = originalWidth.toFloat() / originalHeight.toFloat()
        
        // Calculate dimensions that fit within codec limits while maintaining aspect ratio
        // Try fitting by height first, then by width if needed
        val heightBasedWidth = (maxHeight * aspectRatio).toInt()
        val widthBasedHeight = (maxWidth / aspectRatio).toInt()
        
        val targetWidth: Int
        val targetHeight: Int
        
        if (heightBasedWidth <= maxWidth) {
            // Fits by height constraint
            targetWidth = heightBasedWidth
            targetHeight = maxHeight
        } else {
            // Fits by width constraint
            targetWidth = maxWidth
            targetHeight = widthBasedHeight
        }
        
        // Ensure dimensions are even (required by many codecs) and within limits
        val safeWidth = ((targetWidth / 2) * 2).coerceAtMost(maxWidth)
        val safeHeight = ((targetHeight / 2) * 2).coerceAtMost(maxHeight)
        
        Log.d(TAG, "calculateSafeResolution: Calculated safe dimensions = ${safeWidth}x${safeHeight} (aspect ratio = $aspectRatio, original = ${originalWidth}x${originalHeight})")
        
        // Find the best VideoResolution.Exact enum value that fits within device limits
        val suitableResolution = findBestExactResolution(safeWidth, safeHeight, maxWidth, maxHeight, aspectRatio)
        
        if (suitableResolution != null) {
            Log.d(TAG, "calculateSafeResolution: Using Exact resolution: $suitableResolution")
            return suitableResolution
        }
        
        // No suitable resolution found - log warning and use Original
        // The export may fail, but we've logged enough info for debugging
        Log.e(TAG, "calculateSafeResolution: No suitable resolution found for ${safeWidth}x${safeHeight}")
        Log.e(TAG, "calculateSafeResolution: Device limits: ${maxWidth}x${maxHeight}, Video: ${originalWidth}x${originalHeight}")
        Log.w(TAG, "calculateSafeResolution: Falling back to Original resolution - export may fail on this device")
        return VideoResolution.Original
    }
    
    /**
     * Finds the best VideoResolution.Exact enum value that fits within device limits.
     * The Exact enum has a 'size' property (height) and we need to calculate width based on aspect ratio.
     */
    private fun findBestExactResolution(
        targetWidth: Int,
        targetHeight: Int,
        maxWidth: Int,
        maxHeight: Int,
        aspectRatio: Float
    ): VideoResolution? {
        try {
            // Get the Exact enum class
            val exactClass = Class.forName("com.banuba.sdk.core.VideoResolution\$Exact")
            
            // Get all enum values
            val enumValues = exactClass.enumConstants as? Array<*>
            if (enumValues == null) {
                Log.w(TAG, "findBestExactResolution: Could not get Exact enum values")
                return null
            }
            
            Log.d(TAG, "findBestExactResolution: Found ${enumValues.size} Exact enum values")
            
            // Map enum values to their resolutions
            val resolutionsWithDimensions = enumValues.mapNotNull { enumValue ->
                try {
                    val exactResolution = enumValue as? VideoResolution
                    if (exactResolution == null) return@mapNotNull null
                    
                    // Get the 'size' property (height)
                    val sizeField = exactResolution.javaClass.getDeclaredField("size")
                    sizeField.isAccessible = true
                    val height = sizeField.get(exactResolution) as? Int ?: 0
                    
                    if (height == 0) return@mapNotNull null
                    
                    // Calculate width based on aspect ratio (assuming 16:9 for standard presets)
                    // For non-standard aspect ratios, we'll use the target aspect ratio
                    val width = (height * aspectRatio).toInt()
                    
                    val name = (enumValue as? Enum<*>)?.name ?: "Unknown"
                    Log.d(TAG, "findBestExactResolution: ${name} = ${width}x${height} (size=$height, aspectRatio=$aspectRatio)")
                    
                    ExactResolutionInfo(name, exactResolution, width, height)
                } catch (e: Exception) {
                    Log.d(TAG, "findBestExactResolution: Could not get dimensions for enum value: ${e.message}")
                    null
                }
            }
            
            // Find the largest resolution that fits within device limits
            val suitableResolution = resolutionsWithDimensions
                .sortedByDescending { it.width * it.height } // Sort by total pixels (largest first)
                .firstOrNull { resolution ->
                    // Check if resolution fits within device limits
                    // We need to ensure both width and height fit, accounting for aspect ratio
                    val fitsByHeight = resolution.height <= maxHeight && (resolution.height * aspectRatio).toInt() <= maxWidth
                    val fitsByWidth = resolution.width <= maxWidth && (resolution.width / aspectRatio).toInt() <= maxHeight
                    fitsByHeight || fitsByWidth
                }
            
            if (suitableResolution != null) {
                Log.d(TAG, "findBestExactResolution: Selected ${suitableResolution.name} (${suitableResolution.width}x${suitableResolution.height})")
                return suitableResolution.resolution
            } else {
                Log.w(TAG, "findBestExactResolution: No suitable Exact resolution found")
                // Try to find the smallest one that's at least close to our target
                val closestResolution = resolutionsWithDimensions
                    .minByOrNull { 
                        val widthDiff = kotlin.math.abs(it.width - targetWidth)
                        val heightDiff = kotlin.math.abs(it.height - targetHeight)
                        widthDiff + heightDiff
                    }
                
                if (closestResolution != null && 
                    closestResolution.width <= maxWidth * 1.5f && 
                    closestResolution.height <= maxHeight * 1.5f) {
                    Log.d(TAG, "findBestExactResolution: Using closest available: ${closestResolution.name}")
                    return closestResolution.resolution
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "findBestExactResolution: Error finding Exact resolution: ${e.message}", e)
        }
        
        return null
    }
    
    /**
     * Data class to hold Exact resolution information
     */
    private data class ExactResolutionInfo(
        val name: String,
        val resolution: VideoResolution,
        val width: Int,
        val height: Int
    )
    
    /**
     * Queries the device's MediaCodec encoder capabilities to determine maximum supported resolution.
     * Returns fallback values if capabilities cannot be queried.
     */
    private fun getCodecCapabilities(): CodecLimits {
        return try {
            val codecList = MediaCodecList(MediaCodecList.REGULAR_CODECS)
            val mimeType = MediaFormat.MIMETYPE_VIDEO_AVC
            
            // Iterate through all codecs to find an H.264 encoder
            // Prefer hardware encoders over software ones
            var encoderInfo: MediaCodecInfo? = null
            
            // First, try to find a hardware encoder (usually better performance and more accurate limits)
            for (codecInfo in codecList.codecInfos) {
                if (!codecInfo.isEncoder) continue
                
                try {
                    val supportedTypes = codecInfo.supportedTypes
                    if (supportedTypes.contains(mimeType)) {
                        // Prefer hardware encoders (usually contain vendor names like "mtk", "qcom", "exynos")
                        val name = codecInfo.name.lowercase()
                        if (name.contains("mtk") || name.contains("qcom") || name.contains("exynos") || 
                            name.contains("qti") || name.contains("omx") && !name.contains("google")) {
                            encoderInfo = codecInfo
                            Log.d(TAG, "getCodecCapabilities: Found hardware encoder: ${codecInfo.name}")
                            break
                        }
                    }
                } catch (e: Exception) {
                    Log.d(TAG, "getCodecCapabilities: Error checking codec ${codecInfo.name}: ${e.message}")
                }
            }
            
            // If no hardware encoder found, try any encoder
            if (encoderInfo == null) {
                for (codecInfo in codecList.codecInfos) {
                    if (!codecInfo.isEncoder) continue
                    
                    try {
                        val supportedTypes = codecInfo.supportedTypes
                        if (supportedTypes.contains(mimeType)) {
                            encoderInfo = codecInfo
                            Log.d(TAG, "getCodecCapabilities: Found encoder: ${codecInfo.name}")
                            break
                        }
                    } catch (e: Exception) {
                        Log.d(TAG, "getCodecCapabilities: Error checking codec ${codecInfo.name}: ${e.message}")
                    }
                }
            }
            
            if (encoderInfo == null) {
                Log.w(TAG, "getCodecCapabilities: No H.264 encoder found, using fallback limits")
                return CodecLimits(FALLBACK_MAX_EXPORT_WIDTH, FALLBACK_MAX_EXPORT_HEIGHT)
            }
            
            val capabilities = encoderInfo.getCapabilitiesForType(mimeType)
            val videoCapabilities = capabilities?.videoCapabilities
            
            if (videoCapabilities == null) {
                Log.w(TAG, "getCodecCapabilities: Video capabilities not available, using fallback limits")
                return CodecLimits(FALLBACK_MAX_EXPORT_WIDTH, FALLBACK_MAX_EXPORT_HEIGHT)
            }
            
            val supportedWidths = videoCapabilities.supportedWidths
            val supportedHeights = videoCapabilities.supportedHeights
            
            val maxWidth = supportedWidths.upper
            val maxHeight = supportedHeights.upper
            
            Log.d(TAG, "getCodecCapabilities: Device supports - maxWidth=$maxWidth, maxHeight=$maxHeight")
            Log.d(TAG, "getCodecCapabilities: Width range = [${supportedWidths.lower}, $maxWidth]")
            Log.d(TAG, "getCodecCapabilities: Height range = [${supportedHeights.lower}, $maxHeight]")
            
            CodecLimits(maxWidth, maxHeight)
        } catch (e: Exception) {
            Log.e(TAG, "getCodecCapabilities: Error querying codec capabilities: ${e.message}", e)
            Log.w(TAG, "getCodecCapabilities: Using fallback limits")
            CodecLimits(FALLBACK_MAX_EXPORT_WIDTH, FALLBACK_MAX_EXPORT_HEIGHT)
        }
    }
    
    /**
     * Data class to hold codec capability limits
     */
    private data class CodecLimits(
        val maxWidth: Int,
        val maxHeight: Int
    )

    /**
     * Extracts video dimensions from a video URI using MediaMetadataRetriever.
     * Handles rotation metadata to return correct width/height.
     */
    private fun getVideoSize(uri: Uri): Size? {
        Log.d(TAG, "getVideoSize: Extracting video dimensions from URI: $uri")
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)

            val w = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                ?.toIntOrNull()

            val h = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                ?.toIntOrNull()

            val rot = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                ?.toIntOrNull() ?: 0

            Log.d(TAG, "getVideoSize: Raw metadata - width=$w, height=$h, rotation=$rot")

            if (w == null || h == null) {
                Log.w(TAG, "getVideoSize: Could not extract width or height from metadata")
                return null
            }

            // If the rotation is 90° or 270°, swap width/height
            val finalSize = if (rot == 90 || rot == 270) {
                Log.d(TAG, "getVideoSize: Rotation detected ($rot°), swapping dimensions: ${h}x${w}")
                Size(h, w)
            } else {
                Log.d(TAG, "getVideoSize: No rotation swap needed, using dimensions: ${w}x${h}")
                Size(w, h)
            }
            
            Log.d(TAG, "getVideoSize: Final video size = ${finalSize.width}x${finalSize.height}")
            finalSize
        } catch (e: Throwable) {
            Log.e(TAG, "getVideoSize: Error extracting video size: ${e.message}", e)
            null
        } finally {
            retriever.release()
        }
    }
}
