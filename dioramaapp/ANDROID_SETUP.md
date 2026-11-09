# Android setup and run record (2026-11-03)

## Installed tools

- Flutter 3.47.9 stable / Dart 3.13.7 in `C:/Users/josep/development/flutter`.
  Official archive checksum verified; Flutter analytics disabled.
- Flutter bin directory added to the Windows user PATH. Open a new terminal to
  pick up the change; existing terminals can use the full flutter.bat path.
- Android SDK: `C:/Users/josep/AppData/Local/Android/Sdk`.
- Java: Android Studio's bundled JBR 21 at `C:/Program Files/Android/Android Studio/jbr`.
- Android command-line tools 23 (latest) and compatible legacy SDK manager 19.0.
  The latest sdkmanager wrapper failed to install the semicolon-named NDK package;
  manager 19.0 successfully installed NDK 28.2.13676358.
- Flutter Windows/Linux desktop targets disabled to avoid unrelated desktop-plugin
  symlink requirements on this Android setup. This does not disable Android builds.

## Project changes

- `android/local.properties`: replaced the other computer's SDK paths with local paths.
- `pubspec.yaml` / lockfile: project-local override for flutter_bluetooth_serial 0.4.0.
- `third_party/flutter_bluetooth_serial`: original license retained; only Android
  build configuration changed (JCenter/embedded AGP removed, namespace specified,
  manifest package removed, obsolete build-tools pin removed). Dart/Java API unchanged.
- `lib/ui/screens/intro_screen.dart`: Positioned now wraps AnimatedOpacity for
  windows and fountain, correcting the startup ParentDataWidget assertions.
- `test/intro_layout_test.dart`: checks initial layout and all animation phases.

Original project backup, created before these edits:
`C:/Users/josep/Downloads/dioramaapp-before-android-setup-20261103.zip`.

## Verification

- `flutter analyze --no-pub lib`: passed again after the intro layout fix.
- `flutter test --no-pub test/intro_layout_test.dart`: observed failing on the
  original ParentDataWidget errors, then passed after the fix.
- `flutter test --no-pub`: NOT fully passing. Existing `test/widget_test.dart`
  still refers to the removed `MyApp` counter-template class; compilation fails.
  This obsolete test was not changed as part of installing/running the app.
- First Android debug build installed and launched successfully on physical
  device H6WC4HGM7LGULNQO (2311DRK48G, Android 15/API35). User confirmed it runs.
- Corrected arm64 debug APK built successfully after the intro fix:
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Phone disconnected from ADB before the corrected APK could be installed.
  The running phone build is the first installation; reconnect for the update.

## Run or install the corrected build

From this folder, after connecting/unlocking the phone and allowing USB debugging:

```powershell
& C:/Users/josep/development/flutter/bin/flutter.bat run --no-pub -d H6WC4HGM7LGULNQO --no-resident
```

Or install the already-built APK with the local Android SDK:

```powershell
& C:/Users/josep/AppData/Local/Android/Sdk/platform-tools/adb.exe -s H6WC4HGM7LGULNQO install -r build/app/outputs/flutter-apk/app-debug.apk
& C:/Users/josep/AppData/Local/Android/Sdk/platform-tools/adb.exe -s H6WC4HGM7LGULNQO shell am start -n com.example.dioramaapp/.MainActivity
```

Use **Continue offline** to preview the app. Device control still needs the
previously identified Flutter/ESP32 API integration; this setup did not add it.
