# Status migracji Flutter

Data aktualizacji: 2026-06-25

## Wykonane

- Utworzono projekt Flutter w katalogu `flutter/`.
- Dogenerowano platformy `windows` i `android` przez `flutter create --platforms=windows,android`.
- Dodano bazową strukturę `lib/app`, `lib/domain`, `lib/data`.
- Przeniesiono pierwszy zestaw modeli domenowych:
  - `Project`,
  - `Cabinet`,
  - `Endpoint`,
  - `Connection`,
  - `Settings`,
  - `CableLabel`.
- Dodano `ProjectCodec` do odczytu i zapisu JSON.
- Zachowano kompatybilność z aktualnym formatem Python:
  - `schema_version: 1`,
  - alias `type` dla `cabinet_type` i `endpoint_type`,
  - alias `signal_type_descriptions` dla `signal_type_export_names`,
  - rozwijanie starego `quantity > 1` do pojedynczych przewodów.
- Przeniesiono pierwszą wersję generatora oznaczeń:
  - `SALA-RSC1-FB01-A-01`,
  - `A-01`,
  - `SALA-RSC1-NIEZNANE-ETH-01`.
- Dodano naturalne sortowanie.
- Dodano testy jednostkowe dla JSON i generatora.

## Weryfikacja

```powershell
cd flutter
flutter pub get
flutter analyze
flutter test
```

Wynik:

- `flutter analyze` - bez problemów,
- `flutter test` - wszystkie testy przechodzą.

## Stan środowiska

Flutter SDK działa lokalnie po ustawieniu:

```powershell
$env:PATH = "C:\Users\julek\SDK\flutter_windows_3.44.3-stable\flutter\bin;$env:PATH"
```

Wykryta wersja:

```text
Flutter 3.44.3
Dart 3.12.2
```

`flutter doctor` pokazuje braki przed buildami docelowymi:

- Windows: brak Visual Studio z workloadem `Desktop development with C++`,
- Android: brak `cmdline-tools` i niezaakceptowane licencje Android SDK.

## Następny krok

Etap 2 migracji:

- dopisać operacje stanu projektu w Riverpod,
- dodać repozytorium plików JSON,
- przywrócić zależności plikowe (`file_selector`, `path_provider`) po włączeniu Developer Mode albo przy implementacji zapisu/otwierania,
- rozpocząć ekrany robocze `Projekt`, `Szafy`, `Punkty`, `Połączenia`, `Eksport`.

## 2026-06-26 - pierwszy klikalny szkielet UI

Dodano pierwszą wersję roboczego interfejsu Flutter:

- główna nawigacja: `Projekt`, `Szafy`, `Punkty`, `Połączenia`, `Eksport`,
- stan projektu oparty o Riverpod,
- operacje dodawania, edycji i usuwania szaf,
- operacje dodawania, edycji i usuwania punktów,
- operacje dodawania, edycji, usuwania i odwracania połączeń,
- podgląd wygenerowanych oznaczeń w tabeli połączeń,
- podgląd danych eksportu z kolumnami docelowymi XLSX,
- zapis i odczyt JSON po ręcznie podanej ścieżce pliku.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- testy jednostkowe przechodzą,
- build Windows tworzy `build/windows/x64/runner/Release/cable_list_tool.exe`.

Do poprawy w kolejnych krokach:

- systemowy wybór pliku zamiast ręcznego wpisywania ścieżki,
- edycja słowników typów/statusów z UI,
- automatyczne nazwy według reguł,
- dodawanie wielu elementów naraz,
- eksport XLSX w Dart.

## 2026-06-26 - słowniki i automatyczne nazwy

Dodano kolejne elementy zgodności z wersją Python:

- edycja słowników w zakładce `Projekt`,
- parser formatu `Typ=Wzór`,
- parser formatu `Typ=Wzór|Priorytet`,
- obsługa `=` oraz `:` jako separatorów,
- automatyczne nazwy według reguł `RSC-N`, `FB-NN`,
- dodawanie wielu szaf i punktów przez pole `Ilość nowych`,
- zachowanie zer wiodących przy sekwencji nazw,
- testy jednostkowe dla parsera ustawień i generatora nazw.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 6 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - eksport XLSX

Dodano eksport XLSX w Dart:

- paczka `excel` w wersji `4.0.6`,
- arkusz `Lista kablowa`,
- kolumny: `Oznaczenie`, `Port`, `Skąd`, `Dokąd`, `Typ`, `Numer`, `Status`, `Uwagi`,
- stylowany nagłówek zgodny z kolorem akcentu,
- automatyczne dopasowanie szerokości kolumn,
- zapis pliku XLSX po ręcznie podanej ścieżce w zakładce `Eksport`,
- test budujący XLSX w pamięci i odczytujący go z powrotem.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 7 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - operacje terenowe i sortowanie

Dodano kolejne funkcje robocze:

- automatyczne przeliczanie priorytetów szaf według naturalnej kolejności nazw,
- naturalne sortowanie tabel szaf i punktów,
- naturalne sortowanie listy połączeń według wygenerowanego oznaczenia,
- zaznaczanie dwóch przewodów w tabeli połączeń,
- scalanie dwóch przewodów z nieznanym końcem w jeden znaleziony przewód,
- zachowanie numeru strony szafowej przy scalaniu,
- testy kontrolera dla priorytetów i scalania.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 9 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - ergonomia szybkiego dodawania

Dodano poprawki do formularzy:

- po dodaniu nowej szafy formularz zostawia typ i lokalizację,
- po dodaniu nowej szafy nazwa przechodzi na kolejną sugerowaną,
- po dodaniu nowego punktu formularz zostawia typ i lokalizację,
- po dodaniu nowego punktu nazwa przechodzi na kolejną sugerowaną,
- połączenia mają pole `Ilość nowych`,
- po dodaniu przewodu formularz połączeń zostawia źródło, typ sygnału i status,
- dodano test seryjnego dodawania połączeń.

