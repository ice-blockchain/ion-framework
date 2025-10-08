package io.ion.app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.service.notification.StatusBarNotification
import android.util.Log
import android.util.Size
import androidx.core.os.bundleOf
import com.banuba.sdk.core.EditorUtilityManager
import com.banuba.sdk.core.license.BanubaVideoEditor
import com.banuba.sdk.core.license.LicenseStateCallback
import com.banuba.sdk.export.data.ExportResult
import com.banuba.sdk.export.utils.EXTRA_EXPORTED_SUCCESS
import com.banuba.sdk.pe.BanubaPhotoEditor
import com.banuba.sdk.pe.PhotoCreationActivity
import com.banuba.sdk.pe.data.PhotoEditorConfig
import com.banuba.sdk.ve.ext.VideoEditorUtils.getKoin
import com.banuba.sdk.ve.flow.VideoCreationActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.koin.core.context.stopKoin
import org.koin.core.error.InstanceCreationException
import java.io.File


class MainActivity : FlutterFragmentActivity() {
    companion object {
        // For Photo Editor
        private const val PHOTO_EDITOR_REQUEST_CODE = 8888
        private const val METHOD_INIT_PHOTO_EDITOR = "initPhotoEditor"
        private const val METHOD_START_PHOTO_EDITOR = "startPhotoEditor"
        private const val ARG_EXPORTED_PHOTO_FILE = "argExportedPhotoFilePath"

        // For Video Editor
        const val CONFIG_ENABLE_CUSTOM_AUDIO_BROWSER = false
        private const val VIDEO_EDITOR_REQUEST_CODE = 7788
        private const val METHOD_INIT_VIDEO_EDITOR = "initVideoEditor"
        private const val METHOD_START_VIDEO_EDITOR = "startVideoEditor"
        private const val METHOD_START_VIDEO_EDITOR_PIP = "startVideoEditorPIP"
        private const val METHOD_START_VIDEO_EDITOR_TRIMMER = "startVideoEditorTrimmer"
        private const val METHOD_RELEASE_VIDEO_EDITOR = "releaseVideoEditor"
        private const val METHOD_DEMO_PLAY_EXPORTED_VIDEO = "playExportedVideo"
        private const val ARG_EXPORTED_VIDEO_FILE = "argExportedVideoFilePath"
        private const val ARG_EXPORTED_VIDEO_COVER = "argExportedVideoCoverPreviewPath"

        // Errors code
        private const val ERR_CODE_SDK_NOT_INITIALIZED = "ERR_SDK_NOT_INITIALIZED"
        private const val ERR_CODE_SDK_LICENSE_REVOKED = "ERR_SDK_LICENSE_REVOKED"


    }

    private var exportResult: MethodChannel.Result? = null

    // Track current editing file for cleanup
    private var currentEditingFile: File? = null

    private var videoEditorSDK: BanubaVideoEditor? = null
    private var photoEditorSDK: BanubaPhotoEditor? = null
    private var videoEditorModule: VideoEditorModule? = null

    private lateinit var audioFocusHandler: AudioFocusHandler

