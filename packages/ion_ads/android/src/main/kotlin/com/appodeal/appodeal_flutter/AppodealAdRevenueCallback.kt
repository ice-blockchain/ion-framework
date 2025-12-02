package com.appodeal.appodeal_flutter

import com.appodeal.ads.Appodeal
import com.appodeal.ads.revenue.AdRevenueCallbacks
import com.appodeal.ads.revenue.RevenueInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AppodealAdRevenueCallback(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {

    val adChannel: MethodChannel by lazy {
        MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "appodeal_flutter/adrevenue"
        ).apply { setMethodCallHandler(this@AppodealAdRevenueCallback) }
    }

    val adListener: Listener = Listener(adChannel)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {}

    internal class Listener(private val adChannel: MethodChannel) : AdRevenueCallbacks {
        override fun onAdRevenueReceive(revenueInfo: RevenueInfo) {
            adChannel.invokeMethod(
                "onAdRevenueReceive",
                mapOf(
                    "adType" to resolveAdType(revenueInfo.adType),
                    "networkName" to revenueInfo.networkName,
                    "demandSource" to revenueInfo.demandSource,
                    "adUnitName" to revenueInfo.adUnitName,
                    "placement" to revenueInfo.placement,
                    "revenue" to revenueInfo.revenue,
                    "currency" to revenueInfo.currency,
                    "revenuePrecision" to revenueInfo.revenuePrecision
                )
            )
        }

        // FIXME: ad type for banners isn't correct from native side
        private fun resolveAdType(adType: Int): Int {
            return if (adType == BANNER_ALL) Appodeal.BANNER else adType
        }
    }
}

private const val BANNER_ALL = Appodeal.BANNER or
        Appodeal.BANNER_BOTTOM or
        Appodeal.BANNER_TOP or
        Appodeal.BANNER_VIEW or
        Appodeal.BANNER_LEFT or
        Appodeal.BANNER_RIGHT
