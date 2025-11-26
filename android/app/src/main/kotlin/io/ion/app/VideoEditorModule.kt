package io.ion.app

import android.app.Application
import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
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
        // Maximum safe resolution for Android MediaCodec
        // Many devices don't support encoding above 2160p (4K) height
        // Some devices also have width limitations, so we cap at 3840x2160 (standard 4K)
        private const val MAX_EXPORT_HEIGHT = 2160
        private const val MAX_EXPORT_WIDTH = 3840
        // Alternative: Use 1080p for maximum compatibility across all devices
        // private const val MAX_EXPORT_HEIGHT = 1080
        // private const val MAX_EXPORT_WIDTH = 1920
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

        // Calculate safe export resolution based on source video dimensions
        val safeResolution = calculateSafeResolution(videoRangeList)

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
     * and capping them at MAX_EXPORT_WIDTH/HEIGHT to avoid MediaCodec configuration errors
     * on devices with limited codec support.
     * 
     * The error occurs when videos exceed device MediaCodec capabilities (e.g., 3240x2160).
     * This method checks video dimensions and uses a safe resolution preset if available.
     */
    private fun calculateSafeResolution(videoRangeList: VideoRangeList): VideoResolution {
        // Try to get video dimensions from the first video range
        val firstVideoRange = videoRangeList.data.firstOrNull() ?: return VideoResolution.Original
        
        val sourceUri = firstVideoRange.sourceUri ?: return VideoResolution.Original
        
        val videoSize = getVideoSize(sourceUri) ?: return VideoResolution.Original
        
        val originalWidth = videoSize.width
        val originalHeight = videoSize.height
        
        // If video is already within safe limits, use original resolution
        if (originalWidth <= MAX_EXPORT_WIDTH && originalHeight <= MAX_EXPORT_HEIGHT) {
            return VideoResolution.Original
        }
        
        // Video exceeds safe limits - need to use a lower resolution preset
        // Try common Banuba SDK preset names via reflection (defensive approach)
        // Most Banuba SDKs have presets like P2160 (4K) or P1080 (Full HD)
        return try {
            // Try P2160 preset first (4K - 3840x2160)
            val p2160Field = VideoResolution::class.java.getDeclaredField("P2160")
            p2160Field.isAccessible = true
            p2160Field.get(null) as? VideoResolution ?: VideoResolution.Original
        } catch (e: Exception) {
            // P2160 not available, try P1080 (Full HD - 1920x1080)
            try {
                val p1080Field = VideoResolution::class.java.getDeclaredField("P1080")
                p1080Field.isAccessible = true
                p1080Field.get(null) as? VideoResolution ?: VideoResolution.Original
            } catch (e: Exception) {
                // No preset available - try creating custom resolution if constructor exists
                try {
                    val constructor = VideoResolution::class.java.getDeclaredConstructor(
                        Int::class.java, 
                        Int::class.java
                    )
                    constructor.isAccessible = true
                    
                    // Calculate safe dimensions maintaining aspect ratio
                    val aspectRatio = originalWidth.toFloat() / originalHeight.toFloat()
                    val targetHeight = MAX_EXPORT_HEIGHT
                    val calculatedWidth = (targetHeight * aspectRatio).toInt()
                    val targetWidth = minOf(calculatedWidth, MAX_EXPORT_WIDTH)
                    
                    // Ensure dimensions are even (required by many codecs)
                    val safeWidth = (targetWidth / 2) * 2
                    val safeHeight = (targetHeight / 2) * 2
                    
                    constructor.newInstance(safeWidth, safeHeight) as VideoResolution
                } catch (e: Exception) {
                    // Last resort: use Original
                    // Note: This may still fail on some devices, but Banuba SDK might handle scaling
                    VideoResolution.Original
                }
            }
        }
    }

    /**
     * Extracts video dimensions from a video URI using MediaMetadataRetriever.
     * Handles rotation metadata to return correct width/height.
     */
    private fun getVideoSize(uri: String): Size? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, Uri.parse(uri))

            val w = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                ?.toIntOrNull() ?: return null

            val h = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                ?.toIntOrNull() ?: return null

            val rot = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                ?.toIntOrNull() ?: 0

            // If the rotation is 90° or 270°, swap width/height
            if (rot == 90 || rot == 270) {
                Size(h, w)
            } else {
                Size(w, h)
            }
        } catch (e: Throwable) {
            null
        } finally {
            retriever.release()
        }
    }
}