Próba dodania systemowego wyboru plików przez `file_selector` została odłożona, ponieważ lokalny Windows nadal blokuje pluginy Flutter bez Developer Mode/symlink support.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 10 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - bezpieczniejszy zapis plików

Dodano zabezpieczenia zapisu:

- potwierdzenie nadpisania istniejącego XLSX,
- potwierdzenie nadpisania istniejącego JSON przy zapisie pod inną ścieżką,
- walidacja rozszerzenia `.json` dla projektu,
- walidacja rozszerzenia `.xlsx` dla eksportu,
- testy walidacji ścieżek zapisu.

Systemowy wybór pliku nadal pozostaje odłożony, ponieważ pluginy Flutter wymagają Developer Mode/symlink support na lokalnym Windows.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 12 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - test realnego projektu Flutter

Dodano test przepływu na przykładowym projekcie terenowym utworzonym w modelu Flutter:

- projekt `Sala konferencyjna 4.2`,
- szafa `RSC-1`,
- punkty `FB-01` i `PROJ-1`,
- przewód `ETH`,
- przewód `Audio` z kodem eksportu `A`,
- zapis JSON do katalogu tymczasowego,
- odczyt JSON,
- generowanie oznaczeń,
- eksport XLSX,
- odczyt XLSX i sprawdzenie arkusza `Lista kablowa`.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 13 testów jednostkowych/przepływowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - Android build

Sprawdzono Android:

- `flutter doctor` bez problemów,
- Android SDK i licencje OK,
- Visual Studio i Windows OK,
- dostępne AVD: `Medium_Phone`, `Medium_Tablet`, `Wear_OS_5_XL_Round`,
- `flutter build apk --debug` działa,
- wynik: `build/app/outputs/flutter-apk/app-debug.apk`,
- aplikacja instaluje się na aktywnym emulatorze Wear OS `emulator-5558`.

Stan emulatorów przy teście:

- `emulator-5558` - aktywny, Wear OS, 480x480,
- `emulator-5554` - offline,
- `emulator-5556` - authorizing.

Wniosek:

- Android toolchain i build APK są gotowe,
- pełny test ergonomii UI trzeba wykonać na telefonie/tablecie, gdy emulator przejdzie do stanu `device`.

## 2026-06-26 - systemowe okna wyboru plików

Po włączeniu Developer Mode na Windows dodano `file_selector` i systemowe okna plików:

- `Otwórz JSON`,
- `Zapisz JSON jako`,
- `Eksportuj XLSX` z wyborem lokalizacji,
- automatyczne dopisanie `.json` albo `.xlsx`, jeśli użytkownik pominie rozszerzenie,
- ręczne pole ścieżki zostało jako fallback i podgląd wybranej lokalizacji.

Wcześniej eksport bez pełnej ścieżki zapisywał plik względem katalogu roboczego aplikacji. Znaleziony wcześniejszy plik:

```text
C:\Users\julek\Documents\VS Code\CableListTool\PROJ_lista_kablowa.xlsx
```

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 12 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - XLSX freeze pane i autofiltr

Dodano dopracowanie eksportu XLSX:

- zamrożenie pierwszego wiersza arkusza,
- autofiltr dla zakresu `A1:H...`,
- test sprawdzający obecność `pane state="frozen"` i `autoFilter` w XML arkusza.

Biblioteka `excel` nie udostępnia publicznego API dla tych opcji, więc exporter dopisuje je do XML arkusza po wygenerowaniu pliku XLSX.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 12 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - ikona aplikacji

Podmieniono ikony z `docs/assets`:

- Windows: `docs/assets/logo_clean.ico` jako `windows/runner/resources/app_icon.ico`,
- Android mdpi: 48 px,
- Android hdpi: 72 px,
- Android xhdpi: 96 px,
- Android xxhdpi: 144 px,
- Android xxxhdpi: 192 px.

Ikony Android wygenerowano z `docs/assets/logo_clean.png`.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 12 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - branding bez podmiany ikony

Dodano elementy brandingu GreenCrew bez zmiany ikony aplikacji:

- zielony akcent GreenCrew w motywie Flutter,
- ciemniejszy techniczny motyw bazowy,
- nazwa okna Windows `CableListTool`,
- metadane EXE: `GreenCrew`, `CableListTool`, opis aplikacji i copyright,
- Android label `CableListTool`,
- Android package/application id `pl.greencrew.tools.cablelisttool`,
- ekran `O aplikacji` z informacją o GreenCrew, autorze, licencji i stronie.

Ikona aplikacji została celowo pozostawiona jako domyślna Flutter na tym etapie.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build windows
```

Wynik:

- analiza bez problemów,
- 12 testów jednostkowych przechodzi,
- build Windows poprawny.

## 2026-06-26 - Android telefon/tablet

Sprawdzono aplikacje na uruchomionych emulatorach telefonu i tabletu:

- `emulator-5556` - telefon, Android 16 API 36,
- `emulator-5554` - tablet, Android 15 API 35.

Poprawiono:

- przeniesiono `MainActivity` do pakietu `pl.greencrew.tools.cablelisttool`,
- usunieto overflow w gornym pasku na szerokosci telefonu.

Weryfikacja:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Wynik:

- analiza bez problemow,
- 13 testow przechodzi,
- APK debug instaluje sie na telefonie i tablecie,
- `am start` zwraca `Status: ok` na obu emulatorach,
- proces aplikacji pozostaje aktywny po starcie,
- screenshoty telefonu i tabletu potwierdzaja wyswietlenie UI.
