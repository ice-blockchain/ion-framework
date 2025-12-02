package com.appodeal.appodeal_flutter.native_ad.models

import com.appodeal.appodeal_flutter.apdLog

class AdIconConfig(
    val visible: Boolean = true,
    val size: Int = 50,
    val position: AdIconPosition = AdIconPosition.Start,
    val margin: Int = 0,
) {
    companion object {
        fun toAdIconConfig(map: Map<String, Any>): AdIconConfig {
            apdLog("toAdIconConfig: $map")
            return AdIconConfig(
                visible = map["visible"] as? Boolean ?: true,
                size = map["size"] as? Int ?: 50,
                position = AdIconPosition.values()[map["position"] as? Int ?: 0],
                margin = map["margin"] as? Int ?: 0,
            )
        }
    }
}

enum class AdIconPosition { Start, End }
