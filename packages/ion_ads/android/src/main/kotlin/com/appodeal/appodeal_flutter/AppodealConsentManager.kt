package com.appodeal.appodeal_flutter

import com.appodeal.ads.Appodeal
import com.appodeal.consent.ConsentForm
import com.appodeal.consent.ConsentInfoUpdateCallback
import com.appodeal.consent.ConsentManager
import com.appodeal.consent.ConsentManagerError
import com.appodeal.consent.ConsentUpdateRequestParameters
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AppodealConsentManager(
    private val flutterPlugin: IonAppodealBaseFlutterPlugin,
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {

    val adChannel: MethodChannel = MethodChannel(
        flutterPluginBinding.binaryMessenger,
        "appodeal_flutter/consent_manager"
    ).apply { setMethodCallHandler(this@AppodealConsentManager) }

    private var consentForm: ConsentForm? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> load(call, result)
            "show" -> show(call, result)
            "loadAndShowIfRequired" -> loadAndShowIfRequired(call, result)
            "revoke" -> revoke(call, result)
            else -> result.notImplemented()
        }
    }

    private fun load(call: MethodCall, result: MethodChannel.Result) {
        val activity = flutterPlugin.activity
        val args = call.arguments as Map<*, *>
        val appKey = args["appKey"] as String
        val tagForUnderAgeOfConsent = args["tagForUnderAgeOfConsent"] as Boolean

        val parameters = ConsentUpdateRequestParameters(
            activity = activity,
            key = appKey,
            tagForUnderAgeOfConsent = tagForUnderAgeOfConsent,
            sdk = "appodeal",
            sdkVersion = Appodeal.getVersion(),
        )

        val infoUpdateCallback = object : ConsentInfoUpdateCallback {
            override fun onFailed(error: ConsentManagerError) {
                val invokeArgs = mapOf("error" to error.localizedMessage)
                adChannel.invokeMethod("onConsentFormLoadFailure", invokeArgs)
            }

            override fun onUpdated() {
                ConsentManager.load(
                    context = activity,
                    successListener = { consentForm ->
                        this@AppodealConsentManager.consentForm = consentForm
                        val status = ConsentManager.status
                        val invokeArgs = mapOf("status" to status.ordinal)
                        adChannel.invokeMethod("onConsentFormLoadSuccess", invokeArgs)
                    },
                    failureListener = { error ->
                        val invokeArgs = mapOf("error" to error.localizedMessage)
                        adChannel.invokeMethod("onConsentFormLoadFailure", invokeArgs)
                    }
                )
            }
        }
        ConsentManager.requestConsentInfoUpdate(parameters, infoUpdateCallback)
        result.success(null)
    }

    private fun show(call: MethodCall, result: MethodChannel.Result) {
        val consentForm = this.consentForm
        if (consentForm == null) {
            val invokeArgs = mapOf("error" to "Consent form is not loaded")
            adChannel.invokeMethod("onConsentFormDismissed", invokeArgs)
        } else {
            val activity = flutterPlugin.activity
            consentForm.show(activity) { error ->
                this.consentForm = null
                val invokeArgs = error?.let { mapOf("error" to error.localizedMessage) }
                adChannel.invokeMethod("onConsentFormDismissed", invokeArgs)
            }
        }
        result.success(null)
    }

    private fun loadAndShowIfRequired(call: MethodCall, result: MethodChannel.Result) {
        val activity = flutterPlugin.activity
        val args = call.arguments as Map<*, *>
        val appKey = args["appKey"] as String
        val tagForUnderAgeOfConsent = args["tagForUnderAgeOfConsent"] as Boolean

        val parameters = ConsentUpdateRequestParameters(
            activity = activity,
            key = appKey,
            tagForUnderAgeOfConsent = tagForUnderAgeOfConsent,
            sdk = "appodeal",
            sdkVersion = Appodeal.getVersion(),
        )

        val infoUpdateCallback = object : ConsentInfoUpdateCallback {
            override fun onFailed(error: ConsentManagerError) {
                val invokeArgs = mapOf("error" to error.localizedMessage)
                adChannel.invokeMethod("onConsentFormLoadFailure", invokeArgs)
            }

            override fun onUpdated() {
                ConsentManager.loadAndShowConsentFormIfRequired(activity) { error ->
                    val invokeArgs = error?.let { mapOf("error" to error.localizedMessage) }
                    adChannel.invokeMethod("onConsentFormDismissed", invokeArgs)
                }
            }
        }
        ConsentManager.requestConsentInfoUpdate(parameters, infoUpdateCallback)
        result.success(null)
    }

    private fun revoke(call: MethodCall, result: MethodChannel.Result) {
        ConsentManager.revoke(flutterPlugin.context)
        result.success(null)
    }
}