    // Bundle for enabling Editor V2
    private val extras = bundleOf(
        "EXTRA_USE_EDITOR_V2" to true
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioFocusHandler = AudioFocusHandler(applicationContext, flutterEngine)

        // Setup notification clearing channel
        setupNotificationChannel(flutterEngine)

        // Set up your MethodChannel here after registration
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "banubaSdkChannel"
        ).setMethodCallHandler { call, result ->
            // Initialize export result callback to deliver the results back to Flutter
            exportResult = result

            when (call.method) {
                METHOD_INIT_VIDEO_EDITOR -> {
                    val licenseToken = call.arguments as String
                    videoEditorSDK = BanubaVideoEditor.initialize(licenseToken)

                    if (videoEditorSDK == null) {
                        // The SDK token is incorrect - empty or truncated
                        result.error(ERR_CODE_SDK_NOT_INITIALIZED, "", null)
                    } else {
                        result.success(null)
                    }
                }

                METHOD_START_VIDEO_EDITOR_TRIMMER -> {
                    val videoFilePath = call.argument("videoFilePath") as? String
                    val maxVideoDurationMs = call.argument<Int?>("maxVideoDurationMs")
                    val coverSelectionEnabled =
                        call.argument<Boolean?>("coverSelectionEnabled") ?: true
                    val trimmerVideoUri = videoFilePath?.let { Uri.fromFile(File(it)) }
                    if (trimmerVideoUri == null) {
                        exportResult?.error("ERR_START_TRIMMER_MISSING_VIDEO", "", null)
                    } else {
                        checkSdkLicenseVideoEditor(
                            callback = { isValid ->
                                if (isValid) {
                                    // ✅ The license is active
                                    // Initialize video editor sdk dependencies
                                    val aspectRatio =
                                        getVideoSize(applicationContext, trimmerVideoUri)?.let {
                                            it.width.toDouble() / it.height.toDouble()
                                        }

                                    videoEditorModule = VideoEditorModule().apply {
                                        initialize(
                                            application,
                                            aspectRatio,
                                            maxVideoDurationMs?.toLong(),
                                            coverSelectionEnabled,
                                        )
                                    }
                                    startVideoEditorModeTrimmer(trimmerVideoUri)
                                } else {
                                    // ❌ Use of SDK is restricted: the license is revoked or expired
                                    result.error(ERR_CODE_SDK_LICENSE_REVOKED, "", null)
                                }
                            },
                            onError = { result.error(ERR_CODE_SDK_NOT_INITIALIZED, "", null) }
                        )
                    }
                }

                METHOD_RELEASE_VIDEO_EDITOR -> {
                    releaseVideoEditorModule()
                    videoEditorSDK = null
                    result.success(null)
                }

                METHOD_INIT_PHOTO_EDITOR -> {
                    val licenseToken = call.arguments as String
                    photoEditorSDK = BanubaPhotoEditor.initialize(licenseToken)

                    if (photoEditorSDK == null) {
                        // The SDK token is incorrect - empty or truncated
                        result.error(ERR_CODE_SDK_NOT_INITIALIZED, "", null)
                    } else {
                        result.success(null)
                    }
                }

                METHOD_START_PHOTO_EDITOR -> {
                    if (photoEditorSDK == null) {
                        // The SDK token is incorrect - empty or truncated
                        result.error(ERR_CODE_SDK_NOT_INITIALIZED, "", null)
                    } else {
                        // ✅ The license is active
                        val imageUrl =
                            call.argument<String>("imagePath") // Get the image URL from Flutter
                        if (imageUrl.isNullOrEmpty()) {
                            result.error("INVALID_ARGUMENT", "Image URL is required", null)
                            return@setMethodCallHandler
                        }
                        val imageUri = Uri.fromFile(File(imageUrl))
                        val config = PhotoEditorConfig.Builder(this).build();
                        startActivityForResult(
                            PhotoCreationActivity.startFromEditor(this, config, imageUri),
                            PHOTO_EDITOR_REQUEST_CODE
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // Observe export video results
    override fun onActivityResult(requestCode: Int, result: Int, intent: Intent?) {
        super.onActivityResult(requestCode, result, intent)
        
        when (requestCode) {
            VIDEO_EDITOR_REQUEST_CODE -> handleVideoEditorResult(result, intent)
            PHOTO_EDITOR_REQUEST_CODE -> handlePhotoEditorResult(result, intent)
        }
    }
    
    private fun handleVideoEditorResult(result: Int, intent: Intent?) {
        when (result) {
            RESULT_OK -> {
                val exportResult = intent?.getParcelableExtra(EXTRA_EXPORTED_SUCCESS) as? ExportResult.Success
                if (exportResult == null) {
                    sendExportError("ERR_MISSING_EXPORT_RESULT", "")
                } else {
                    val data = prepareVideoExportData(exportResult)
                    sendExportSuccess(data)
                }
                cleanupCurrentEditingFile()
            }
            RESULT_CANCELED -> {
                cleanupCurrentEditingFile()
                // User cancelled video editing - return null to indicate cancellation
                sendExportSuccess(null)
            }
        }
    }
    
    private fun handlePhotoEditorResult(result: Int, intent: Intent?) {
        when (result) {
            RESULT_OK -> {
                val data = preparePhotoExportData(intent)
                sendExportSuccess(data)
            }
            RESULT_CANCELED -> {
                // User cancelled photo editing - return null to indicate cancellation
                sendExportSuccess(null)
            }
        }
    }
    
    private fun sendExportSuccess(data: Any?) {
        exportResult?.success(data)
        exportResult = null // Cleaning to avoid sending duplicates
    }
    
    private fun sendExportError(code: String, message: String) {
        exportResult?.error(code, message, null)
        exportResult = null
    }

    // Customize photo export data results to meet your requirements.
    // You can use Map or JSON to pass custom data for your app.
    private fun preparePhotoExportData(result: Intent?): Map<String, Any?> {
        val photoUri = result?.getParcelableExtra(PhotoCreationActivity.EXTRA_EXPORTED) as? Uri
        return mapOf(
            ARG_EXPORTED_PHOTO_FILE to photoUri?.toString()
        )
    }

    // Customize export data results to meet your requirements.
    // You can use Map or JSON to pass custom data for your app.
    private fun prepareVideoExportData(result: ExportResult.Success): Map<String, Any?> {
        // First exported video file path is used to play video in this sample to demonstrate
        // the result of video export.
        // You can provide your custom logic.
        val firstVideoFilePath = result.videoList[0].sourceUri.toString()
        val videoCoverImagePath = result.preview.toString()
        val data = mapOf(
            ARG_EXPORTED_VIDEO_FILE to firstVideoFilePath,
            ARG_EXPORTED_VIDEO_COVER to videoCoverImagePath
        )
        return data
    }

    private fun startVideoEditorModeTrimmer(trimmerVideo: Uri) {
        // Create a safe copy of the video for editing
        val safeEditingUri = copyVideoToSafeLocation(trimmerVideo)
        val finalUri = safeEditingUri ?: trimmerVideo

        startActivityForResult(
            VideoCreationActivity.startFromTrimmer(
                context = this,
                // setup data that will be acceptable during export flow
                additionalExportData = null,
                // set TrackData object if you open VideoCreationActivity with preselected music track
                audioTrackData = null,
                // set Trimmer video configuration
                predefinedVideos = arrayOf(finalUri),
                extras = extras
            ), VIDEO_EDITOR_REQUEST_CODE
        )
    }

    private fun copyVideoToSafeLocation(originalUri: Uri): Uri? {
        try {
            val originalPath = originalUri.path
            if (originalPath == null) {
                return null
            }

            val originalFile = File(originalPath)
            if (!originalFile.exists()) {
                return null
            }

            val editingFileName = "editing_${System.currentTimeMillis()}.mp4"
            val editingFile = File(filesDir, editingFileName)

            if (editingFile.exists()) {
                editingFile.delete()
            }

            originalFile.copyTo(editingFile, overwrite = true)
            currentEditingFile = editingFile
            return Uri.fromFile(editingFile)
        } catch (e: Exception) {
            return null
        }
    }

    private fun cleanupCurrentEditingFile() {
        val file = currentEditingFile ?: return

        try {
            if (file.exists() && !file.delete()) {
                Log.w("EDIT_VIDEO", "Failed to delete editing file: ${file.name}")
            }
        } catch (e: Exception) {
            Log.e("EDIT_VIDEO", "Failed to cleanup editing file: ${e.message}", e)
        }

        currentEditingFile = null
        releaseVideoEditorModule()
    }

    private fun releaseVideoEditorModule() {
        if (videoEditorModule != null) {
            val utilityManager = try {
                // EditorUtilityManager is NULL when the token is expired or revoked.
                // This dependency is not explicitly created in DI.
                getKoin().getOrNull<EditorUtilityManager>()
            } catch (e: InstanceCreationException) {
                null
            }
            utilityManager?.release()
            stopKoin()
            videoEditorModule = null
        }
    }

    private fun checkSdkLicenseVideoEditor(
        callback: LicenseStateCallback,
        onError: () -> Unit
    ) {
        val sdk = videoEditorSDK
        if (sdk == null) {
            onError()
        } else {
            // Checking the license might take around 1 sec in the worst case.
            // Please optimize use if this method in your application for the best user experience
            sdk.getLicenseState(callback)
        }
    }

    private fun getVideoSize(context: Context, uri: Uri): Size? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)

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
        } catch (_: Throwable) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun setupNotificationChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "notification_channel"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "clearNotificationGroup" -> {
                    val groupIdentifier = call.argument<String>("groupIdentifier")
                    if (groupIdentifier == null) {
                        result.error("INVALID_ARGUMENTS", "Missing groupIdentifier", null)
                    } else {
                        clearNotificationGroup(groupIdentifier)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun clearNotificationGroup(groupIdentifier: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            Log.d("MainActivity", "Attempting to clear notifications for groupIdentifier: $groupIdentifier")

            val activeNotifications: Array<StatusBarNotification> = notificationManager.activeNotifications
            Log.d("MainActivity", "Total active notifications: ${activeNotifications.size}")

            for (notification in activeNotifications) {
                val notificationGroup = notification.notification?.group
                val notificationTag = notification.tag

                Log.d("MainActivity", "Notification - ID: ${notification.id}, Tag: $notificationTag, Group: $notificationGroup")

                // Clear by group or tag that matches groupIdentifier
                if (notificationGroup == groupIdentifier || notificationTag == groupIdentifier) {
                    notificationManager.cancel(notificationTag, notification.id)
                    Log.d("MainActivity", "Cancelled notification with ID: ${notification.id}")
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error clearing notifications: ${e.message}", e)
        }
    }
}
