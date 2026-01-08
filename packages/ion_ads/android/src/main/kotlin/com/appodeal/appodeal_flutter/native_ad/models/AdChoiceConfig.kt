package com.appodeal.appodeal_flutter.native_ad.models

import com.appodeal.appodeal_flutter.apdLog
import com.appodeal.ads.nativead.Position as NativeAdChoicePosition

class AdChoiceConfig(
    val position: NativeAdChoicePosition = NativeAdChoicePosition.END_TOP,
    val margin: Double = 0.0,
) {
    companion object {
        fun toAdChoiceConfig(map: Map<String, Any>): AdChoiceConfig {
            apdLog("toAdChoiceConfig: $map")
            val idxPosition = map["position"] as? Int ?: 0
            
            return AdChoiceConfig(
                position = NativeAdChoicePosition.entries[idxPosition],
                margin = map["margin"] as? Double ?: 0.0,
            )
        }
    }
}