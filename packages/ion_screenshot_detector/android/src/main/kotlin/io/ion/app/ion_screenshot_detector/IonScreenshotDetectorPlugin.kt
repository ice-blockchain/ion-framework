package io.ion.app.ion_screenshot_detector

import android.app.Activity
import android.content.ContentResolver
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel

/** IonScreenshotDetectorPlugin */
class IonScreenshotDetectorPlugin : FlutterPlugin, EventChannel.StreamHandler, ActivityAware {
  private var lastDetectedPath: String? = null
  private var contentResolver: ContentResolver? = null
  private var eventSink: EventChannel.EventSink? = null
  private var screenshotObserver: ContentObserver? = null
  private lateinit var channel: EventChannel
  private var activity: Activity? = null
  private var screenCaptureCallback: Any? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    contentResolver = binding.applicationContext.contentResolver
    channel = EventChannel(binding.binaryMessenger, "io.ion.app/screenshots")
    channel.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setStreamHandler(null)
    contentResolver = null
    screenshotObserver = null
    unregisterScreenshotDetector()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    registerScreenshotDetector()
  }

  override fun onDetachedFromActivity() {
    unregisterScreenshotDetector()
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    registerScreenshotDetector()
  }

  override fun onDetachedFromActivityForConfigChanges() {
    unregisterScreenshotDetector()
    activity = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    registerScreenshotDetector()
  }

  override fun onCancel(arguments: Any?) {
    unregisterScreenshotDetector()
  }

  private fun registerScreenshotObserver() {
    screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
      override fun onChange(selfChange: Boolean, uri: Uri?) {
        super.onChange(selfChange, uri)
        uri?.let {
          if (lastDetectedPath == it.path) {
            return
          }
          lastDetectedPath = it.path
          var path: String = ""
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            path = queryRelativeDataColumn(uri)
          } else {
            path = queryDataColumn(uri)
          }
          if (!path.isEmpty()) {
            eventSink?.success(path)
          }
        }
      }
    }

    contentResolver?.registerContentObserver(
      MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
      true,
      screenshotObserver!!
    )
  }

  private fun registerScreenshotDetector() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      registerScreenCaptureCallback()
    } else {
      registerScreenshotObserver()
    }
  }

  private fun unregisterScreenshotDetector() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      unregisterScreenCaptureCallback()
    } else {
      contentResolver?.unregisterContentObserver(screenshotObserver!!)
    }
    eventSink = null
    screenshotObserver = null
  }

  private fun registerScreenCaptureCallback() {
    if (screenCaptureCallback != null) return
    // Using anonymous class to implement Activity.ScreenCaptureCallback
    screenCaptureCallback = object : Activity.ScreenCaptureCallback {
      override fun onScreenCaptured() {
        eventSink?.success("")
      }
    }
    // Cast screenCaptureCallback to the correct type and register
    activity?.registerScreenCaptureCallback(
      activity!!.mainExecutor,
      screenCaptureCallback as Activity.ScreenCaptureCallback
    )
  }

  private fun unregisterScreenCaptureCallback() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && screenCaptureCallback != null) {
      // Safe casting back to Activity.ScreenCaptureCallback
      activity?.unregisterScreenCaptureCallback(screenCaptureCallback as Activity.ScreenCaptureCallback)
      screenCaptureCallback = null
    }
  }

  private fun queryWithRetry(uri: Uri, maxRetries: Int, queryFunction: (Uri) -> String): String {
    repeat(maxRetries) { attempt ->
      try {
        return queryFunction(uri)
      } catch (e: IllegalStateException) {
        if (attempt == maxRetries - 1) {
          android.util.Log.w("IonScreenshotDetector", "Media content not accessible after $maxRetries attempts: ${e.message}")
          return ""
        }
        // Wait before retry (exponential backoff)
        Thread.sleep(100L * (attempt + 1))
      } catch (e: Exception) {
        android.util.Log.e("IonScreenshotDetector", "Unexpected error in query: ${e.message}")
        return ""
      }
    }
    return ""
  }

  private fun queryDataColumn(uri: Uri): String {
    return queryWithRetry(uri, maxRetries = 3) { uriToQuery ->
      var finalPath: String = ""
      val projection = arrayOf(
        MediaStore.Images.Media.DATA
      )
      contentResolver?.query(
        uriToQuery,
        projection,
        null,
        null,
        null
      )?.use { cursor ->
        val dataColumn = cursor.getColumnIndex(MediaStore.Images.Media.DATA)

        while (cursor.moveToNext()) {
          val path = cursor.getString(dataColumn)
          if (path.contains("screenshot", true)) {
            finalPath = path
            break
          }
        }
      }
      finalPath
    }
  }

  private fun queryRelativeDataColumn(uri: Uri): String {
    return queryWithRetry(uri, maxRetries = 3) { uriToQuery ->
      var finalPath: String = ""
      val projection = arrayOf(
        MediaStore.Images.Media.DISPLAY_NAME,
        MediaStore.Images.Media.RELATIVE_PATH
      )
      contentResolver?.query(
        uriToQuery,
        projection,
        null,
        null,
        null
      )?.use { cursor ->
        val relativePathColumn =
          cursor.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH)
        val displayNameColumn =
          cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
        while (cursor.moveToNext()) {
          val name = cursor.getString(displayNameColumn)
          val relativePath = cursor.getString(relativePathColumn)
          if (name.contains("screenshot", true) or
            relativePath.contains("screenshot", true)
          ) {
            finalPath = relativePath
            break
          }
        }
      }
      finalPath
    }
  }
}
