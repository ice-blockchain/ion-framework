# --- General Flutter Rules ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.common.annotation.KeepName
-keepnames class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# --- Banuba SDK Rules ---
-keep class com.banuba.sdk.** { *; }
-keep class com.banuba.token.storage.** { *; }
-keep interface com.banuba.sdk.** { *; }
-dontwarn com.banuba.sdk.**

# --- Firebase & Google Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Play Core (Flutter Embedding) ---
# Ignore missing classes from Play Core if deferred components are not used
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# --- BouncyCastle & SSL (Existing Rules) ---
-dontwarn org.bouncycastle.jsse.BCSSLParameters
-dontwarn org.bouncycastle.jsse.BCSSLSocket
-dontwarn org.bouncycastle.jsse.provider.BouncyCastleJsseProvider
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# --- Credentials Manager (Existing Rules) ---
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** {
  *;
}

# --- Prevent shrinking of native methods ---
-keepclasseswithmembernames class * {
    native <methods>;
}
