package com.bakemono.businessmindset.bridge

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * `businessmindset/store` MethodChannel — Android counterpart of the iOS
 * storefront / ATT bridge. App Tracking Transparency does not exist on
 * Android, so [requestATT] / [getATTStatus] return `not_applicable`.
 */
class StoreChannelHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStorefrontCountryCode" -> result.success(detectCountryCode())
            "requestATT", "getATTStatus" -> result.success("not_applicable")
            else -> result.notImplemented()
        }
    }

    /**
     * Best-effort 3-letter ISO country code (matches the format returned by
     * `SKPaymentQueue.default().storefront?.countryCode` on iOS — the Dart
     * side already handles both 2- and 3-letter codes).
     */
    private fun detectCountryCode(): String? {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val sim = tm?.simCountryIso?.takeIf { it.isNotBlank() }
        val network = tm?.networkCountryIso?.takeIf { it.isNotBlank() }
        val locale = Locale.getDefault().country.takeIf { it.isNotBlank() }
        val twoLetter = (sim ?: network ?: locale)?.uppercase(Locale.ROOT) ?: return null
        return ISO_3166_2_TO_3[twoLetter] ?: twoLetter
    }
}

// Subset of the ISO 3166-1 alpha-2 → alpha-3 mapping. Falls back to the
// 2-letter code for anything not listed (the Dart side accepts both).
private val ISO_3166_2_TO_3: Map<String, String> = mapOf(
    "US" to "USA", "CA" to "CAN", "MX" to "MEX",
    "FR" to "FRA", "GB" to "GBR", "UK" to "GBR", "DE" to "DEU", "ES" to "ESP",
    "IT" to "ITA", "PT" to "PRT", "NL" to "NLD", "BE" to "BEL", "CH" to "CHE",
    "AT" to "AUT", "IE" to "IRL", "PL" to "POL", "SE" to "SWE", "NO" to "NOR",
    "DK" to "DNK", "FI" to "FIN", "CZ" to "CZE", "GR" to "GRC", "HU" to "HUN",
    "RO" to "ROU", "BG" to "BGR", "TR" to "TUR", "RU" to "RUS", "UA" to "UKR",
    "MA" to "MAR", "DZ" to "DZA", "TN" to "TUN", "EG" to "EGY", "ZA" to "ZAF",
    "NG" to "NGA", "KE" to "KEN", "AU" to "AUS", "NZ" to "NZL", "JP" to "JPN",
    "KR" to "KOR", "CN" to "CHN", "IN" to "IND", "ID" to "IDN", "PH" to "PHL",
    "VN" to "VNM", "TH" to "THA", "MY" to "MYS", "SG" to "SGP", "AE" to "ARE",
    "SA" to "SAU", "IL" to "ISR", "BR" to "BRA", "AR" to "ARG", "CL" to "CHL",
    "CO" to "COL", "PE" to "PER", "VE" to "VEN",
)
