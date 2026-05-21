# ── Flutter ──────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Google Play Core (deferred components, referenced by Flutter engine) ─
-dontwarn com.google.android.play.core.**

# ── MediaPipe Tasks Vision (face landmarker) ────────────────────────
# Prevents R8 from stripping native MediaPipe + TFLite classes in
# release builds.
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# ── Protobuf (used internally by MediaPipe) ────────────────────────
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# ── Guava / common (used internally by MediaPipe Tasks) ────────────
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**

# ── JNI + native method preservation ───────────────────────────────
-keepclasseswithmembernames class * { native <methods>; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# ── AutoValue / JavaPoet (MediaPipe compile-time deps) ──────────────
# These are annotation-processing classes referenced by AutoValue shaded
# inside the MediaPipe AAR. Not needed at runtime.
-dontwarn javax.lang.model.**
-dontwarn autovalue.shaded.**
-dontwarn com.google.auto.value.**

# ── Camera / CameraX ───────────────────────────────────────────────
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ── Firebase (already included by plugin but safe to keep) ─────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
