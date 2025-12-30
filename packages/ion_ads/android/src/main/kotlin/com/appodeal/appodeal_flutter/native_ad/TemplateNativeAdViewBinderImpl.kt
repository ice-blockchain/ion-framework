package com.appodeal.appodeal_flutter.native_ad

import android.app.Activity
import android.widget.Button
import android.widget.RelativeLayout
import android.widget.TextView
import com.appodeal.ads.nativead.NativeAdView
import com.appodeal.ads.nativead.NativeAdViewAppWall
import com.appodeal.ads.nativead.NativeAdViewContentStream
import com.appodeal.ads.nativead.NativeAdViewNewsFeed
import com.appodeal.appodeal_flutter.R

internal val templateNativeAdViewBinder by lazy { TemplateNativeAdViewBinderImpl() }

internal class TemplateNativeAdViewBinderImpl : NativeAdViewBinder {

    override fun bind(activity: Activity, nativeAdOptions: NativeAdOptions): NativeAdView {
        val context = activity.applicationContext
        val layoutInflater = activity.layoutInflater
        // Create the NativeAdView
        val nativeAdView = when (val nativeAdViewType = nativeAdOptions.nativeAdViewType) {
            NativeAdViewType.ContentStream -> layoutInflater.inflate(
                R.layout.apd_native_ad_view_custom,
                null
            ) as NativeAdView // NativeAdViewContentStream(context)
            NativeAdViewType.AppWall -> layoutInflater.inflate(
                R.layout.apd_native_ad_view_full,
                null
            ) as NativeAdView // NativeAdViewAppWall(context)
            NativeAdViewType.NewsFeed -> NativeAdViewNewsFeed(context)
            else -> throw IllegalArgumentException("Unknown NativeAdViewType: $nativeAdViewType")
        }

        if (nativeAdOptions.nativeAdViewType == NativeAdViewType.ContentStream ||
            nativeAdOptions.nativeAdViewType == NativeAdViewType.AppWall
        ) {
            return nativeAdView
        }


        // set ad choices config
        val adChoicePosition = nativeAdOptions.adChoiceConfig.position
        nativeAdView.setAdChoicesPosition(adChoicePosition)

        // set ad attribution config
        val adAttributionBackgroundColor = nativeAdOptions.adAttributionConfig.backgroundColor
        nativeAdView.setAdAttributionBackground(adAttributionBackgroundColor)
        val adAttributionTextColor = nativeAdOptions.adAttributionConfig.textColor
        nativeAdView.setAdAttributionTextColor(adAttributionTextColor)

        // set ad title config
        val adTitleConfigFontSize = nativeAdOptions.adTitleConfig.fontSize.toFloat()
        (nativeAdView.titleView as? TextView)?.textSize = adTitleConfigFontSize

        // set ad description config
        val adDescriptionFontSize = nativeAdOptions.adDescriptionConfig.fontSize.toFloat()
        (nativeAdView.descriptionView as? TextView)?.apply {
            textSize = adDescriptionFontSize
            setTextColor(nativeAdOptions.adDescriptionConfig.textColor)
        }

        // set ad action button config
        val adActionButtonFontSize = nativeAdOptions.adActionButtonConfig.fontSize.toFloat()
        (nativeAdView.callToActionView as? Button)?.apply {
            textSize = adActionButtonFontSize
            setBackgroundColor(nativeAdOptions.adActionButtonConfig.backgroundColor)
            setBackgroundResource(R.drawable.apd_native_cta_round_outline)
            setTextColor(nativeAdOptions.adActionButtonConfig.textColor)
        }

        val density = context.resources.displayMetrics.density
        val iconSize = (nativeAdOptions.adIconConfig.size * density).toInt()

        (nativeAdView.iconView)?.layoutParams =
            RelativeLayout.LayoutParams(iconSize, iconSize)

        return nativeAdView
    }
}