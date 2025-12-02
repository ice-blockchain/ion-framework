package com.appodeal.appodeal_flutter

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.ViewGroup
import com.appodeal.ads.Appodeal
import io.flutter.plugin.platform.PlatformView
import java.lang.ref.WeakReference

internal class AppodealAdView(activity: Activity, arguments: HashMap<*, *>) : PlatformView {

    private val placement: String = arguments["placement"] as? String ?: "default"
    private val bannerType: Int = toBannerType(arguments["adSize"] as HashMap<*, *>)
    private val adView: View = getAdView(activity.applicationContext)

    init {
        (adView.parent as? ViewGroup)?.removeView(adView)
        Appodeal.show(activity, bannerType, placement)
    }

    override fun getView(): View = adView

    override fun dispose() {}

    private fun toBannerType(size: HashMap<*, *>): Int = when (size["name"] as String) {
        "BANNER" -> Appodeal.BANNER_VIEW
        "MEDIUM_RECTANGLE" -> Appodeal.MREC
        else -> error("Banner type doesn't support")
    }

    private fun getAdView(context: Context): View = when (bannerType) {
        Appodeal.MREC -> refMrecAdView.get() ?: run {
            Appodeal.getMrecView(context).also { refMrecAdView = WeakReference(it) }
        }
        Appodeal.BANNER_VIEW -> refBannerAdView.get() ?: run {
            Appodeal.getBannerView(context).also { refBannerAdView = WeakReference(it) }
        }
        else -> error("Banner type doesn't support")
    }
}

private var refMrecAdView = WeakReference<View>(null)
private var refBannerAdView = WeakReference<View>(null)