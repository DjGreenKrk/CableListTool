# NOTATKI_IMPLEMENTACYJNE.md

# CableListTool - notatki implementacyjne

---

# 2026-06-21 - pierwsza wersja robocza

Utworzono pierwszą działającą wersję aplikacji poza katalogiem `baza informacji`.

Zakres:

* modele danych: `Project`, `Cabinet`, `Endpoint`, `Connection`, `Settings`,
* zapis i odczyt JSON w UTF-8,
* generator oznaczeń kablowych,
* numeracja globalna osobno dla każdego typu sygnału,
* automatyczne dopasowanie szerokości numeru, np. `01` albo `001`,
* priorytety szaf z automatycznym przeliczaniem na podstawie numerów w nazwach,
* połączenia wybierane ze wspólnej listy `Cabinet + Endpoint`,
* blokada wyboru tego samego obiektu jako źródła i celu,
* eksport XLSX do arkusza `Lista kablowa`,
* UI PySide6 z zakładkami: Projekt, Szafy, Punkty, Połączenia, Export,
* ciemny styl zgodny z kierunkiem z `PROJECT.md`,
* `requirements.txt`,
* `README.md`.

Weryfikacja wykonana:

* kompilacja składni przez `python -m compileall .`,
* test zapisu i odczytu JSON,
* test eksportu XLSX,
* test utworzenia okna PySide6 w trybie offscreen.

Do sprawdzenia ręcznie w aplikacji:

* wygoda edycji list słownikowych w zakładce Projekt,
* ergonomia formularza połączeń,
* czy podgląd oznaczeń jest wystarczająco widoczny,
* czy priorytety szaf są zrozumiałe w praktyce,
* czy eksport XLSX ma wystarczający układ kolumn.

Możliwe następne poprawki:

* lepszy podgląd oznaczeń jeszcze przed zapisem nowego połączenia,
* filtrowanie i wyszukiwanie w tabelach,
* skróty klawiaturowe dla dodawania i zapisu,
* status niezapisanych zmian w pasku tytułu,
* przykładowy plik projektu testowego.

---

# 2026-06-21 - status pojedynczego przewodu i eksport

Zmiany po pierwszym teście UI:

* dodano możliwość ustawienia statusu dla pojedynczego wygenerowanego przewodu w połączeniu,
* połączenie nadal ma status domyślny,
* status konkretnego przewodu jest zapisywany jako nadpisanie względem statusu połączenia,
* przykład: połączenie ETH o ilości 3 może mieć status ogólny `Potwierdzone`, a tylko drugi przewód może mieć `Niezgodność`,
* eksport XLSX używa statusu konkretnego przewodu, jeżeli został ustawiony,
* z eksportu XLSX usunięto kolumnę `Projekt`; pierwsza kolumna to `Oznaczenie`, druga to `Skąd`.

---

# 2026-06-21 - połączenia z nieznanym końcem

Dodano możliwość tworzenia połączeń, w których znane jest tylko `Skąd`, a `Dokąd` pozostaje nieznane.

Przykład użycia:

* w `RSC-1` znaleziono 14 przewodów ETH,
* 4 przewody mają znane zakończenie, np. `FB-1`,
* pozostałe można dodać jako `RSC-1 -> Nieznane`,
* takie przewody dostają status `Niezidentyfikowany`,
* po odnalezieniu końca można edytować połączenie i wybrać właściwe `Dokąd`.

W generatorze oznaczeń nieznany koniec jest zapisywany jako `NIEZNANE`, np.:

```text
S9.1-RSC1-NIEZNANE-ETH-01
```

---

# 2026-06-21 - tabela połączeń jako lista przewodów

Po analizie danych z `baza informacji/testy/test1.json` przebudowano zakładkę `Połączenia`.

Zmiany:

* każdy przewód jest osobnym wierszem tabeli,
* tabela pokazuje kolumnę `Oznaczenie`,
* pole `Ilość nowych` tworzy wiele osobnych przewodów zamiast jednej grupy z `quantity > 1`,
* pliki zapisane w starym modelu są automatycznie rozbijane po otwarciu na pojedyncze przewody,
* usunięto potrzebę osobnej sekcji `Oznaczenia`,
* dodano przycisk `Odwróć kierunek`,
* dodano przycisk `Połącz przewody` dla dwóch niezidentyfikowanych przewodów tego samego typu.

