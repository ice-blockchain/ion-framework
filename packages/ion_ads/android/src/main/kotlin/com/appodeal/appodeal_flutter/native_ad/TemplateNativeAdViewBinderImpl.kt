package com.appodeal.appodeal_flutter.native_ad

import android.app.Activity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import com.appodeal.ads.nativead.NativeAdView
import com.appodeal.ads.nativead.NativeAdViewNewsFeed
import com.appodeal.appodeal_flutter.R
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.constraintlayout.widget.ConstraintSet
import com.appodeal.ads.nativead.NativeMediaView
import com.appodeal.ads.nativead.Position
import com.appodeal.appodeal_flutter.apdLog

internal val templateNativeAdViewBinder by lazy { TemplateNativeAdViewBinderImpl() }

internal class TemplateNativeAdViewBinderImpl : NativeAdViewBinder {

    override fun bind(activity: Activity, nativeAdOptions: NativeAdOptions): NativeAdView {
        val context = activity.applicationContext
        val layoutInflater = activity.layoutInflater
        // Create the NativeAdView
        val nativeAdView = when (nativeAdOptions.nativeAdViewType) {
            NativeAdViewType.ContentStream -> layoutInflater.inflate(
                R.layout.apd_native_ad_view_custom,
                null
            ) as NativeAdView
            NativeAdViewType.AppWall -> layoutInflater.inflate(
                R.layout.apd_native_ad_view_full,
                null
            ) as NativeAdView
            NativeAdViewType.Chat -> layoutInflater.inflate(
                R.layout.apd_native_ad_view_chat_list,
                null
            ) as NativeAdView
            NativeAdViewType.Article -> layoutInflater.inflate(
                R.layout.apd_native_ad_view_article,
                null
            ) as NativeAdView
            NativeAdViewType.NewsFeed -> NativeAdViewNewsFeed(context)
            else -> throw IllegalArgumentException("Unknown NativeAdViewType: ${nativeAdOptions.nativeAdViewType}")
        }

        if (nativeAdOptions.nativeAdViewType == NativeAdViewType.Chat || nativeAdOptions.nativeAdViewType == NativeAdViewType.Article) {
            return nativeAdView
        }

        val constraintSet = ConstraintSet()
        val nativeCustomContentId = R.id.native_custom_content
        val constraintLayout = nativeAdView.findViewById<ConstraintLayout>(nativeCustomContentId)
        constraintSet.clone(constraintLayout)

        val adActionButtonConfig = nativeAdOptions.adActionButtonConfig
        val adActionPosIndex = adActionButtonConfig.position

        val cardPadding = activity.resources.getDimensionPixelSize(R.dimen.apd_native_custom_card_padding)
        val horizontalSpacing = activity.resources.getDimensionPixelSize(R.dimen.apd_native_custom_content_margin_v)
        val density = activity.resources.displayMetrics.density

        apdLog(
            "AppodealNativeAdView nativeAdViewType: ${nativeAdOptions.nativeAdViewType}, " +
                    "density: $density, cardPadding:$cardPadding, horizontalSpacing:$horizontalSpacing, " +
                    "adActionPosIndex:$adActionPosIndex"
        )

        if (nativeAdOptions.nativeAdViewType == NativeAdViewType.AppWall) {
            // set ad choices config for AppWall
            val adChoiceConfig = nativeAdOptions.adChoiceConfig
            val adChoicePosition = adChoiceConfig.position

            val attributionViewId = R.id.native_custom_ad_attribution
            val adChoicesViewId = R.id.native_custom_ad_choices

            val marginPx = (adChoiceConfig.margin * density).toInt()

            // Clear existing horizontal constraints to avoid conflicts
            constraintSet.clear(attributionViewId, ConstraintSet.START)
            constraintSet.clear(attributionViewId, ConstraintSet.END)
            constraintSet.clear(adChoicesViewId, ConstraintSet.START)
            constraintSet.clear(adChoicesViewId, ConstraintSet.END)

            // Always top anchored to media wrapper
            when (adChoicePosition) {
                Position.START_TOP -> {
                    constraintSet.connect(adChoicesViewId, ConstraintSet.START, nativeCustomContentId, ConstraintSet.START, cardPadding)
                    constraintSet.connect(attributionViewId, ConstraintSet.START, adChoicesViewId, ConstraintSet.END, horizontalSpacing)
                    constraintSet.connect(
                        attributionViewId,
                        ConstraintSet.TOP,
                        nativeCustomContentId,
                        ConstraintSet.TOP,
                        marginPx + cardPadding + horizontalSpacing
                    )
                    constraintSet.connect(
                        adChoicesViewId,
                        ConstraintSet.TOP,
                        nativeCustomContentId,
                        ConstraintSet.TOP,
                        marginPx + cardPadding + horizontalSpacing
                    )
                }

                Position.END_TOP -> {
                    constraintSet.connect(attributionViewId, ConstraintSet.END, nativeCustomContentId, ConstraintSet.END, cardPadding)
                    constraintSet.connect(adChoicesViewId, ConstraintSet.END, attributionViewId, ConstraintSet.START, horizontalSpacing)
                    constraintSet.connect(attributionViewId, ConstraintSet.TOP, nativeCustomContentId, ConstraintSet.TOP, marginPx)
                    constraintSet.connect(adChoicesViewId, ConstraintSet.TOP, nativeCustomContentId, ConstraintSet.TOP, marginPx)
                }

                else -> {
                    constraintSet.connect(attributionViewId, ConstraintSet.END, nativeCustomContentId, ConstraintSet.END, cardPadding)
                    constraintSet.connect(adChoicesViewId, ConstraintSet.END, attributionViewId, ConstraintSet.START, horizontalSpacing)
                }
            }
        }

        // set adActionButtonConfig config
        val callToActionViewId = R.id.native_custom_cta
        val nativeMediaViewId = R.id.native_media_wrapper

        nativeAdView.mediaView?.setOnHierarchyChangeListener(object : ViewGroup.OnHierarchyChangeListener {
            override fun onChildViewAdded(parent: View?, child: View?) {
                child?.let { mediaChild ->
                    // Force the internal view (Video/Image) to fill the parent
                    val params = mediaChild.layoutParams as FrameLayout.LayoutParams
                    params.width = FrameLayout.LayoutParams.MATCH_PARENT
                    params.height = FrameLayout.LayoutParams.MATCH_PARENT
                    mediaChild.layoutParams = params
                }
            }

            override fun onChildViewRemoved(parent: View?, child: View?) {}
        })


        // Clear existing horizontal constraints to avoid conflicts
        constraintSet.clear(callToActionViewId, ConstraintSet.START)
        constraintSet.clear(callToActionViewId, ConstraintSet.END)
        constraintSet.clear(callToActionViewId, ConstraintSet.TOP)
        constraintSet.clear(callToActionViewId, ConstraintSet.BOTTOM)

        constraintSet.clear(nativeMediaViewId, ConstraintSet.BOTTOM)

        // Always end anchored to media wrapper
        constraintSet.connect(callToActionViewId, ConstraintSet.END, nativeCustomContentId, ConstraintSet.END, 0)

        when (adActionPosIndex) {
            Position.START_TOP -> {
                constraintSet.connect(callToActionViewId, ConstraintSet.TOP, nativeCustomContentId, ConstraintSet.TOP, 0)
                constraintSet.connect(nativeMediaViewId, ConstraintSet.BOTTOM, nativeCustomContentId, ConstraintSet.BOTTOM, 0)
                constraintSet.setDimensionRatio(nativeMediaViewId, "H,10:16")
            }

            Position.START_BOTTOM -> {
                constraintSet.connect(callToActionViewId, ConstraintSet.BOTTOM, nativeCustomContentId, ConstraintSet.BOTTOM, 0)
                constraintSet.connect(callToActionViewId, ConstraintSet.START, nativeCustomContentId, ConstraintSet.START, 0)
                constraintSet.connect(nativeMediaViewId, ConstraintSet.BOTTOM, callToActionViewId, ConstraintSet.TOP, 0)
                constraintSet.setDimensionRatio(nativeMediaViewId, "H,9:16")

                constraintSet.clear(R.id.native_custom_title, ConstraintSet.END)
                constraintSet.clear(R.id.native_custom_description, ConstraintSet.END)
                constraintSet.connect(R.id.native_custom_title, ConstraintSet.END, nativeCustomContentId, ConstraintSet.END, 0)
            }

            else -> {
                constraintSet.connect(callToActionViewId, ConstraintSet.TOP, nativeCustomContentId, ConstraintSet.TOP, 0)
            }
        }
        constraintSet.applyTo(constraintLayout)


        return nativeAdView
    }
}