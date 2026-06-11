# Keep generic type signatures to preserve metadata
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod

# Keep the notification plugin classes intact
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Prevent Gson serialization type erasure
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**