Sprawdzone na danych testowych:

* `test1.json` po migracji daje 26 pojedynczych przewodów,
* połączenie dwóch nieznanych przewodów zmniejsza liczbę wierszy o 1,
* odwrócenie `WB-1 -> RSC-1` daje oznaczenie w kierunku `RSC-1 -> WB-1`.

---

# 2026-06-21 - szybkie dodawanie szaf i punktów

Poprawiono zachowanie formularzy `Szafy` i `Punkty`.

Zmiany:

* po zapisie nowego elementu formularz nie zostaje w trybie edycji utworzonego rekordu,
* typ i lokalizacja zostają w formularzu,
* opis jest czyszczony,
* nazwa przechodzi na następną sugerowaną wartość,
* dodano pole `Ilość nowych`,
* `RSC-1` przy ilości 3 tworzy `RSC-1`, `RSC-2`, `RSC-3`,
* `FB-01` przy ilości 3 tworzy `FB-01`, `FB-02`, `FB-03`,
* `Panel` przy ilości 3 tworzy `Panel-1`, `Panel-2`, `Panel-3`.

Weryfikacja:

* składnia Python OK,
* test sekwencji nazw OK,
* test offscreen UI OK,
* po dodaniu `RSC-1` x3 formularz pokazuje `RSC-4` i `current_id = None`.

---

# 2026-06-21 - naturalne sortowanie list

Dodano naturalne sortowanie w UI i generatorze.

Zmiany:

* tabela `Szafy` sortuje po nazwie naturalnie,
* tabela `Punkty` sortuje po nazwie naturalnie,
* pola wyboru `Skąd` i `Dokąd` pokazują najpierw posortowane szafy, potem posortowane punkty,
* generator oznaczeń używa naturalnego porównania nazw obiektów przy ustalaniu kolejności połączeń.

Przykłady sprawdzone:

* `RSC-1`, `RSC-2`, `RSC-10`,
* `TSC-1`, `TSC-2`, `TSC-3`, `TSC-10`,
* połączenia do `TSC-1`, `TSC-2`, `TSC-10` generują się w tej kolejności.

---

# 2026-06-21 - trwałe numery przewodów po stronie szafy

Dodano trwały numer przewodu dla połączeń zawierających szafę.

Zmiany:

* model `Connection` ma pole `cable_number`,
* generator nadaje `cable_number` przewodom z szafą, jeśli jeszcze go nie mają,
* numer jest zapisywany w JSON,
* po uzupełnieniu drugiego końca przewodu numer zostaje taki sam,
* przy łączeniu dwóch nieznanych przewodów wybierany jest numer strony szafowej,
* przy połączeniu szafa-szafa obowiązuje strona szafy o wyższym priorytecie.

Sprawdzony przypadek:

* przed: `S4.2-RSC1-NIEZNANE-ETH-04`,
* po połączeniu z projektorem: `S4.2-RSC1-Proj1-ETH-04`,
* numer `04` zostaje zachowany.

---

# 2026-06-21 - priorytety typów punktów

Dodano priorytety typów punktów.

Zmiany:

* model `Settings` ma pole `endpoint_type_priorities`,
* zakładka `Projekt` ma priorytety wpisywane w tym samym polu co typy i nazwy punktów,
* format wpisu to `Typ=Wzór|Priorytet`, np. `Panel=TSC-N|10`,
* tabele punktów i comboboksy `Skąd` / `Dokąd` uwzględniają priorytety typów,
* generator oznaczeń uwzględnia priorytety typów punktów poniżej reguł szaf.

Weryfikacja:

* `Panel=TSC-N|10`, `Projektor=PROJ-N|20`,
* `TSC-1` dostaje niższy numer niż `Proj-1`,
* punkt bez priorytetu typu trafia za punktami z ustawionym priorytetem.

---

# 2026-06-21 - reguły domyślnych nazw typów

Dodano automatyczne nazwy na podstawie typu, gdy pole `Nazwa` zostanie puste.

Zmiany:

* model `Settings` ma pola `cabinet_name_rules` i `endpoint_name_rules`,
* zakładka `Projekt` ma połączone pola `Typy i nazwy szaf` oraz `Typy i nazwy punktów`,
* format reguł to `Typ=Wzór`,
* dla punktów format może zawierać priorytet: `Typ=Wzór|Priorytet`,
* wzór obsługuje placeholder `N`, np. `RSC-N`, `FB-NN`, `ABC-NNN`,
* liczba znaków `N` określa zera wiodące,
* dopasowanie typu jest odporne na brak polskich znaków.

