package com.appodeal.appodeal_flutter.native_ad

import android.graphics.Color

internal fun parseColor(hexColorValue: String?): Int? {
    return if (hexColorValue == null) null
    else Color.parseColor(hexColorValue)
}