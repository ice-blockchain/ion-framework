package com.appodeal.appodeal_flutter

import com.appodeal.ads.BannerCallbacks
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AppodealBanner(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {

    val adChannel: MethodChannel by lazy {
        MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appodeal_flutter/banner"
        ).apply { setMethodCallHandler(this@AppodealBanner) }
    }

    val adListener: Listener = Listener(adChannel)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {}

    internal class Listener(private val adChannel: MethodChannel) : BannerCallbacks {

        override fun onBannerLoaded(height: Int, isPrecache: Boolean) {
            adChannel.invokeMethod("onBannerLoaded", mapOf("isPrecache" to isPrecache))
        }

        override fun onBannerFailedToLoad() {
            adChannel.invokeMethod("onBannerFailedToLoad", null)
        }

        override fun onBannerShown() {
            adChannel.invokeMethod("onBannerShown", null)
        }

        override fun onBannerShowFailed() {
            adChannel.invokeMethod("onBannerShowFailed", null)
        }

        override fun onBannerClicked() {
            adChannel.invokeMethod("onBannerClicked", null)
        }

        override fun onBannerExpired() {
            adChannel.invokeMethod("onBannerExpired", null)
        }
    }
}