Domyślne przykłady:

* `Szafa sterująca=RSC-N`,
* `Floorbox=FB-NN`,
* `Panel=TSC-N|10`,
* `Projektor=PROJ-N|20`.

Weryfikacja:

* pusta nazwa + `Szafa sterująca` tworzy `RSC-1`, potem `RSC-2`,
* pusta nazwa + `Floorbox` tworzy `FB-01`, potem `FB-02`,
* pusta nazwa + `Panel` tworzy `TSC-1`,
* własny wzór `RSC-NN` tworzy `RSC-01`.

---

# 2026-06-22 - build onefile i logo

Przygotowano build aplikacji jako pojedynczy plik EXE.

Źródła grafiki:

* logo i ikony znajdują się w `baza informacji/grafiki`,
* do aplikacji skopiowano zasoby do `resources`,
* główna ikona aplikacji to `resources/CableListTool.ico`,
* dodatkowy obraz logo to `resources/CableListTool.png`.

Zmiany techniczne:

* dodano `app_resources.py` do obsługi ścieżek zasobów w trybie źródłowym i PyInstaller,
* ustawiono ikonę aplikacji w `main.py`,
* ustawiono ikonę głównego okna w `ui/main_window.py`,
* dodano `CableListTool.spec`,
* dodano `build_onefile.ps1`,
* zaktualizowano `.gitignore` o `build/`, `dist/`, `.venv/`, `__pycache__/` i `*.pyc`.

Build:

```powershell
.\build_onefile.ps1
```

Wynik:

```text
dist/CableListTool.exe
```

Weryfikacja:

* kompilacja Pythona OK,
* ikona zasobu widoczna dla aplikacji,
* okno PySide6 startuje z ikoną w teście offscreen,
* PyInstaller zbudował `dist/CableListTool.exe` jako onefile.

---

# 2026-06-22 - metadane EXE

Dodano metadane aplikacji i pliku EXE.

Pliki:

* `app_metadata.py` - nazwa, wersja, autor, opis, język używane przez aplikację,
* `version_info.txt` - zasób wersji Windows dla PyInstaller,
* `CableListTool.spec` - podpięcie `version_info.txt`.

Domyślne wartości:

* wersja: `0.1.0`,
* plikowa wersja Windows: `0.1.0.0`,
* nazwa produktu: `CableListTool`,
* twórca: `CableListTool`,
* język zasobu: Polish (Poland), kod `0415`, Unicode `1200`.

Do personalizacji przed publikacją:

* podać właściwą nazwę twórcy lub firmy,
* ewentualnie zmienić opis aplikacji,
* przy kolejnych buildach aktualizować wersję jednocześnie w `app_metadata.py` i `version_info.txt`.

---

# 2026-06-22 - kody eksportu i priorytety typów sygnałów

Typy sygnałów w zakładce `Projekt` obsługują teraz format `Typ=Kod eksportu|Priorytet`.

Przykłady:

```text
Audio=A|10
DMX=DMX|20
DALI=DL|30
HDMI
```

Zmiany techniczne:

* model `Settings` ma pola `signal_type_export_names` i `signal_type_priorities`,
* stare projekty z samą listą `signal_types` pozostają kompatybilne,
* brak kodu eksportu i brak priorytetu są poprawne,
* stare pole `signal_type_descriptions` jest czytane jako alias migracyjny,
* oznaczenie przewodu i eksport XLSX używają kodu eksportu, jeżeli został ustawiony,
* generator oznaczeń sortuje grupy typów sygnałów po priorytecie, a potem naturalnie po nazwie,
* numeracja przewodów nadal jest prowadzona osobno dla każdego typu sygnału.

---

# 2026-06-22 - kolumna portu w eksporcie XLSX

Eksport XLSX ma dodatkową kolumnę `Port` z krótkim oznaczeniem do drukarki etykiet.

Zasady:

* `Port` to ostatni człon pełnego oznaczenia,
* format to `KodTypu-Numer`, np. `ETH-10` albo `A-01`,
* jeżeli typ sygnału ma kod eksportu po `=`, używany jest kod eksportu,
* jeżeli typ sygnału nie ma kodu eksportu, używana jest nazwa typu sygnału.
