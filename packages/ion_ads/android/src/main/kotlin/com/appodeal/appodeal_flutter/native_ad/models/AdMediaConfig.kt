package com.appodeal.appodeal_flutter.native_ad.models

import com.appodeal.appodeal_flutter.apdLog

class AdMediaConfig(
    val visible: Boolean = true,
    val position: AdMediaPosition = AdMediaPosition.Bottom,
    val margin: Int = 0,
) {
    companion object {
        fun toAdMediaConfig(map: Map<String, Any>): AdMediaConfig {
            apdLog("toAdMediaConfig: $map")
            return AdMediaConfig(
                visible = map["visible"] as? Boolean ?: true,
                position = AdMediaPosition.values()[(map["position"] as? Int ?: 0)],
                margin = map["margin"] as? Int ?: 0,
            )
        }
    }
}

enum class AdMediaPosition { Top, Bottom }
