# Flutter's own engine/plugin classes are already kept by the Flutter Gradle
# plugin's default rules (proguard-android-optimize.txt covers the Android
# framework side). These add keep rules for libraries in this app that are
# known to break under R8 without them.

# Firebase / Firestore — model classes read via reflection.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Stripe SDK
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Google Play Core (deferred components / Play Store install referrer) —
# referenced by the Flutter engine's split-install shim even when unused.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# flutter_local_notifications — receiver/service classes invoked by the OS,
# not from Dart, so R8 can't see the real call sites.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Google Sign-In / Maps — model classes deserialized via reflection.
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.maps.** { *; }
