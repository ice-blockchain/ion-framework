package com.appodeal.appodeal_flutter

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

internal abstract class IonAppodealBaseFlutterPlugin :
    FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private var activityReference = WeakReference<Activity>(null)
    private var contextReference = WeakReference<Context>(null)
    internal val activity: Activity get() = requireNotNull(activityReference.get())
    internal val context: Context get() = requireNotNull(activityReference.get() ?: contextReference.get())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        contextReference = WeakReference(binding.applicationContext)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityReference = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityReference = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {}
}