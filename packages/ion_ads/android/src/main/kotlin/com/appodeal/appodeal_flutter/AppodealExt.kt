package com.appodeal.appodeal_flutter

import com.appodeal.ads.Appodeal
import com.appodeal.ads.utils.Log
import com.appodeal.appodeal_flutter.native_ad.NativeAdViewBinder

private var userNativeAdViewBinder: NativeAdViewBinder? = null

var Appodeal.nativeAdViewBinder: NativeAdViewBinder?
    get() = userNativeAdViewBinder
    set(value) {
        Log.log("Appodeal", "Flutter", "setNativeAdViewBinder")
        userNativeAdViewBinder = value
    }