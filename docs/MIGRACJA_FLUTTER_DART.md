# Migracja CableListTool z Python/PySide6 do Flutter + Dart

Data przygotowania: 2026-06-25

## Cel migracji

Celem jest przepisanie aplikacji CableListTool z obecnej wersji Python + PySide6 na jedną bazę kodu Flutter + Dart działającą na:

* Windows 10/11,
* Android.

Migracja ma zachować aktualne założenie `offline first`:

* brak serwera,
* brak logowania,
* brak chmury,
* dane lokalne,
* eksport do XLSX,
* kompatybilność z istniejącymi plikami JSON projektu.

## Powód migracji

Obecna wersja Python/PySide6 dobrze działa na Windows, ale nie daje naturalnej ścieżki na Androida. Flutter pozwala utrzymać jeden kod UI i logiki dla Androida oraz Windows, przy zachowaniu lokalnego działania aplikacji.

## Źródła do potwierdzenia przy starcie prac

Przy zakładaniu projektu trzeba sprawdzić aktualne wersje Fluttera i paczek na oficjalnych stronach:

* Flutter desktop Windows: https://docs.flutter.dev/platform-integration/desktop
* Flutter Android setup: https://docs.flutter.dev/platform-integration/android/setup
* Flutter Windows setup: https://docs.flutter.dev/platform-integration/windows/setup
* Supported platforms: https://docs.flutter.dev/reference/supported-platforms
* file_selector: https://pub.dev/packages/file_selector
* file_picker: https://pub.dev/packages/file_picker
* path_provider: https://pub.dev/packages/path_provider
* excel: https://pub.dev/packages/excel
* file_saver: https://pub.dev/packages/file_saver

Nie wpisywać na sztywno wersji paczek w dokumentacji projektowej bez sprawdzenia ich aktualnego stanu.

## Zakres funkcjonalny do przeniesienia

Pierwsza wersja Flutter powinna odtworzyć funkcje obecnej wersji Python:

* tworzenie projektu z nazwą i kodem,
* zapis i odczyt projektu JSON,
* lista szaf,
* lista punktów,
* lista połączeń/przewodów,
* połączenia z nieznanym końcem,
* scalanie dwóch niezidentyfikowanych przewodów,
* odwracanie kierunku połączenia,
* automatyczna numeracja nazw szaf i punktów,
* priorytety szaf,
* priorytety typów punktów,
* kody eksportu i priorytety typów sygnałów,
* generowanie pełnego oznaczenia przewodu,
* generowanie krótkiego oznaczenia portu,
* eksport XLSX,
* lokalne zasoby graficzne i ikona aplikacji.

## Decyzja architektoniczna

Logika domenowa nie może być zaszyta w widgetach Fluttera.

Docelowy podział:

```text
lib/
  main.dart
  app/
    cable_list_app.dart
    app_theme.dart
    app_router.dart
  domain/
    models/
      project.dart
      cabinet.dart
      endpoint.dart
      connection.dart
      settings.dart
      cable_label.dart
    services/
      label_generator.dart
      name_sequence.dart
      natural_sort.dart
  data/
    project_codec.dart
    project_repository.dart
    xlsx_exporter.dart
  features/
    project/
    cabinets/
    endpoints/
    connections/
    export/
  shared/
    widgets/
    dialogs/
```

Zasada:

* `domain/` nie importuje Fluttera,
* `data/` odpowiada za JSON, pliki i XLSX,
* `features/` zawiera ekrany i kontrolery stanu,
* widgety korzystają z usług domenowych, ale ich nie implementują.

## Proponowany stan aplikacji

Na start wystarczy proste zarządzanie stanem:

* `ChangeNotifier` + `Provider`,
* albo `Riverpod`.

Rekomendacja: `Riverpod`, jeżeli projekt ma rosnąć. Daje łatwiejsze testowanie i mniej zależności od drzewa widgetów.

Minimalny stan aplikacji:

```text
ProjectState:
  project: Project
  currentPath: String?
  isDirty: bool
  generatedLabels: List<CableLabel>
```

Operacje stanu:

* `newProject()`,
* `openProject(path)`,
* `saveProject(path)`,
* `markDirty()`,
* `addCabinet()`,
* `updateCabinet()`,
* `deleteCabinet()`,
* `addEndpoint()`,
* `updateEndpoint()`,
* `deleteEndpoint()`,
* `addConnections(quantity)`,
* `updateConnection()`,
* `deleteConnections(ids)`,
* `reverseConnections(ids)`,
* `mergeUnknownConnections(firstId, secondId)`,
* `exportXlsx(path)`.

## Model danych Dart

