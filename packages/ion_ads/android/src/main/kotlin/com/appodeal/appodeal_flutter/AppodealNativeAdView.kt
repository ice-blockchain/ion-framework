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
        try {
            apdLog("AppodealNativeAdView#adView-lazy")
            val nativeAd = Appodeal.getNativeAds(1).firstOrNull() ?: return@lazy WeakReference(null)
            val nativeAdOptions = nativeAdOptions ?: return@lazy WeakReference(null)

            apdLog("AppodealNativeAdView#adView-lazy-nativeAdOptions: $nativeAdOptions")

            apdLog("AppodealNativeAdView#adView-lazy-nativeAdViewType: ${nativeAdOptions.nativeAdViewType}")
            val templateNativeAdViewBinder = templateNativeAdViewBinder
            val adView = templateNativeAdViewBinder.bind(activity, nativeAdOptions)

//            val adView = when (nativeAdOptions.nativeAdViewType) {
//                NativeAdViewType.Custom -> {
//                    apdLog("AppodealNativeAdView#adView-lazy-nativeAdViewType: Custom")
//                    val customNativeAdViewBinder = Appodeal.nativeAdViewBinder
//                        ?: throw IllegalArgumentException("NativeAdViewBinder is not set")
//                    customNativeAdViewBinder.bind(activity, nativeAdOptions)
//                }
//
//                else -> {
//                    apdLog("AppodealNativeAdView#adView-lazy-nativeAdViewType: ${nativeAdOptions.nativeAdViewType}")
//                    val templateNativeAdViewBinder = templateNativeAdViewBinder
//                    templateNativeAdViewBinder.bind(activity, nativeAdOptions)
//                }
//            }
            apdLog("AppodealNativeAdView#adView-lazy-registerView: $adView")
            adView.registerView(nativeAd, placement)
            return@lazy WeakReference(adView)
        } catch (e: Exception) {
            apdLog("AppodealNativeAdView#adView-lazy-error: ${e.message}")
            return@lazy WeakReference(null)
        }
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
