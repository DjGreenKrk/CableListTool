# PROJECT.md

# CableListTool

## Cel projektu

Stworzyć prostą desktopową aplikację offline do przygotowywania dokumentacji kablowej istniejących instalacji technicznych.

Program ma wspierać inwentaryzację i tworzenie list kablowych dla obiektów takich jak:

* sale konferencyjne,
* instalacje AV,
* instalacje oświetleniowe,
* systemy sterowania,
* obiekty sceniczne,
* budynki inteligentne.

Nie jest celem tworzenie systemu CAD, schematów elektrycznych ani pełnego odpowiednika EPLAN.

Program ma być szybkim narzędziem terenowym działającym na laptopie.

---

# Główne założenia

## Offline First

Aplikacja musi działać:

* bez internetu,
* bez serwera,
* bez chmury,
* bez logowania,
* bez synchronizacji.

Całość działa lokalnie.

---

## Platforma

Docelowo:

* Windows 10
* Windows 11

---

## Technologia

Backend:

* Python 3.12+

GUI:

* PySide6

Przechowywanie danych:

* JSON

Eksport:

* openpyxl

Build:

* PyInstaller

---

# Struktura projektu

```text
CableListTool/
│
├── main.py
├── models.py
├── storage.py
├── naming.py
├── export_xlsx.py
│
├── ui/
│   ├── main_window.py
│   ├── project_page.py
│   ├── cabinets_page.py
│   ├── endpoints_page.py
│   ├── connections_page.py
│
├── resources/
│
├── requirements.txt
└── README.md
```

---

# Model danych

## Project

```python
Project:
    name: str
    code: str
    cabinets: list
    endpoints: list
    connections: list
```

Przykład:

```json
{
  "name": "Sala 9.1",
  "code": "S9.1"
}
```

---

## Cabinet

```python
Cabinet:
    id: str
    name: str
    description: str
```

Przykład:

```json
{
  "name": "RSC-1"
}
```

---

## Endpoint

```python
Endpoint:
    id: str
    name: str
    endpoint_type: str
    location: str
    description: str
```

Przykład:

```json
{
  "name": "FB-01",
  "endpoint_type": "Floorbox"
}
```

---

## Connection

```python
Connection:
    id: str
    source_id: str
    destination_id: str
    signal_type: str
    quantity: int
    status: str
    notes: str
```

---

# Typy punktów

Domyślnie:

```text
Floorbox
Oprawa
Panel
Przycisk
Rack
Urządzenie
Inne
```

Lista musi być rozszerzalna.

---

# Typy sygnałów

Domyślnie:

```text
ETH
DMX
DALI
230V
AUDIO
HDMI
USB
CTRL
INNE
```

Lista musi być rozszerzalna.

---

# Statusy

```text
Do sprawdzenia
Potwierdzone
Niezgodność
Brak kabla
Niezidentyfikowany
```

Lista musi być rozszerzalna.

---

# Generator oznaczeń

Program generuje oznaczenia automatycznie.

Domyślny wzór:

```text
{PROJECT}-{FROM}-{TO}-{TYPE}-{NN}
```

Przykład:

```text
S9.1-RSC1-FB01-ETH-01
S9.1-RSC1-FB01-ETH-02
```

Zasady:

1. Nazwy obiektów w oznaczeniu nie zawierają myślników.

Przykład:

```text
RSC-1 -> RSC1
FB-01 -> FB01
```

2. Numeracja jest dwucyfrowa.

```text
01
02
03
...
99
```

3. Dla quantity > 1 tworzone są kolejne oznaczenia.

Przykład:

```text
quantity = 3
```

wynik:

```text
S9.1-RSC1-FB01-ETH-01
S9.1-RSC1-FB01-ETH-02
S9.1-RSC1-FB01-ETH-03
```

---

# Funkcjonalności MVP

## Zarządzanie projektem

Użytkownik może:

* utworzyć projekt,
* otworzyć projekt,
* zapisać projekt.

Format:

```text
*.json
```

---

## Zarządzanie szafami

Operacje:

* dodaj,
* edytuj,
* usuń.

Pola:

* nazwa,
* opis.

---

## Zarządzanie punktami

Operacje:

* dodaj,
* edytuj,
* usuń.

Pola:

* nazwa,
* typ,
* lokalizacja,
* opis.

---

## Zarządzanie połączeniami

Operacje:

* dodaj,
* edytuj,
* usuń.

Pola:

* skąd,
* dokąd,
* typ sygnału,
* ilość,
* status,
* uwagi.

---

## Podgląd oznaczeń

Po zapisaniu połączenia użytkownik od razu widzi wygenerowane oznaczenia.

Przykład:

```text
S9.1-RSC1-FB01-ETH-01
S9.1-RSC1-FB01-ETH-02
```

---

## Eksport XLSX

Program eksportuje arkusz:

```text
Lista kablowa
```

Kolumny:

```text
Oznaczenie
Projekt
Skąd
Dokąd
Typ
Numer
Status
Uwagi
```

Każde oznaczenie stanowi osobny wiersz.

---

# Interfejs

Układ głównego okna:

```text
+------------------------------------------------+
| Menu                                           |
+------------------------------------------------+
| Projekt | Szafy | Punkty | Połączenia | Export |
+------------------------------------------------+
|                                                |
|                aktywna zakładka                |
|                                                |
+------------------------------------------------+
```

Wszystkie widoki oparte o tabelę.

Nie stosować kreatorów.

Nie stosować popupów do głównej pracy.

Preferowane formularze boczne lub dolne.

---

# Styl

Nowoczesny ciemny interfejs inspirowany:

* SP9MOA Morse Simulator
* VS Code
* Q-SYS Designer

Kolorystyka:

```text
Tło:
#07111a

Panele:
#0d1a24

Obramowania:
#1f3443

Tekst:
#eef8ff

Akcent:
#2b5c79
```

---

# Zapis danych

JSON ma być czytelny dla człowieka.

Nie używać binarnych formatów.

Przykładowy projekt powinien być możliwy do ręcznej edycji w Notepad++.

---

# Build

Program musi poprawnie budować się przez:

```powershell
pyinstaller --noconfirm --onefile --windowed --name CableListTool main.py
```

---

# Etapy implementacji

## Etap 1

* modele danych
* zapis JSON
* odczyt JSON

## Etap 2

* zakładka Szafy
* zakładka Punkty

## Etap 3

* zakładka Połączenia

## Etap 4

* generator oznaczeń

## Etap 5

* eksport XLSX

## Etap 6

* dopracowanie UI

---

# Ważne

Priorytetem jest:

1. prostota,
2. stabilność,
3. szybkość pracy,
4. możliwość używania na budowie.

Priorytetem NIE jest:

* synchronizacja,
* wielodostęp,
* aplikacja mobilna,
* integracje sieciowe,
* CAD,
* schematy elektryczne.