Model powinien zachować obecny format JSON.

### Project

```dart
class Project {
  final String name;
  final String code;
  final List<Cabinet> cabinets;
  final List<Endpoint> endpoints;
  final List<Connection> connections;
  final Settings settings;
}
```

### Cabinet

```dart
class Cabinet {
  final String id;
  final String name;
  final String cabinetType;
  final String location;
  final String description;
  final int priority;
}
```

### Endpoint

```dart
class Endpoint {
  final String id;
  final String name;
  final String endpointType;
  final String location;
  final String description;
}
```

### Connection

```dart
class Connection {
  final String id;
  final String sourceId;
  final String destinationId;
  final String signalType;
  final int quantity;
  final String status;
  final int? cableNumber;
  final Map<String, String> cableStatuses;
  final String notes;
}
```

### Settings

```dart
class Settings {
  final List<String> cabinetTypes;
  final Map<String, String> cabinetNameRules;
  final List<String> endpointTypes;
  final Map<String, String> endpointNameRules;
  final Map<String, int> endpointTypePriorities;
  final List<String> signalTypes;
  final Map<String, String> signalTypeExportNames;
  final Map<String, int> signalTypePriorities;
  final List<String> statuses;
}
```

### CableLabel

```dart
class CableLabel {
  final String connectionId;
  final int cableIndex;
  final String designation;
  final String project;
  final String source;
  final String destination;
  final String signalType;
  final String exportSignalType;
  final String portLabel;
  final String number;
  final String status;
  final String notes;
}
```

## Kompatybilność JSON

Nowa aplikacja Flutter musi otwierać pliki zapisane przez wersję Python.

Aktualny zapis:

```json
{
  "schema_version": 1,
  "project": {
    "name": "Sala",
    "code": "SALA"
  },
  "cabinets": [],
  "endpoints": [],
  "connections": [],
  "settings": {}
}
```

Wymagania parsera:

* brakujące pole ma dostać wartość domyślną,
* stare `cabinet.type` ma być czytane jako `cabinet_type`,
* stare `endpoint.type` ma być czytane jako `endpoint_type`,
* stare `signal_type_descriptions` ma być czytane jako alias `signal_type_export_names`,
* `quantity > 1` ma być rozwijane do osobnych połączeń,
* `cable_statuses` jest mapą statusów indeksowanych tekstowo,
* puste `destination_id` oznacza nieznany koniec.

Rekomendacja:

* zachować `schema_version: 1` przy pierwszej wersji Flutter, jeżeli format JSON nie zostanie zmieniony,
* zwiększyć do `schema_version: 2` dopiero wtedy, gdy Flutter zapisze format niekompatybilny z Pythonem.

## Logika generatora oznaczeń

Generator oznaczeń trzeba przepisać testami 1:1 z Pythona.

Stałe:

```text
UNKNOWN_DESTINATION_NAME = "Nieznane"
UNKNOWN_DESTINATION_TOKEN = "NIEZNANE"
```

Pełne oznaczenie:

```text
{PROJECT}-{SOURCE}-{DESTINATION}-{PORT}
```

Port:

```text
{EXPORT_SIGNAL_TYPE}-{NUMBER}
```

Przykłady:

```text
Projekt: SALA
Skąd: RSC-1
Dokąd: FB-01
Typ: Audio
Kod eksportu typu: A
Numer: 01

Pełne oznaczenie: SALA-RSC1-FB01-A-01
Port: A-01
```

Jeżeli typ nie ma kodu eksportu:

```text
Typ: ETH
Port: ETH-10
```

Zasady numeracji:

* numeracja jest osobna dla każdego typu sygnału,
* połączenia ze stroną szafy zachowują `cable_number`,
* jeżeli połączenie jest szafa-szafa, numer zachowuje strona z wyższym priorytetem,
* jeżeli połączenie nie ma szafy, numer wynika z kolejności punktów i priorytetów typów punktów,
* szerokość numeru to minimum 2 cyfry,
* jeśli dany typ sygnału przekroczy 99, cały typ przechodzi na 3 cyfry,
* kod eksportu sygnału jest używany w oznaczeniu i XLSX,
* nazwa typu sygnału jest używana, gdy brak kodu eksportu.

## Sortowanie

Trzeba przenieść naturalne sortowanie:

```text
RSC-2 < RSC-10
FB-01 < FB-02 < FB-10
```

Kolejność połączeń:

1. Połączenia zawierające szafy.
2. Priorytet szafy.
3. Naturalna nazwa szafy.
4. Stały `cable_number`.
5. Priorytet typu punktu.
6. Naturalna nazwa punktu.
7. Id połączenia jako stabilny tie-breaker.

