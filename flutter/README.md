# CableListTool Flutter

Active Flutter/Dart implementation of CableListTool.

## Version

`v2.0.0`

The Python/PySide6 line ended at `v1.1.0`; Flutter is versioned as the next
major generation.

## Status

Implemented:

- Riverpod project state.
- Domain models and JSON codec.
- Local in-app project storage.
- JSON backup/import.
- XLSX export with frozen header and autofilter.
- Windows and Android builds.
- Android phone/tablet responsive UI.
- GreenCrew branding and application icons.
- Unit and workflow tests.

## Development

```powershell
$env:PATH = "C:\Users\julek\SDK\flutter_windows_3.44.3-stable\flutter\bin;$env:PATH"
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Release Builds

```powershell
flutter build apk --release
flutter build windows --release
```

Artifacts:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/windows/x64/runner/Release/`
