package com.appodeal.appodeal_flutter.native_ad.models

import android.graphics.Color
import com.appodeal.appodeal_flutter.apdLog
import com.appodeal.appodeal_flutter.native_ad.parseColor

class AdAttributionConfig(
    val fontSize: Int = 14,
    val textColor: Int = Color.WHITE,
    val backgroundColor: Int = Color.RED,
    val margin: Int = 0,
) {
    companion object {
        fun toAdAttributionConfig(map: Map<String, Any>): AdAttributionConfig {
            apdLog("toAdAttributionConfig: $map")
            return AdAttributionConfig(
                fontSize = map["fontSize"] as? Int ?: 14,
                textColor = parseColor(map["textColor"] as? String) ?: Color.WHITE,
                backgroundColor = parseColor(map["backgroundColor"] as? String) ?: Color.RED,
                margin = map["margin"] as? Int ?: 0,
            )
        }
    }
}