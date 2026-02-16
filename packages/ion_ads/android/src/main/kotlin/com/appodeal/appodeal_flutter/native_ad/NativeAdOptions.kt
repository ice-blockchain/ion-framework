package com.appodeal.appodeal_flutter.native_ad

import com.appodeal.appodeal_flutter.apdLog
import com.appodeal.appodeal_flutter.native_ad.models.AdActionButtonConfig
import com.appodeal.appodeal_flutter.native_ad.models.AdAttributionConfig
import com.appodeal.appodeal_flutter.native_ad.models.AdChoiceConfig
import com.appodeal.appodeal_flutter.native_ad.models.AdDescriptionConfig
import com.appodeal.appodeal_flutter.native_ad.models.AdIconConfig
import com.appodeal.appodeal_flutter.native_ad.models.AdMediaConfig
import com.appodeal.appodeal_flutter.native_ad.models.AdTitleConfig

class NativeAdOptions(
    val nativeAdViewType: NativeAdViewType,
    val adActionButtonConfig: AdActionButtonConfig,
    val adAttributionConfig: AdAttributionConfig,
    val adChoiceConfig: AdChoiceConfig,
    val adDescriptionConfig: AdDescriptionConfig,
    val adIconConfig: AdIconConfig,
    val adMediaConfig: AdMediaConfig,
    val adTitleConfig: AdTitleConfig,
) {
    override fun toString(): String {
        return "NativeAdOptions(nativeAdViewType=$nativeAdViewType, adActionButtonConfig=$adActionButtonConfig, adAttributionConfig=$adAttributionConfig, adChoiceConfig=$adChoiceConfig, adDescriptionConfig=$adDescriptionConfig, adIconConfig=$adIconConfig, adMediaConfig=$adMediaConfig, adTitleConfig=$adTitleConfig)"
    }

    companion object {
        @Suppress("UNCHECKED_CAST")
        fun toNativeAdOptions(args: Map<String, Any>): NativeAdOptions? = runCatching {
            apdLog("toNativeAdOptions: $args")
            val idxNativeAdViewType = args["nativeAdType"] as? Int
                ?: throw IllegalArgumentException("nativeAdType is required")
            NativeAdOptions(
                nativeAdViewType = NativeAdViewType.entries[idxNativeAdViewType],
                adActionButtonConfig = AdActionButtonConfig.toAdActionButtonConfig(args["adActionButtonConfig"] as Map<String, Any>),
                adAttributionConfig = AdAttributionConfig.toAdAttributionConfig(args["adAttributionConfig"] as Map<String, Any>),
                adChoiceConfig = AdChoiceConfig.toAdChoiceConfig(args["adChoiceConfig"] as Map<String, Any>),
                adDescriptionConfig = AdDescriptionConfig.toAdDescriptionConfig(args["adDescriptionConfig"] as Map<String, Any>),
                adIconConfig = AdIconConfig.toAdIconConfig(args["adIconConfig"] as Map<String, Any>),
                adMediaConfig = AdMediaConfig.toAdMediaConfig(args["adMediaConfig"] as Map<String, Any>),
                adTitleConfig = AdTitleConfig.toAdTitleConfig(args["adTitleConfig"] as Map<String, Any>),
            ).also {
                apdLog("NativeAdOptions: $it")
            }
        }.getOrNull()
    }
}

enum class NativeAdViewType { Custom, ContentStream, AppWall, NewsFeed, Chat, Article }