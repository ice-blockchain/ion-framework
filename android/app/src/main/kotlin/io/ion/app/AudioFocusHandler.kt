package io.ion.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AudioFocusHandler(private val context: Context, flutterEngine: FlutterEngine) {
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "audio_focus_channel")
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var hasFocus = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initAudioFocus" -> {
                    setupAudioFocus()
                    result.success(true)
                }
                "requestAudioFocus" -> {
                    val success = requestAudioFocus()
                    result.success(success)
                }
                "abandonAudioFocus" -> {
                    abandonAudioFocus()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupAudioFocus() {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        // Don't request audio focus on initialization
    }

    private fun requestAudioFocus(): Boolean {
        if (audioManager == null) {
            setupAudioFocus()
        }

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // For API 26+
            val playbackAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()

            focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(playbackAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener { focusChange ->
                    handleAudioFocusChange(focusChange)
                }
                .build()

            audioManager?.requestAudioFocus(focusRequest!!)
        } else {
            // For API below 26
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus({ focusChange ->
                handleAudioFocusChange(focusChange)
            }, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }

        hasFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        channel.invokeMethod("onAudioFocusChange", hasFocus)
        return hasFocus
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
        hasFocus = false
        channel.invokeMethod("onAudioFocusChange", false)
    }

    private fun handleAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                // We have gained audio focus
                hasFocus = true
                channel.invokeMethod("onAudioFocusChange", true)
            }
            AudioManager.AUDIOFOCUS_LOSS, 
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, 
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // We have lost audio focus
                hasFocus = false
                channel.invokeMethod("onAudioFocusChange", false)
            }
        }
    }

    fun cleanup() {
        Log.d(TAG, "cleanup() called - starting cleanup process")
        
        // Abandon audio focus before cleanup
        if (hasFocus) {
            abandonAudioFocus()
        }
        
        // Remove method call handler to prevent memory leaks
        channel.setMethodCallHandler(null)
        
        // Clear references
        audioManager = null
        focusRequest = null
    }

    companion object {
        private const val TAG = "AudioFocusHandler"
    }
} 