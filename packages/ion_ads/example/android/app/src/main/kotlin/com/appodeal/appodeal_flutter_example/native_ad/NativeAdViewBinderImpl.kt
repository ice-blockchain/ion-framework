package com.appodeal.appodeal_flutter_example.native_ad

import android.app.Activity
import com.appodeal.ads.nativead.NativeAdView
import com.appodeal.appodeal_flutter.native_ad.NativeAdOptions
import com.appodeal.appodeal_flutter.native_ad.NativeAdViewBinder
import com.appodeal.appodeal_flutter_example.R

internal class NativeAdViewBinderImpl : NativeAdViewBinder {
    override fun bind(activity: Activity, nativeAdOptions: NativeAdOptions): NativeAdView {
        val layoutInflater = activity.layoutInflater
        return layoutInflater.inflate(R.layout.apd_native_ad_view_custom, null) as NativeAdView
    }
}
