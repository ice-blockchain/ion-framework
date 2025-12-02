package com.appodeal.appodeal_flutter.native_ad.models

import com.appodeal.appodeal_flutter.apdLog

class AdLayoutConfig(
    val margin: Int = 10,
) {
    companion object {
        fun toAdLayoutConfig(map: Map<String, Any>): AdLayoutConfig {
            apdLog("toAdLayoutConfig: $map")
            return AdLayoutConfig(
                margin = map["margin"] as? Int ?: 10,
            )
        }
    }

}
