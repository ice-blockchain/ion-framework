package com.appodeal.appodeal_flutter

import com.appodeal.ads.RewardedVideoCallbacks
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AppodealRewarded(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {

    val adChannel: MethodChannel by lazy {
        MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appodeal_flutter/rewarded"
        ).apply { setMethodCallHandler(this@AppodealRewarded) }
    }

    val adListener: Listener = Listener(adChannel)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {}

    internal class Listener(private val adChannel: MethodChannel) : RewardedVideoCallbacks {

        override fun onRewardedVideoLoaded(isPrecache: Boolean) {
            adChannel.invokeMethod("onRewardedVideoLoaded", mapOf("isPrecache" to isPrecache))
        }

        override fun onRewardedVideoFailedToLoad() {
            adChannel.invokeMethod("onRewardedVideoFailedToLoad", null)
        }

        override fun onRewardedVideoShown() {
            adChannel.invokeMethod("onRewardedVideoShown", null)
        }

        override fun onRewardedVideoShowFailed() {
            adChannel.invokeMethod("onRewardedVideoShowFailed", null)
        }

        override fun onRewardedVideoFinished(amount: Double, currency: String) {
            adChannel.invokeMethod(
                "onRewardedVideoFinished",
                mapOf("amount" to amount, "reward" to currency)
            )
        }

        override fun onRewardedVideoClosed(finished: Boolean) {
            adChannel.invokeMethod("onRewardedVideoClosed", mapOf("isFinished" to finished))
        }

        override fun onRewardedVideoExpired() {
            adChannel.invokeMethod("onRewardedVideoExpired", null)
        }

        override fun onRewardedVideoClicked() {
            adChannel.invokeMethod("onRewardedVideoClicked", null)
        }
    }
}