Kolejność typów sygnałów:

1. Priorytet typu sygnału.
2. Naturalna nazwa typu.

## Reguły tekstowe konfiguracji

Flutter powinien zachować aktualny format pól tekstowych.

Szafy:

```text
Typ=Wzór
```

Przykład:

```text
Szafa sterująca=RSC-N
Rack=RACK-N
```

Punkty:

```text
Typ=Wzór|Priorytet
```

Przykład:

```text
Floorbox=FB-NN|30
Panel=TSC-N|10
Projektor=PROJ-N|20
```

Typy sygnałów:

```text
Typ=Kod eksportu|Priorytet
```

Przykład:

```text
Audio=A|10
DMX=DMX|20
ETH
```

Statusy:

```text
Jedna wartość w linii.
```

Parser:

* obsłużyć `=` oraz `:` jako separator klucza i wartości,
* `|` rozdziela priorytet,
* błędny priorytet pominąć zamiast blokować cały zapis,
* puste linie ignorować.

## UI Windows + Android

Flutter UI musi mieć jeden model funkcjonalny, ale dwa układy responsywne.

### Windows

Układ może przypominać obecną aplikację:

* boczna nawigacja albo górne zakładki,
* duże tabele,
* formularz edycji po prawej,
* przyciski akcji nad/pod formularzem,
* eksport przez okno wyboru pliku.

### Android

Układ musi być wygodny dotykowo:

* dolna nawigacja albo `NavigationRail` w poziomie,
* listy zamiast szerokich tabel,
* formularz jako osobny ekran lub bottom sheet,
* akcje kontekstowe dla zaznaczonych przewodów,
* eksport przez systemowe udostępnianie/zapis pliku,
* większe pola dotykowe.

### Ekrany

Minimalny zestaw:

* `Projekt`,
* `Szafy`,
* `Punkty`,
* `Połączenia`,
* `Eksport`.

## Pliki i uprawnienia

Windows:

* użytkownik wybiera plik JSON do otwarcia,
* użytkownik wybiera miejsce zapisu JSON,
* użytkownik wybiera miejsce eksportu XLSX.

Android:

* nie zakładać swobodnego dostępu do dowolnej ścieżki pliku,
* używać systemowego pickera albo zapisu przez mechanizm udostępniania,
* kopia robocza projektu może być trzymana w katalogu aplikacji,
* eksport XLSX powinien pozwalać zapisać lub udostępnić plik.

Pakiety do rozważenia:

* `file_selector` albo `file_picker` do wyboru plików,
* `path_provider` do katalogów aplikacji,
* `file_saver` do zapisu/udostępniania plików na wielu platformach.

## Eksport XLSX w Dart

Obecny eksport ma arkusz `Lista kablowa`.

Kolumny:

```text
Oznaczenie
Port
Skąd
Dokąd
Typ
Numer
Status
Uwagi
```

Zasady:

* `Oznaczenie` to pełna etykieta,
* `Port` to krótka etykieta do drukarki, np. `ETH-10`,
* `Typ` to kod eksportu typu sygnału, a jeśli go nie ma, nazwa typu,
* `Numer` to sam numer połączenia,
* eksport powinien zachować autofiltr i zamrożony nagłówek, jeżeli biblioteka XLSX na to pozwala.

Pakiety:

* najpierw sprawdzić `excel`,
* jeżeli będzie brakować stylowania lub funkcji, rozważyć `syncfusion_flutter_xlsio`, ale sprawdzić licencję przed użyciem.

## Testy obowiązkowe przed migracją

Przed pisaniem Fluttera warto spisać testowe projekty JSON z obecnej wersji Python.

Scenariusze:

* puste dane i wartości domyślne,
* szafa `RSC-1` + 14 przewodów ETH z nieznanym końcem,
* znalezienie końca przewodu i scalenie dwóch niezidentyfikowanych przewodów,
* odwrócenie kierunku,
* połączenie szafa-punkt,
* połączenie punkt-punkt,
* połączenie szafa-szafa,
* sygnał `Audio=A|10`,
* sygnał bez kodu eksportu, np. `ETH`,
* typ punktu z priorytetem,
* przekroczenie 99 przewodów jednego typu,
* eksport XLSX z kolumną `Port`.

## Testy jednostkowe Dart

Priorytet testów:

1. `ProjectCodec` - odczyt i zapis JSON.
2. `LabelGenerator` - oznaczenia i numeracja.
3. `NaturalSort` - sortowanie nazw.
4. `NameSequence` - automatyczne nazwy.
5. `XlsxExporter` - kolejność kolumn i wartości.
6. Operacje na połączeniach: merge, reverse, unknown destination.

