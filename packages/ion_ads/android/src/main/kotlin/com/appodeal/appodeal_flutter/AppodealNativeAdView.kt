package com.appodeal.appodeal_flutter

import android.app.Activity
import android.view.View
import android.widget.RatingBar
import android.widget.TextView
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
            val nativeAdCount = Appodeal.getAvailableNativeAdsCount()
            apdLog("AppodealNativeAdView#adView-lazy nativeAdCount:$nativeAdCount")
            val nativeAd = Appodeal.getNativeAds(1).firstOrNull() ?: return@lazy WeakReference(null)
            val nativeAdOptions = nativeAdOptions ?: return@lazy WeakReference(null)

            apdLog("AppodealNativeAdView#adView-lazy-nativeAdOptions: $nativeAdOptions")
            val templateNativeAdViewBinder = templateNativeAdViewBinder
            val adView = templateNativeAdViewBinder.bind(activity, nativeAdOptions)
            apdLog("AppodealNativeAdView#adView-lazy-nativeAdView: $adView")

            val ratingBar = adView.findViewById<RatingBar>(R.id.native_custom_rating)
            val descriptionView = adView.findViewById<TextView>(R.id.native_custom_description)
            if (nativeAd.rating > 0) {
                ratingBar?.visibility = View.VISIBLE
                descriptionView?.visibility = View.GONE
                ratingBar?.rating = nativeAd.rating
            } else {
                ratingBar?.visibility = View.INVISIBLE
                descriptionView?.visibility = View.VISIBLE
            }

            adView.adChoiceView?.visibility = View.GONE

            apdLog("AppodealNativeAdView#adView-lazy-registerView placement: $placement")
            adView.registerView(nativeAd, placement)
            return@lazy WeakReference(adView)
        } catch (e: Exception) {
            apdLog("AppodealNativeAdView#adView-lazy-error: ${e.message}")
            return@lazy WeakReference(null)
        }
    }

    override fun getView(): View? {
        apdLog("AppodealNativeAdView#adView: getView nativeAdOptions:$nativeAdOptions")
        return adView.get()
    }

    override fun dispose() {
        adView.get()?.destroy()
        adView.clear()
    }
}
