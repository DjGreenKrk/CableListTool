# CableListTool Flutter

Start migracji CableListTool z Python/PySide6 do Flutter + Dart.

Ten katalog zawiera pierwszy szkielet warstw:

- `lib/domain` - modele i logika bez zależności od Fluttera,
- `lib/data` - odczyt/zapis JSON zgodny z obecną wersją Python,
- `lib/app` - start aplikacji i motyw,
- `test` - testy kompatybilności JSON i generatora oznaczeń.

## Wymagania

Flutter SDK nie jest jeszcze dostępny w lokalnym `PATH`. Po instalacji SDK uruchom:

```powershell
cd flutter
flutter pub get
flutter test
flutter run -d windows
```

Docelowo należy wygenerować brakujące katalogi platform:

```powershell
cd flutter
flutter create --platforms=windows,android .
```

## Status

Gotowe:

- modele `Project`, `Cabinet`, `Endpoint`, `Connection`, `Settings`,
- parser JSON z aliasami pól z wersji Python,
- rozwijanie starych połączeń `quantity > 1` do pojedynczych przewodów,
- generator oznaczeń i portów,
- naturalne sortowanie,
- testy startowe.

Do zrobienia jako kolejne kroki:

- repozytorium plików z pickerami Windows/Android,
- eksport XLSX,
- stan aplikacji Riverpod,
- responsywne ekrany Projekt/Szafy/Punkty/Połączenia/Eksport.
