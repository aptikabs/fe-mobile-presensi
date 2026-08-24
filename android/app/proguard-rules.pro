# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class plugins.flutter.io.**  { *; }

# Firebase & Play Core
-dontwarn com.google.android.play.core.**
-dontwarn com.google.firebase.**

# Security Obfuscation Rules
-allowaccessmodification
-repackageclasses 'o'

# Renaming & Anti-Reconnaissance Attributes
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,Exceptions,InnerClasses,Signature

# Strip debug log calls in production Android R8 build
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Do not keep MainActivity methods except FlutterActivity overrides
-keepclassmembers class * extends io.flutter.embedding.android.FlutterActivity {
    public void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine);
}

# Preserve Native C++ JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}



