# Flutter engine and plugin wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive database models and annotations if reflection is used
-keep class com.hivedb.** { *; }
-keep class * extends io.hive.** { *; }
-keep interface io.hive.** { *; }
