# CableListTool

Prosta desktopowa aplikacja offline do przygotowywania list kablowych istniejących instalacji technicznych.

## Uruchomienie

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python main.py
```

## Funkcje pierwszej wersji

* projekt z nazwą i kodem,
* zapis i odczyt pliku JSON,
* edycja typów szaf, punktów, sygnałów i statusów,
* lista szaf z priorytetami liczbowymi,
* szybkie dodawanie wielu szaf i punktów z automatyczną numeracją nazw,
* reguły domyślnych nazw dla typów, np. `Szafa sterująca=RSC-N`, `Floorbox=FB-NN`,
* naturalne sortowanie szaf, punktów i połączeń,
* priorytety typów punktów niższe od priorytetów szaf, wpisywane jako `Panel=TSC-N|10`,
* kody eksportu i priorytety typów sygnałów, wpisywane jako `Audio=A|10`,
* automatyczne przeliczanie priorytetów szaf na podstawie numerów w nazwach,
* lista punktów końcowych,
* lista połączeń ze wspólnym wyborem `Cabinet + Endpoint`,
* połączenia z nieznanym końcem `Dokąd = Nieznane`,
* każde połączenie/przewód jako osobny wiersz w tabeli,
* dodawanie wielu nowych przewodów przez pole `Ilość nowych`,
* scalanie dwóch niezidentyfikowanych przewodów w jedno znalezione połączenie,
* odwracanie kierunku wybranych przewodów,
* zachowanie numeru przewodu po stronie szafy po znalezieniu drugiego końca,
* generator oznaczeń z globalną numeracją per typ sygnału,
* status domyślny połączenia oraz status nadpisany dla pojedynczego przewodu,
* eksport XLSX do arkusza `Lista kablowa`.

## Build

Metadane aplikacji:

* `app_metadata.py` - nazwa i wersja widoczna w aplikacji,
* `version_info.txt` - metadane Windows EXE, takie jak wersja, twórca, opis, język.

```powershell
.\build_onefile.ps1
```

Wynikowy plik:

```text
dist/CableListTool.exe
```
