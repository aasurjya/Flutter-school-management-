# Proguard / R8 rules for the school_management release build.
#
# Keep-rules below are the minimum required for the packages we use that do
# reflection / dynamic loading. R8 will strip everything else aggressively
# under `isMinifyEnabled = true, isShrinkResources = true`.
#
# When you add a new dependency that does reflection (annotations, JSON
# serialization, plugin lookup), add its keep-rule here and document why.

# ─── Flutter ───────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ─── Supabase / GoTrue / Realtime ──────────────────────────────────────────
# Reflective JSON serialization in the Dart layer is fine, but native plugin
# bridges need their classes preserved.
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

# ─── Sentry ────────────────────────────────────────────────────────────────
# Sentry strips its own internals; keeping these prevents Crash-Free metric
# breakage when stack symbolication runs.
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# ─── Isar local database ───────────────────────────────────────────────────
-keep class * extends ** { @isar.annotation.Collection <fields>; }
-keepclasseswithmembers class * {
    @isar.** *;
}

# ─── Razorpay (payment gateway, optional) ──────────────────────────────────
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*

# ─── Kotlin / Coroutines ───────────────────────────────────────────────────
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ─── Annotations / Reflection (general safety net) ─────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# ─── Stack traces ──────────────────────────────────────────────────────────
# Map obfuscated class names back to readable names — `flutter build apk
# --split-debug-info` writes the symbol map; this directive ensures R8 also
# emits a mapping.txt that pairs with it.
-renamesourcefileattribute SourceFile
