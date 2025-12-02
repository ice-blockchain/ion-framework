package com.appodeal.appodeal_flutter

import com.appodeal.ads.MrecCallbacks
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AppodealMrec(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {

    val adChannel: MethodChannel by lazy {
        MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appodeal_flutter/mrec"
        ).apply { setMethodCallHandler(this@AppodealMrec) }
    }

    val adListener: Listener = Listener(adChannel)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {}

    internal class Listener(private val adChannel: MethodChannel) : MrecCallbacks {

        override fun onMrecLoaded(isPrecache: Boolean) {
            adChannel.invokeMethod("onMrecLoaded", mapOf("isPrecache" to isPrecache))
        }

        override fun onMrecFailedToLoad() {
            adChannel.invokeMethod("onMrecFailedToLoad", null)
        }

        override fun onMrecShown() {
            adChannel.invokeMethod("onMrecShown", null)
        }

        override fun onMrecShowFailed() {
            adChannel.invokeMethod("onMrecShowFailed", null)
        }

        override fun onMrecClicked() {
            adChannel.invokeMethod("onMrecClicked", null)
        }

        override fun onMrecExpired() {
            adChannel.invokeMethod("onMrecExpired", null)
        }
    }
}