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
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.constraintlayout.widget.ConstraintSet
import com.appodeal.ads.nativead.Position
import com.appodeal.appodeal_flutter.apdLog

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

        if (nativeAdOptions.nativeAdViewType == NativeAdViewType.ContentStream) {
            return nativeAdView
        }

        // set ad choices config
        val adChoiceConfig = nativeAdOptions.adChoiceConfig
        val adChoicePosition = adChoiceConfig.position

        //nativeAdView.setAdChoicesPosition(adChoicePosition)
        val nativeCustomContentId = R.id.native_custom_content
        val attributionViewId = R.id.native_custom_ad_attribution
        val adChoicesViewId = R.id.native_custom_ad_choices
        val constraintLayout = nativeAdView.findViewById<ConstraintLayout>(nativeCustomContentId)

        val cardPadding = activity.resources.getDimensionPixelSize(R.dimen.apd_native_custom_card_padding)
        val horizontalSpacing = activity.resources.getDimensionPixelSize(R.dimen.apd_native_custom_content_margin_v)
        val density = activity.resources.displayMetrics.density

        val marginPx = (adChoiceConfig.margin * density).toInt()
        apdLog(
            "AppodealNativeAdView nativeAdViewType: ${nativeAdOptions.nativeAdViewType}, " +
                    "density: $density, cardPadding:$cardPadding, horizontalSpacing:$horizontalSpacing, marginPx:$marginPx"
        )

        val constraintSet = ConstraintSet()
        constraintSet.clone(constraintLayout)

        // Clear existing horizontal constraints to avoid conflicts
        constraintSet.clear(attributionViewId, ConstraintSet.START)
        constraintSet.clear(attributionViewId, ConstraintSet.END)
        constraintSet.clear(adChoicesViewId, ConstraintSet.START)
        constraintSet.clear(adChoicesViewId, ConstraintSet.END)

        // Always top anchored to media wrapper
        constraintSet.connect(attributionViewId, ConstraintSet.TOP, nativeCustomContentId, ConstraintSet.TOP, marginPx)
        constraintSet.connect(adChoicesViewId, ConstraintSet.TOP, nativeCustomContentId, ConstraintSet.TOP, marginPx)

        when (adChoicePosition) {
            Position.START_TOP -> {
                constraintSet.connect(adChoicesViewId, ConstraintSet.START, nativeCustomContentId, ConstraintSet.START, cardPadding)
                constraintSet.connect(attributionViewId, ConstraintSet.START, adChoicesViewId, ConstraintSet.END, horizontalSpacing)
            }

            Position.END_TOP -> {
                constraintSet.connect(attributionViewId, ConstraintSet.END, nativeCustomContentId, ConstraintSet.END, cardPadding)
                constraintSet.connect(adChoicesViewId, ConstraintSet.END, attributionViewId, ConstraintSet.START, horizontalSpacing)
            }

            else -> {
                constraintSet.connect(attributionViewId, ConstraintSet.END, nativeCustomContentId, ConstraintSet.END, cardPadding)
                constraintSet.connect(adChoicesViewId, ConstraintSet.END, attributionViewId, ConstraintSet.START, horizontalSpacing)
            }
        }
        constraintSet.applyTo(constraintLayout)

        // set ad attribution config
//        val adAttributionBackgroundColor = nativeAdOptions.adAttributionConfig.backgroundColor
//        nativeAdView.setAdAttributionBackground(adAttributionBackgroundColor)
//        val adAttributionTextColor = nativeAdOptions.adAttributionConfig.textColor
//        nativeAdView.setAdAttributionTextColor(adAttributionTextColor)
//
//        // set ad title config
//        val adTitleConfigFontSize = nativeAdOptions.adTitleConfig.fontSize.toFloat()
//        (nativeAdView.titleView as? TextView)?.textSize = adTitleConfigFontSize
//
//        // set ad description config
//        val adDescriptionFontSize = nativeAdOptions.adDescriptionConfig.fontSize.toFloat()
//        (nativeAdView.descriptionView as? TextView)?.apply {
//            textSize = adDescriptionFontSize
//            setTextColor(nativeAdOptions.adDescriptionConfig.textColor)
//        }
//
//        // set ad action button config
//        val adActionButtonFontSize = nativeAdOptions.adActionButtonConfig.fontSize.toFloat()
//        (nativeAdView.callToActionView as? Button)?.apply {
//            textSize = adActionButtonFontSize
//            setBackgroundColor(nativeAdOptions.adActionButtonConfig.backgroundColor)
//            setBackgroundResource(R.drawable.apd_native_cta_round_outline)
//            setTextColor(nativeAdOptions.adActionButtonConfig.textColor)
//        }
//
//        val density = context.resources.displayMetrics.density
//        val iconSize = (nativeAdOptions.adIconConfig.size * density).toInt()
//
//        (nativeAdView.iconView)?.layoutParams =
//            RelativeLayout.LayoutParams(iconSize, iconSize)

        return nativeAdView
    }
}