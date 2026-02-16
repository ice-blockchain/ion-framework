package com.appodeal.appodeal_flutter.native_ad.models

import android.graphics.Color
import com.appodeal.appodeal_flutter.apdLog
import com.appodeal.appodeal_flutter.native_ad.parseColor
import com.appodeal.ads.nativead.Position

class AdActionButtonConfig(
    val fontSize: Int = 14,
    val textColor: Int = Color.BLACK,
    val backgroundColor: Int = Color.TRANSPARENT,
    val margin: Int = 0,
    val radius: Int = 8,
    val position: Position = Position.START_TOP,
) {
    companion object {
        fun toAdActionButtonConfig(map: Map<String, Any>): AdActionButtonConfig {
            apdLog("toAdActionButtonConfig: $map")
            val idxPosition = map["position"] as? Int ?: 0

            return AdActionButtonConfig(
                fontSize = map["fontSize"] as? Int ?: 12,
                textColor = parseColor(map["textColor"] as? String) ?: Color.BLACK,
                backgroundColor = parseColor(map["backgroundColor"] as? String) ?: Color.TRANSPARENT,
                margin = map["margin"] as? Int ?: 0,
                radius = map["radius"] as? Int ?: 8,
                position = Position.entries[idxPosition],
            )
        }
    }
}