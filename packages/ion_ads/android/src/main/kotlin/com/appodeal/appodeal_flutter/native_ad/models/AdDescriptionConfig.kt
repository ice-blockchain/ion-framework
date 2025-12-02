package com.appodeal.appodeal_flutter.native_ad.models

import android.graphics.Color
import com.appodeal.appodeal_flutter.apdLog
import com.appodeal.appodeal_flutter.native_ad.parseColor

class AdDescriptionConfig(
    val fontSize: Int = 14,
    val textColor: Int = Color.BLACK,
    val backgroundColor: Int = Color.TRANSPARENT,
    val margin: Int = 0,
) {
    companion object {
        fun toAdDescriptionConfig(map: Map<String, Any>): AdDescriptionConfig {
            apdLog("toAdDescriptionConfig: $map")
            return AdDescriptionConfig(
                fontSize = map["fontSize"] as? Int ?: 14,
                textColor = parseColor(map["textColor"] as? String) ?: Color.BLACK,
                backgroundColor = parseColor(map["backgroundColor"] as? String) ?: Color.TRANSPARENT,
                margin = map["margin"] as? Int ?: 0,
            )
        }
    }
}