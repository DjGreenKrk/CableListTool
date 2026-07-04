# Flutter backlog

Data aktualizacji: 2026-06-26

Założenie od teraz: nie wymagamy pełnej kompatybilności wstecznej z wersją Python. Flutter może rozwijać własny model, o ile zachowuje sens workflow CableListTool.

## Braki do pełnej funkcjonalności

- Dalsze dopracowanie ergonomii formularzy po zapisie.
  - Częściowo wykonane: po dodaniu szafy/punktu zostaje typ i lokalizacja, nazwa przechodzi na kolejną sugerowaną.
  - Częściowo wykonane: połączenia mają `Ilość nowych`.
- Test Android na telefonie/tablecie.
  - Toolchain Android jest już zielony.
  - `flutter build apk --debug` działa.
  - Aplikacja instaluje się na dostępnym emulatorze Wear OS, ale test ergonomii UI wymaga telefonu/tabletu.
  - Obecne emulatory telefonu/tabletu są widoczne jako `offline`/`authorizing`.

## Wykonane z backlogu

- Scalanie dwóch niezidentyfikowanych przewodów.
- Automatyczne przeliczanie priorytetów szaf z nazw typu `RSC-1`, `RSC-2`.
- Naturalne sortowanie tabel i list wyboru.
- Część ergonomii formularzy po zapisie.
- Potwierdzenie nadpisania XLSX.
- Zamrożenie nagłówka i autofiltr XLSX.
- Systemowy wybór plików JSON/XLSX.
- Ikona i zasoby aplikacji Flutter dla Windows/Android.
- Test na realnym projekcie terenowym zapisanym z Fluttera.
- Android toolchain i build APK debug.

## Priorytet

1. Ułatwienia pracy w tabelach i formularzach.
2. Operacje terenowe na przewodach: nieznany koniec, scalanie, odwracanie.
3. Pliki i eksport.
4. Zasoby, ikony i dopracowanie wydania.

## 2026-06-26 - Android telefon/tablet

Wykonane:

- APK debug instaluje sie i uruchamia na emulatorze telefonu `emulator-5556`.
- APK debug instaluje sie i uruchamia na emulatorze tabletu `emulator-5554`.
- Poprawiono pakiet `MainActivity`, zeby pasowal do `pl.greencrew.tools.cablelisttool`.
- Poprawiono overflow w gornym pasku na szerokosci telefonu.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build apk --debug
adb -s emulator-5556 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5556 shell am start -W -n pl.greencrew.tools.cablelisttool/.MainActivity
adb -s emulator-5554 shell am start -W -n pl.greencrew.tools.cablelisttool/.MainActivity
```

## 2026-07-04 - v2.0.0

Zalozenie wersjonowania:

- ostatnia wersja Python to `v1.1.0`,
- pierwsza wersja Flutter jest oznaczona jako `v2.0.0`.

Wykonane:

- pelnoprawny zapis projektow w aplikacji,
- JSON jako backup/import projektu,
- eksport XLSX i JSON przez systemowy manager plikow na Androidzie,
- responsywne kafelki szaf, punktow i kabli,
- dlugie przytrzymanie kabla jako zaznaczenie do scalania,
- klik w ikone niezapisanych zmian zapisuje projekt,
- dokumentacja GitHub odswiezona pod Flutter jako glowna wersje.

Nastepne sensowne kroki:

- test manualny eksportu XLSX/JSON na fizycznym Androidzie,
- podpisywanie release APK/AAB,
- dopracowanie ekranu eksportu dla pustej listy kabli.
