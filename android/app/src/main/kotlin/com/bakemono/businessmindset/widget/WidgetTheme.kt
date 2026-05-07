package com.bakemono.businessmindset.widget

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import com.bakemono.businessmindset.bridge.WidgetPrefs
import org.json.JSONArray

/**
 * Widget theme descriptor — Kotlin mirror of the Swift `ThemeData` struct
 * in `ios/BusinessMindsetWidget/ThemeData.swift`. Only the fields the
 * widget actually renders are kept (background colors/gradient, image
 * reference, foreground color). The canonical source of truth lives in
 * `lib/theme/themedatas.dart`; whenever a theme is added or tweaked
 * there, the iOS list and this list must be updated together.
 *
 * Color values are stored as standard Android ARGB `Int` (via
 * `0xFFRRGGBB.toInt()` to fit into the signed 32-bit `Int`).
 */
internal data class WidgetTheme(
    val color1: Int,
    val color2: Int,
    val color3: Int,
    val nbrColor: Int,
    val fontColor: Int,
    val isImage: Boolean,
    val imageName: String?,
)

// ---------------------------------------------------------------------
// Built-in theme list. Must stay index-aligned with:
//   - lib/theme/themedatas.dart  (allAppThemes)
//   - ios/BusinessMindsetWidget/ThemeData.swift (allAppThemes)
// ---------------------------------------------------------------------
internal val allAppThemes: List<WidgetTheme> = listOf(
    // 0 blackTheme
    WidgetTheme(0xFF1f1f1f.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFFffffff.toInt(), false, null),
    // 1 greenTheme
    WidgetTheme(0xFFa2f1a7.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 2 lightPinkTheme
    WidgetTheme(0xFFf8d4c6.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 3 pinkTheme
    WidgetTheme(0xFFfd608e.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 4 lightYellowTheme
    WidgetTheme(0xFFfef6bb.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 5 lightPurpleTheme
    WidgetTheme(0xFFf6d8fc.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 6 lightBlueTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 7 skinTheme
    WidgetTheme(0xFFf9d1a5.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 8 littlePurpleTheme
    WidgetTheme(0xFF4865fd.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFFffffff.toInt(), false, null),
    // 9 littleSkinTheme
    WidgetTheme(0xFFfbf4ed.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 10 littleGreenTheme
    WidgetTheme(0xFF86f5cc.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 11 blueGreenTheme
    WidgetTheme(0xFFabbde0.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 12 veryLightBlueTheme
    WidgetTheme(0xFF10eaff.toInt(), 0xff29918a.toInt(), 0xffe09571.toInt(), 1, 0xFF000000.toInt(), false, null),
    // 13 greenBlueTheme
    WidgetTheme(0xFF72fa93.toInt(), 0xff9ac1f0.toInt(), 0xffe09571.toInt(), 2, 0xFF000000.toInt(), false, null),
    // 14 redBlueTheme
    WidgetTheme(0xFFf9858b.toInt(), 0xff9ac1f0.toInt(), 0xffe09571.toInt(), 2, 0xFF000000.toInt(), false, null),
    // 15 blueBlueBlueTheme
    WidgetTheme(0xFFb5e5e7.toInt(), 0xff7dd1df.toInt(), 0xff1e95d4.toInt(), 3, 0xFFffffff.toInt(), false, null),
    // 16 yellowBlueTheme
    WidgetTheme(0xFFffcf43.toInt(), 0xff5ce0d8.toInt(), 0xff1e95d4.toInt(), 2, 0xFF000000.toInt(), false, null),
    // 17 whitePurpleTheme
    WidgetTheme(0xFFffffff.toInt(), 0xff903b6b.toInt(), 0xff1e95d4.toInt(), 2, 0xFFffffff.toInt(), false, null),
    // 18 purplePinkTheme
    WidgetTheme(0xFFfcc5f9.toInt(), 0xfff38283.toInt(), 0xff1e95d4.toInt(), 2, 0xFF000000.toInt(), false, null),
    // 19 skinGreenTheme
    WidgetTheme(0xFFf8d4c6.toInt(), 0xffa0efa5.toInt(), 0xff1e95d4.toInt(), 2, 0xFF000000.toInt(), false, null),
    // 20 skinRedTheme
    WidgetTheme(0xFFf8d4c6.toInt(), 0xfffd608e.toInt(), 0xffd4305f.toInt(), 3, 0xFFffffff.toInt(), false, null),
    // 21 lightBlueWhiteTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xff16dcdb.toInt(), 0xff1edec7.toInt(), 3, 0xFF000000.toInt(), false, null),
    // 22 pinkBlueTheme
    WidgetTheme(0xFFf6d8fc.toInt(), 0xff0fdbee.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), false, null),
    // 23 blueRedTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), false, null),
    // 24 skylineTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "1_skyline"),
    // 25 skyline2Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "2_skyline"),
    // 26 landscapeTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "3_landscape"),
    // 27 skymountainTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "4_skymountain"),
    // 28 moonTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "5_moon"),
    // 29 beachTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "6_beach"),
    // 30 ferrariTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "7_ferrari"),
    // 31 mountainTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "8_mountain"),
    // 32 snowmoutainTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFFFFF.toInt(), true, "9_snowmoutain"),
    // 33 landscape10Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "10_landscape"),
    // 34 eiffelTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFFFFF.toInt(), true, "11_eiffel"),
    // 35 dubaiTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFFFFF.toInt(), true, "12_dubai"),
    // 36 forestTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFFFFF.toInt(), true, "13_forest"),
    // 37 lagoonTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "14_lagoon"),
    // 38 beach15Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "15_beach"),
    // 39 riceTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFF9EE.toInt(), true, "16_rice"),
    // 40 boatTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFF9EE.toInt(), true, "17_boat"),
    // 41 sandTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "18_sand"),
    // 42 sky20Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "20_sky"),
    // 43 seaTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "21_sea"),
    // 44 birdsTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "22_birds"),
    // 45 bridgeTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "23_bridge"),
    // 46 marbreTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "24_marbre"),
    // 47 blackmarbreTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "25_blackmarbre"),
    // 48 city26Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "26_city"),
    // 49 lights27Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "27_lights"),
    // 50 dunesTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "28_dunes"),
    // 51 redmoutainTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFF9EE.toInt(), true, "29_redmoutain"),
    // 52 water30Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "30_water"),
    // 53 city31Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFF9EE.toInt(), true, "31_city"),
    // 54 sky32Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "32_sky"),
    // 55 lights33Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "33_lights"),
    // 56 mongolfiereTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFFFFFFF.toInt(), true, "34_mongolfiere"),
    // 57 sky35Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "35_sky"),
    // 58 planeTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "36_plane"),
    // 59 cloudsTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "37_clouds"),
    // 60 flowersTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "38_flowers"),
    // 61 fungusTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "39_fungus"),
    // 62 water40Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "40_water"),
    // 63 forest41Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "41_forest"),
    // 64 sky42Theme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "42_sky"),
    // 65 sakuraTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFF000000.toInt(), true, "43_sakura"),
    // 66 milkywayTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "44_milkyway"),
    // 67 auroreTheme
    WidgetTheme(0xFF0fdbee.toInt(), 0xffe6126d.toInt(), 0xffd4305f.toInt(), 2, 0xFFffffff.toInt(), true, "45_aurore"),
)

/**
 * Picks the widget theme index with the same precedence as the iOS
 * `getWidgetThemeIndex` helper:
 *   - once the widget has been configured → `widgetThemeIndex`,
 *   - otherwise fall back on the app's own `themeIndex`
 *     (so the widget placeholder uses the live app theme), and finally
 *     `widgetThemeIndex` or `0`.
 */
internal fun resolveWidgetThemeIndex(prefs: SharedPreferences, configured: Boolean): Int {
    return if (configured) {
        prefs.getInt(WidgetPrefs.Keys.WIDGET_THEME_INDEX, 0)
    } else {
        when {
            prefs.contains(WidgetPrefs.Keys.THEME_INDEX_APP) ->
                prefs.getInt(WidgetPrefs.Keys.THEME_INDEX_APP, 0)
            prefs.contains(WidgetPrefs.Keys.WIDGET_THEME_INDEX) ->
                prefs.getInt(WidgetPrefs.Keys.WIDGET_THEME_INDEX, 0)
            else -> 0
        }
    }
}

/**
 * Resolves the currently active widget theme. Custom themes (created
 * by the user in the app) are stored by Dart as a JSON array under
 * `themeCustomDatasMap`; built-in themes come from [allAppThemes].
 */
internal fun resolveWidgetTheme(prefs: SharedPreferences, configured: Boolean): WidgetTheme {
    val index = resolveWidgetThemeIndex(prefs, configured)
    val isCustom = prefs.getBoolean(WidgetPrefs.Keys.WIDGET_IS_CUSTOM_THEME, false)

    if (isCustom) {
        val customs = parseCustomThemes(prefs.getString(WidgetPrefs.Keys.THEME_CUSTOM_DATAS, null))
        if (index in customs.indices) return customs[index]
    }

    val safe = index.coerceIn(0, allAppThemes.size - 1)
    return allAppThemes[safe]
}

private fun parseCustomThemes(json: String?): List<WidgetTheme> {
    if (json.isNullOrBlank()) return emptyList()
    return try {
        val array = JSONArray(json)
        (0 until array.length()).mapNotNull { i ->
            val obj = array.optJSONObject(i) ?: return@mapNotNull null
            WidgetTheme(
                color1 = (obj.opt("color1") as? Number)?.toLong()?.toInt() ?: 0xFF1f1f1f.toInt(),
                color2 = (obj.opt("color2") as? Number)?.toLong()?.toInt() ?: 0xFF1f1f1f.toInt(),
                color3 = (obj.opt("color3") as? Number)?.toLong()?.toInt() ?: 0xFF1f1f1f.toInt(),
                nbrColor = obj.optInt("nbrcolor", 1),
                fontColor = (obj.opt("fontcolor") as? Number)?.toLong()?.toInt() ?: 0xFFFFFFFF.toInt(),
                isImage = obj.optBoolean("isImage", false),
                imageName = obj.optString("imageName", "").takeIf { it.isNotBlank() },
            )
        }
    } catch (_: Throwable) {
        emptyList()
    }
}

// ---------------------------------------------------------------------
// Background rendering
// ---------------------------------------------------------------------

/**
 * Renders the theme background as a Bitmap suitable for consumption by
 * Glance's `ImageProvider(Bitmap)`. We always go through a bitmap (vs.
 * `.background(Color)` or a static XML gradient) so the same code path
 * handles solid colors, 2-stop and 3-stop gradients, matching the
 * `ThemeBackgroundView` / `WidgetBackgroundModifier` logic on iOS.
 *
 * Images are handled separately (they are rendered via a drawable
 * resource, see [themeBackgroundDrawableRes]).
 */
internal fun renderThemeGradientBitmap(
    theme: WidgetTheme,
    widthPx: Int,
    heightPx: Int,
): Bitmap {
    val w = widthPx.coerceAtLeast(1)
    val h = heightPx.coerceAtLeast(1)
    val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    when (theme.nbrColor) {
        1 -> {
            paint.color = theme.color1
            canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), paint)
        }
        2 -> {
            paint.shader = LinearGradient(
                0f, 0f, 0f, h.toFloat(),
                intArrayOf(theme.color1, theme.color2),
                null,
                Shader.TileMode.CLAMP,
            )
            canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), paint)
        }
        else -> {
            paint.shader = LinearGradient(
                0f, 0f, 0f, h.toFloat(),
                intArrayOf(theme.color1, theme.color2, theme.color3),
                null,
                Shader.TileMode.CLAMP,
            )
            canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), paint)
        }
    }
    return bitmap
}

/**
 * Resolves the `@drawable/bg_<imageName>` resource id for an image
 * theme, or `0` if the image isn't bundled with the app. Background
 * images live in `res/drawable-nodpi/bg_*.png` (mirrors the iOS
 * `BusinessMindsetWidget/Assets.xcassets/<name>.imageset/`).
 */
internal fun themeBackgroundDrawableRes(context: Context, theme: WidgetTheme): Int {
    val imageName = theme.imageName ?: return 0
    if (imageName.isBlank()) return 0
    val resName = "bg_$imageName"
    return context.resources.getIdentifier(resName, "drawable", context.packageName)
}
