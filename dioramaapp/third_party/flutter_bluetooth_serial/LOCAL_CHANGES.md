# Local Android build compatibility

Based on pub.dev flutter_bluetooth_serial 0.4.0; original LICENSE retained.
Dart and Java plugin sources are unchanged. This copy is selected by the root
pubspec's dependency_overrides entry, so the shared Pub cache remains untouched.

- Removed obsolete JCenter repositories and the embedded AGP 4.1.0 buildscript;
  use the application Gradle plugin and Maven repositories instead.
- Added explicit Android namespace and removed manifest package metadata.
- Removed obsolete build-tools pin; the application's AGP chooses the tools.

The app's existing root build configuration sets library compile SDK to 36.
