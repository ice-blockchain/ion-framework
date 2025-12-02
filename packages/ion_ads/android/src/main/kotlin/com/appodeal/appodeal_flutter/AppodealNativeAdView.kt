package com.appodeal.appodeal_flutter

import android.app.Activity
import android.view.View
import com.appodeal.ads.Appodeal
import com.appodeal.ads.nativead.NativeAdView
import com.appodeal.appodeal_flutter.native_ad.NativeAdOptions
import com.appodeal.appodeal_flutter.native_ad.NativeAdViewType
import com.appodeal.appodeal_flutter.native_ad.templateNativeAdViewBinder
import io.flutter.plugin.platform.PlatformView
import java.lang.ref.WeakReference

internal class AppodealNativeAdView(activity: Activity, arguments: HashMap<*, *>) : PlatformView {

    init {
        apdLog("AppodealNativeAdView#init")
    }


    private val placement: String = arguments["placement"] as? String ?: "default"

    @Suppress("UNCHECKED_CAST")
    private val nativeAdOptions: NativeAdOptions? =
        NativeAdOptions.toNativeAdOptions(arguments["options"] as Map<String, Any>)

    private val adView: WeakReference<NativeAdView?> by lazy {

        apdLog("AppodealNativeAdView#adView-lazy")
        val availableCount = Appodeal.getAvailableNativeAdsCount()

        val nativeAd = Appodeal.getNativeAds(1).firstOrNull()
            ?: return@lazy WeakReference(null)

        apdLog("AppodealNativeAdView#adView-lazy-nativeAd: ${nativeAd}, availableCount: $availableCount")
        apdLog("AppodealNativeAdView#adView-lazy-nativeAd title: ${nativeAd.title}")
        apdLog("AppodealNativeAdView#adView-lazy-nativeAd description: ${nativeAd.description}")
        apdLog("AppodealNativeAdView#adView-lazy-nativeAd callToAction: ${nativeAd.callToAction}")

        val nativeAdOptions = nativeAdOptions
            ?: return@lazy WeakReference(null)

        apdLog("AppodealNativeAdView#adView-lazy-nativeAdOptions: $nativeAdOptions")

        val adView = when (nativeAdOptions.nativeAdViewType) {
            NativeAdViewType.Custom -> {

                apdLog("AppodealNativeAdView#adView-lazy-nativeAdViewType: Custom")
                val customNativeAdViewBinder = Appodeal.nativeAdViewBinder
                    ?: throw IllegalArgumentException("NativeAdViewBinder is not set")
                customNativeAdViewBinder.bind(activity, nativeAdOptions)


            }

            else -> {

                apdLog("AppodealNativeAdView#adView-lazy-nativeAdViewType: else")
                val templateNativeAdViewBinder = templateNativeAdViewBinder
                templateNativeAdViewBinder.bind(activity, nativeAdOptions)
            }
        }
        apdLog("AppodealNativeAdView#adView-lazy-registerView: $adView")
        adView.registerView(nativeAd, placement)
        WeakReference(adView)
    }

    override fun getView(): View? {
        apdLog("AppodealNativeAdView#adView: ${adView.get()}")
        return adView.get()
    }

    override fun dispose() {
        adView.get()?.destroy()
        adView.clear()
    }
}
