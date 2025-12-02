package com.appodeal.appodeal_flutter

import com.appodeal.ads.InterstitialCallbacks
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AppodealInterstitial(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {

    val adChannel: MethodChannel by lazy {
        MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appodeal_flutter/interstitial"
        ).apply { setMethodCallHandler(this@AppodealInterstitial) }
    }

    val adListener: Listener = Listener(adChannel)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {}

    internal class Listener(private val adChannel: MethodChannel) : InterstitialCallbacks {

        override fun onInterstitialLoaded(isPrecache: Boolean) {
            adChannel.invokeMethod(
                "onInterstitialLoaded",
                mapOf("isPrecache" to isPrecache)
            )
        }

        override fun onInterstitialFailedToLoad() {
            adChannel.invokeMethod("onInterstitialFailedToLoad", null)
        }

        override fun onInterstitialShown() {
            adChannel.invokeMethod("onInterstitialShown", null)
        }

        override fun onInterstitialShowFailed() {
            adChannel.invokeMethod("onInterstitialShowFailed", null)
        }

        override fun onInterstitialClicked() {
            adChannel.invokeMethod("onInterstitialClicked", null)
        }

        override fun onInterstitialClosed() {
            adChannel.invokeMethod("onInterstitialClosed", null)
        }

        override fun onInterstitialExpired() {
            adChannel.invokeMethod("onInterstitialExpired", null)
        }
    }
}
