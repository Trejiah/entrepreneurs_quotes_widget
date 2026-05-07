# =====================================================================
# Business Mindset — ProGuard / R8 rules.
# Reference: https://developer.android.com/build/shrink-code
# These rules supplement the default `proguard-android-optimize.txt`.
# =====================================================================

# --- Flutter / Dart ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase / Crashlytics / Remote Config ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
# Keep Crashlytics line numbers in stack traces.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# --- RevenueCat (purchases_flutter wraps the native SDK) ---
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# --- Google Play Billing ---
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# --- Mixpanel ---
-keep class com.mixpanel.android.** { *; }
-dontwarn com.mixpanel.android.**

# --- TikTok Events SDK ---
-keep class com.tiktok.** { *; }
-dontwarn com.tiktok.**

# --- Google Sign-In / Auth ---
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# --- Adjust / Install Referrer ---
-keep class com.android.installreferrer.** { *; }
-dontwarn com.android.installreferrer.**

# --- Our own native bridge & widget receivers (referenced from the
#     manifest by class name, and by Flutter/runtime callbacks). ---
-keep class com.bakemono.businessmindset.MainActivity { *; }
-keep class com.bakemono.businessmindset.bridge.** { *; }
-keep class com.bakemono.businessmindset.widget.** { *; }

# --- Kotlin / Coroutines / Serialization ---
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault,InnerClasses,EnclosingMethod
-keepclassmembers class kotlinx.serialization.** { *; }
-keep class kotlin.Metadata { *; }

# --- Generic: keep enums / parcelables / native methods ---
-keepclassmembers enum * { *; }
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclasseswithmembernames class * {
    native <methods>;
}

# Suppress warnings for missing optional classes pulled in by transitive deps.
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.**
