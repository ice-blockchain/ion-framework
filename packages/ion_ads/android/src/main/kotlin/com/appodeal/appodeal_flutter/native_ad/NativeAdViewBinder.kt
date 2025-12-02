package com.appodeal.appodeal_flutter.native_ad

import android.app.Activity
import androidx.annotation.Keep
import com.appodeal.ads.nativead.NativeAdView

@Keep
fun interface NativeAdViewBinder {
    fun bind(activity: Activity, nativeAdOptions: NativeAdOptions): NativeAdView
}