Testy generatora powinny porównywać dokładne stringi:

```text
SALA-RSC1-FB01-ETH-04
ETH-04
SALA-RSC1-NIEZNANE-A-01
A-01
```

## Plan migracji etapami

### Etap 0 - zamrożenie formatu

* Opisać aktualny format JSON.
* Zebrać przykładowe projekty testowe.
* Zebrać przykładowe eksporty XLSX.
* Ustalić, że Flutter v1 zapisuje `schema_version: 1`.

### Etap 1 - szkielet Flutter

* Utworzyć projekt Flutter.
* Włączyć platformy Windows i Android.
* Dodać ikonę i nazwę aplikacji.
* Dodać strukturę katalogów `domain`, `data`, `features`.
* Dodać podstawowy routing.

### Etap 2 - domena i JSON

* Przepisać modele.
* Przepisać parser JSON.
* Dodać wartości domyślne.
* Dodać migrację aliasów pól.
* Dodać testy JSON.

### Etap 3 - generator oznaczeń

* Przepisać naturalne sortowanie.
* Przepisać priorytety.
* Przepisać generator `CableLabel`.
* Dodać testy porównujące wyniki z wersją Python.

### Etap 4 - UI robocze

* Ekran projektu.
* Ekran szaf.
* Ekran punktów.
* Ekran połączeń.
* Ekran eksportu.
* Na tym etapie wygląd może być prosty, ale przepływy muszą działać.

### Etap 5 - operacje zaawansowane

* Dodawanie wielu elementów.
* Automatyczne nazwy.
* Automatyczne priorytety szaf.
* Nieznany koniec.
* Scalanie przewodów.
* Odwracanie kierunku.

### Etap 6 - eksport XLSX

* Implementacja arkusza `Lista kablowa`.
* Kolumna `Port`.
* Zapis pliku na Windows.
* Zapis lub udostępnianie pliku na Androidzie.

### Etap 7 - dopracowanie UI

* Responsywny układ Windows/Android.
* Walidacje formularzy.
* Dialog niezapisanych zmian.
* Komunikaty błędów.
* Testy ręczne na rzeczywistym projekcie z sali.

### Etap 8 - wydania

Windows:

* build `.exe` albo instalator,
* podpisywanie opcjonalnie później.

Android:

* build APK do testów,
* później AAB, jeśli aplikacja ma trafić do sklepu.

## Proponowane komendy startowe

```powershell
flutter doctor
flutter create cable_list_tool_flutter
cd cable_list_tool_flutter
flutter config --enable-windows-desktop
flutter run -d windows
flutter run -d android
```

Przed uruchomieniem na Androidzie:

* skonfigurować Android Studio,
* zainstalować SDK,
* uruchomić emulator albo podłączyć telefon,
* sprawdzić `flutter doctor`.

## Ryzyka migracji

Najważniejsze ryzyka:

* różnice w obsłudze plików między Windows i Android,
* eksport XLSX może mieć mniej funkcji niż `openpyxl`,
* szerokie tabele są niewygodne na Androidzie,
* łatwo przypadkiem zmienić format JSON,
* sortowanie i numeracja muszą być identyczne z Pythonem,
* polskie znaki w nazwach i eksporcie muszą działać poprawnie,
* Android może wymagać innego przepływu zapisu/udostępnienia pliku niż Windows.

Sposób ograniczenia ryzyka:

* najpierw testy domenowe,
* potem UI,
* nie zmieniać formatu JSON bez powodu,
* porównywać eksport z wersją Python,
* testować na realnym pliku z katalogu `baza informacji/testy`.

## Kryteria akceptacji migracji

Migracja jest udana, jeżeli:

* Flutter otwiera projekt JSON zapisany przez wersję Python,
* Flutter zapisuje projekt, który Python nadal potrafi otworzyć, dopóki używamy `schema_version: 1`,
* generator oznaczeń daje te same wyniki co Python,
* eksport XLSX ma te same kolumny i wartości,
* aplikacja działa offline na Windows,
* aplikacja działa offline na Androidzie,
* użytkownik może dodać salę od zera bez użycia komputera z Windowsem,
* przepływ pracy z nieznanymi przewodami działa na Androidzie wygodnie dotykowo.

## Rzeczy poza zakresem pierwszej migracji

Nie robić od razu:

* synchronizacji między urządzeniami,
* chmury,
* logowania,
* bazy SQL, jeśli JSON wystarcza,
* skanowania kodów QR,
* automatycznego importu z CAD,
* pełnego systemu uprawnień użytkowników.

Te tematy można dopisać później jako osobne moduły.

