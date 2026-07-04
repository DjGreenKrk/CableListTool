# CableListTool

Offline-first tool for cable inventory, labeling and documentation.

CableListTool is built for technicians documenting real installations: AV,
lighting, control, electrical and similar systems. The active application is the
Flutter version for Windows and Android. The original Python/PySide6 version is
kept in `python/` as a reference implementation.

## Current Version

`v2.0.0`

Versioning note: the last Python/PySide6 line was `v1.1.0`; Flutter starts as
the second major generation at `v2.0.0`.

## Features

- Offline project workflow.
- Local in-app project storage on Android and Windows.
- JSON import/export for backup and interchange.
- XLSX cable list export.
- Cabinet and endpoint management.
- Cable connections with unknown destination workflow.
- Merge two unknown cable ends after identification.
- Reverse cable direction.
- Automatic cable labels and port labels.
- Natural sorting for field-friendly names such as `RSC-1`, `RSC-2`, `RSC-10`.
- Mobile-friendly Material 3 UI with GreenCrew branding.

## Platforms

- Android: supported, including phone and tablet layouts.
- Windows 10/11: supported.

## Repository Layout

- `flutter/` - active Flutter/Dart application.
- `python/` - legacy/reference Python implementation.
- `docs/` - migration notes, branding, UX notes and implementation docs.

## Build

Use the Flutter SDK configured for this workspace:

```powershell
$env:PATH = "C:\Users\julek\SDK\flutter_windows_3.44.3-stable\flutter\bin;$env:PATH"
cd flutter
flutter pub get
flutter test
flutter build apk --release
flutter build windows --release
```

Release artifacts:

- Android APK: `flutter/build/app/outputs/flutter-apk/app-release.apk`
- Windows app: `flutter/build/windows/x64/runner/Release/`

## Project Storage

The primary save path is now internal application storage. JSON is treated as a
backup/import/export format rather than the main project database.

On Android, JSON and XLSX export use the system file manager so the user can
choose the target location.

## License

MIT

## Author

Julian Szymanski  
GreenCrew / GreenCrew Tools  
https://greencrew.pl
