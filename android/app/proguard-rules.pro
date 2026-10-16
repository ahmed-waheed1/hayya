# flutter_local_notifications stores scheduled notifications as Gson JSON
# and reads them back after a reboot or an app update. Keep the model
# classes' names and fields so JSON written by one release still parses in
# the next (R8 renames them differently in each build).
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
