package io.ion.app

import android.app.Application
import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import android.util.Size
import androidx.core.net.toFile
import androidx.core.net.toUri
import androidx.fragment.app.Fragment
import java.io.File
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
        private const val TAG = "BanubaExport___"
        @JvmStatic
        var exportStartTime: Long = 0
            private set
        @JvmStatic
        var originalVideoSizeBytes: Long = 0
            private set
        @JvmStatic
        var originalVideoResolution: String? = null
            private set
    }

    override fun provideExportParams(
        effects: Effects,
        videoRangeList: VideoRangeList,
        musicEffects: List<MusicEffect>,
        videoVolume: Float
    ): List<ExportParams> {
        // Log export start
        exportStartTime = System.currentTimeMillis()
        Log.d(TAG, "Starting Banuba video export...")

        // Calculate original video size
        originalVideoSizeBytes = calculateOriginalVideoSize(videoRangeList)
        val originalSizeMB = originalVideoSizeBytes / (1024.0 * 1024.0)
        Log.d(TAG, "Original video size before Banuba: ${String.format("%.2f", originalSizeMB)} MB")

        // Extract original video resolution
        originalVideoResolution = getOriginalVideoResolution(videoRangeList)
        if (originalVideoResolution != null) {
            Log.d(TAG, "Original video resolution: $originalVideoResolution")
        }

        val exportSessionDir = exportDir.toFile().apply {
            deleteRecursively()
            mkdirs()
        }

        val exportVideo = ExportParams.Builder()
            .effects(effects)
            .fileName("export_video")
            .videoRangeList(videoRangeList)
            .destDir(exportSessionDir)
            .musicEffects(musicEffects)
            .volumeVideo(videoVolume)
            .build()

        return listOf(exportVideo)
    }

    private fun calculateOriginalVideoSize(videoRangeList: VideoRangeList): Long {
        var totalSize = 0L
        for (videoRange in videoRangeList.data) {
            val sourceUri = videoRange.sourceUri ?: continue
            try {
                val file = when {
                    sourceUri.scheme == "file" -> File(sourceUri.path ?: "")
                    else -> File(sourceUri.path ?: "")
                }
                if (file.exists()) {
                    totalSize += file.length()
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error calculating size for ${sourceUri}: ${e.message}")
            }
        }
        return totalSize
    }

    private fun getOriginalVideoResolution(videoRangeList: VideoRangeList): String? {
        val firstVideoRange = videoRangeList.data.firstOrNull() ?: return null
        val sourceUri = firstVideoRange.sourceUri ?: return null
        
        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(context, sourceUri)
            
            val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
            val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            
            retriever.release()
            
            if (width != null && height != null) {
                // Swap dimensions if rotated 90° or 270°
                val finalWidth = if (rotation == 90 || rotation == 270) height else width
                val finalHeight = if (rotation == 90 || rotation == 270) width else height
                "${finalWidth}x${finalHeight}"
            } else {
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error extracting original video resolution: ${e.message}")
            null
        }
    }

}
