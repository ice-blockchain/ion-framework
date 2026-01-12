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
//    val adLayoutConfig: AdLayoutConfig,
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
                nativeAdViewType = NativeAdViewType.values()[idxNativeAdViewType],
                adActionButtonConfig = AdActionButtonConfig.toAdActionButtonConfig(args["adActionButtonConfig"] as Map<String, Any>),
                adAttributionConfig = AdAttributionConfig.toAdAttributionConfig(args["adAttributionConfig"] as Map<String, Any>),
                adChoiceConfig = AdChoiceConfig.toAdChoiceConfig(args["adChoiceConfig"] as Map<String, Any>),
                adDescriptionConfig = AdDescriptionConfig.toAdDescriptionConfig(args["adDescriptionConfig"] as Map<String, Any>),
                adIconConfig = AdIconConfig.toAdIconConfig(args["adIconConfig"] as Map<String, Any>),
//                adLayoutConfig = AdLayoutConfig.toAdLayoutConfig(args["adLayoutConfig"] as Map<String, Any>),
                adMediaConfig = AdMediaConfig.toAdMediaConfig(args["adMediaConfig"] as Map<String, Any>),
                adTitleConfig = AdTitleConfig.toAdTitleConfig(args["adTitleConfig"] as Map<String, Any>),
            ).also {
                apdLog("NativeAdOptions: $it")
            }
        }.getOrNull()
    }
}

//D/AppodealFlutterPlugin(31648): toNativeAdOptions: {adChoiceConfig={position=3}, adMediaConfig={margin=0, visible=false, position=0}, adDescriptionConfig={backgroundColor=#00000000, margin=0, fontSize=12, textColor=#FF000000}, adActionButtonConfig={backgroundColor=#00000000, margin=0, fontSize=14, radius=8, textColor=#FF000000}, adTitleConfig={backgroundColor=#00000000, margin=0, fontSize=14, textColor=#FF000000}, adAttributionConfig={backgroundColor=#FFFF6E40, margin=0, fontSize=12, textColor=#FF000000}, adIconConfig={margin=0, visible=false, size=50, position=0}, nativeAdType=3}
//D/AppodealFlutterPlugin(31648): toAdActionButtonConfig: {backgroundColor=#00000000, margin=0, fontSize=14, radius=8, textColor=#FF000000}
//D/AppodealFlutterPlugin(31648): toAdAttributionConfig: {backgroundColor=#FFFF6E40, margin=0, fontSize=12, textColor=#FF000000}
//D/AppodealFlutterPlugin(31648): toAdChoiceConfig: {position=3}
//D/AppodealFlutterPlugin(31648): toAdDescriptionConfig: {backgroundColor=#00000000, margin=0, fontSize=12, textColor=#FF000000}
//D/AppodealFlutterPlugin(31648): toAdIconConfig: {margin=0, visible=false, size=50, position=0}

enum class NativeAdViewType { Custom, ContentStream, AppWall, NewsFeed, Chat }