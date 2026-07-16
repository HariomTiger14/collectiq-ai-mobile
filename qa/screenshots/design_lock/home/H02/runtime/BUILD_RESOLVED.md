# Runtime Build Resolved

Date: 2026-07-16

The Flutter wrapper startup blocker repeated for:

```text
C:\Users\hario\Desktop\flutter\bin\flutter.bat build apk --debug --flavor local -v
```

The wrapper emitted no output, spawned no Dart or Gradle child process, and was stopped after the bounded wait.

The accepted repository fallback succeeded:

```text
cd android
& { $env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'; .\gradlew.bat assembleLocalDebug }
```

Result:

```text
BUILD SUCCESSFUL in 1m 4s
```

APK:

```text
build\app\outputs\flutter-apk\app-local-debug.apk
191,822,483 bytes
2026-07-16 16:11:09 +10:00
```

Install:

```text
adb -s RZ8R213M8ZL install -r build\app\outputs\flutter-apk\app-local-debug.apk
Success
```

Launch:

```text
adb -s RZ8R213M8ZL shell am start -n com.collectiq.ai.local/com.collectiq.ai.MainActivity
```

Foreground activity confirmed:

```text
com.collectiq.ai.local/com.collectiq.ai.MainActivity
```
