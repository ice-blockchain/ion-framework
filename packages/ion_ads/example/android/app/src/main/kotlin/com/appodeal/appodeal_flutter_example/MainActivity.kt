package com.appodeal.appodeal_flutter_example

import com.appodeal.ads.Appodeal
import com.appodeal.appodeal_flutter.nativeAdViewBinder
import com.appodeal.appodeal_flutter_example.native_ad.NativeAdViewBinderImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Appodeal.nativeAdViewBinder = NativeAdViewBinderImpl()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        Appodeal.nativeAdViewBinder = null
    }
}
