# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in D:\sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/episode/developing/tools/proguard.html

-keepclassmembers class fqcn.of.javascript.interface.for.webview {
   public *;
}
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep class android.support.v8.** { *; }
-dontwarn android.support.v8.**
-keep class com.fulldome.mahabharata.model.** { *; }
-dontwarn com.fulldome.mahabharata.model.**
-keep class com.ironwaterstudio.server.data.** { *; }
-dontwarn com.ironwaterstudio.server.data.**
-keep class com.ironwaterstudio.server.http.** { *; }
-dontwarn com.ironwaterstudio.server.http.**
-keep class com.ironwaterstudio.billing.** { *; }
-dontwarn com.ironwaterstudio.billing.**
