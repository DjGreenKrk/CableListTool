# PLAN.md

# CableListTool - plan stworzenia programu

Ten dokument jest roboczą bazą planów, decyzji i wskazówek do przyszłej implementacji. Nie zawiera kodu programu. Kod aplikacji powinien powstawać poza katalogiem `baza informacji`.

---

# 1. Interpretacja celu

CableListTool ma być prostym, szybkim narzędziem desktopowym do przygotowywania dokumentacji kablowej istniejących instalacji technicznych.

Najważniejsza myśl projektowa:

> To nie jest CAD, EPLAN ani system projektowania instalacji. To praktyczne narzędzie terenowe do porządkowania list kablowych.

Program powinien pomagać użytkownikowi szybko odpowiedzieć na pytania:

* jakie punkty istnieją w obiekcie,
* jakie szafy lub racki występują,
* co jest połączone z czym,
* jakiego typu jest sygnał,
* ile kabli trzeba opisać,
* jaki status ma dane połączenie,
* jakie oznaczenia kablowe wynikają z danych.

---

# 2. Zakres MVP

MVP powinno być celowo małe. Najpierw należy zbudować stabilny przepływ pracy:

1. Utworzenie projektu.
2. Dodanie szaf.
3. Dodanie punktów końcowych.
4. Dodanie połączeń.
5. Automatyczne wygenerowanie oznaczeń.
6. Zapis i odczyt pliku JSON.
7. Eksport listy kablowej do XLSX.

W MVP nie należy dodawać:

* kont użytkowników,
* synchronizacji,
* bazy SQL,
* chmury,
* widoku schematów,
* rysowania instalacji,
* zaawansowanego workflow zatwierdzania,
* automatycznego wykrywania urządzeń.

---

# 3. Proponowana architektura

Projekt warto podzielić na trzy warstwy:

## 3.1. Warstwa modelu

Pliki:

* `models.py`

Odpowiedzialność:

* definicje danych,
* walidacja podstawowych pól,
* konwersja do/z słownika JSON,
* brak zależności od PySide6.

Modele powinny być możliwie czyste i niezależne od GUI. Dzięki temu później łatwo będzie pisać testy generatora oznaczeń, zapisu JSON i eksportu XLSX.

Sugerowane modele:

* `Project`
* `Cabinet`
* `Endpoint`
* `Connection`

Każdy obiekt powinien mieć stabilne `id`, niezależne od nazwy widocznej dla użytkownika. Nazwa może się zmienić, ale powiązania między obiektami nie powinny się wtedy psuć.

Po doprecyzowaniu wymagań należy zachować dwie główne kategorie danych:

* `Cabinet` - szafy sterujące, racki, szafy elektryczne i podobne punkty centralne,
* `Endpoint` - przyłącza, urządzenia, oprawy, panele, projektory i inne punkty podpięte na stałe.

W UI połączeń źródło i cel powinny być wybierane ze wspólnej listy złożonej z `Cabinet + Endpoint`.

## 3.2. Warstwa logiki

Pliki:

* `storage.py`
* `naming.py`
* `export_xlsx.py`

Odpowiedzialność:

* zapis i odczyt JSON,
* generowanie oznaczeń,
* eksport XLSX,
* funkcje pomocnicze niezależne od GUI.

Ta warstwa nie powinna importować komponentów PySide6. GUI powinno wywoływać logikę, ale logika nie powinna znać GUI.

## 3.3. Warstwa interfejsu

Pliki:

* `main.py`
* `ui/main_window.py`
* `ui/project_page.py`
* `ui/cabinets_page.py`
* `ui/endpoints_page.py`
* `ui/connections_page.py`

Odpowiedzialność:

* okno główne,
* zakładki,
* tabele,
* formularze boczne lub dolne,
* obsługa akcji użytkownika,
* aktualizacja widoku po zmianach.

Interfejs powinien być przede wszystkim szybki w obsłudze. Główna praca powinna odbywać się bez wyskakujących okien.

---

# 4. Dane i format JSON

JSON powinien być czytelny dla człowieka i możliwy do ręcznej edycji.

Wskazówki:

* zapisywać z wcięciem, np. `indent=2`,
* używać UTF-8,
* nie sortować pól agresywnie, aby układ był naturalny,
* trzymać dane projektu w jednym pliku `*.json`,
* zachować wersję formatu danych, np. `schema_version`.

Warto rozważyć strukturę:

```json
{
  "schema_version": 1,
  "project": {
    "name": "Sala 9.1",
    "code": "S9.1"
  },
  "cabinets": [],
  "endpoints": [],
  "connections": [],
  "settings": {
    "cabinet_types": [],
    "endpoint_types": [],
    "signal_types": [],
    "statuses": []
  }
}
```

Pole `settings` pozwoli rozszerzać listy typów bez zmiany kodu programu. Subkategorie szaf i punktów mają być edytowalne przez użytkownika z poziomu UI.

---

# 5. Identyfikatory i powiązania

Nie należy wiązać połączeń po nazwach obiektów. Połączenie powinno trzymać:

* `source_id`
* `destination_id`

Nazwy szaf i punktów powinny być tylko etykietami widocznymi dla użytkownika.

Korzyść:

* można zmienić nazwę `FB-01` na `FB-001`,
* połączenia nadal działają,
* eksport pokaże aktualną nazwę,
* generator oznaczeń użyje aktualnej nazwy.

Do `id` wystarczy `uuid4` albo prosty stabilny identyfikator generowany przy tworzeniu obiektu. UUID jest najbezpieczniejszy i prosty.

Połączenia mogą występować we wszystkich kombinacjach:

* Szafa -> Punkt
* Punkt -> Szafa
* Punkt -> Punkt
* Szafa -> Szafa

W formularzu połączenia `source_id` i `destination_id` powinny być wybierane ze wspólnej listy obiektów. Jeżeli obiekt jest wybrany jako `source`, nie powinien być dostępny jako `destination` dla tego samego połączenia.

---

# 6. Generator oznaczeń

Domyślny wzór:

```text
{PROJECT}-{FROM}-{TO}-{TYPE}-{NN}
```

Najważniejsze reguły:

* usuwać myślniki z nazw obiektów w oznaczeniu,
* zachować kod projektu,
* typ sygnału wstawiać jako tekst,
* numerację prowadzić osobno dla każdego typu sygnału w ramach projektu,
* numer dla danego typu sygnału musi być unikalny globalnie w projekcie,
* dla `quantity > 1` tworzyć wiele oznaczeń,
* szerokość numeru dobierać automatycznie do największej liczby kabli danego typu w projekcie.

Przykład:

```text
S9.1-RSC1-FB01-ETH-01
S9.1-RSC1-FB01-ETH-02
```

Reguła szerokości numeracji:

* jeżeli największy numer dla danego typu sygnału mieści się w dwóch cyfrach, stosować zapis `NN`, np. `01`, `02`, `99`,
* jeżeli dla jakiegoś typu sygnału w projekcie pojawi się liczba trzycyfrowa, np. 123 przewody ETH, cała numeracja tego typu przechodzi na zapis `NNN`, np. `001`, `002`, `123`.

Przykład dla ETH, gdy w całym projekcie są 123 przewody ETH:

```text
S9.1-RSC1-FB01-ETH-001
S9.1-RSC1-FB01-ETH-002
...
S9.1-RSC2-FB09-ETH-123
```

Ważna konsekwencja:

* generator oznaczeń powinien przeliczać oznaczenia dla całego projektu, a nie tylko dla pojedynczego połączenia,
* zmiana ilości przewodów w jednym połączeniu może zmienić szerokość numeracji dla wszystkich oznaczeń tego samego typu,
* kolejność nadawania numerów powinna wynikać z priorytetów liczbowych ustalanych przez użytkownika,
* domyślnie najwyższy priorytet ma `Cabinet` z najmniejszym numerem w nazwie,
* połączenia przypisane do takiej szafy powinny dostać najniższe numery niezależnie od tego, czy szafa występuje jako `source`, czy jako `destination`,
* połączenia bez żadnego `Cabinet` powinny być numerowane po połączeniach zawierających `Cabinet`,
* dla połączeń bez `Cabinet` kolejność powinna wynikać z najniższej nazwy obiektu typu `Endpoint` w danym połączeniu,
* każdy typ sygnału jest numerowany niezależnie.

---

# 7. Eksport XLSX

Eksport powinien tworzyć arkusz:

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

Każde wygenerowane oznaczenie powinno być osobnym wierszem.

Przykład: jeżeli połączenie ma `quantity = 3`, w XLSX powstaną 3 wiersze.

Wskazówki jakościowe:

* zamrozić pierwszy wiersz,
* dodać filtr na nagłówkach,
* dopasować szerokości kolumn,
* wyróżnić nagłówki,
* zachować prosty format bez makr,
* jeżeli wybrany plik już istnieje, zapytać użytkownika o potwierdzenie nadpisania,
* jeżeli plik nie istnieje, pozwolić użytkownikowi nadać nazwę lub skorzystać z proponowanej struktury nazwy, np. opartej o nazwę projektu.

---

# 8. Interfejs użytkownika

Główne okno:

```text
Menu
Projekt | Szafy | Punkty | Połączenia | Export
Aktywna zakładka
```

Każda zakładka powinna być oparta o tabelę oraz formularz edycji.

Zalecany układ:

* lewa lub górna część: tabela,
* prawa lub dolna część: formularz szczegółów,
* przyciski akcji blisko formularza.

Unikać:

* kreatorów,
* popupów do codziennej pracy,
* ukrywania najważniejszych funkcji,
* zbyt wielu kroków dla dodania jednego połączenia.

Najważniejsza zakładka operacyjna to `Połączenia`, ponieważ tam użytkownik będzie najczęściej pracował w terenie.

---

# 9. Styl UI

Kierunek wizualny:

* ciemny,
* techniczny,
* czytelny,
* spokojny,
* podobny nastrojem do VS Code, Q-SYS Designer i narzędzi inżynierskich.

Kolory bazowe z `PROJECT.md`:

```text
Tło:        #07111a
Panele:     #0d1a24
Obramowania:#1f3443
Tekst:      #eef8ff
Akcent:     #2b5c79
```

Wskazówki:

* tabele muszą być bardzo czytelne,
* zaznaczony wiersz powinien być wyraźny,
* formularze nie mogą wyglądać jak przypadkowe okienka systemowe,
* przyciski powinny być proste i jednoznaczne,
* statusy można później wyróżnić kolorem, ale w MVP tekst wystarczy.

---

# 10. Etapy realizacji

## Etap 1 - fundament danych

Cel:

* stworzyć modele,
* zapis JSON,
* odczyt JSON,
* przykładowy plik projektu,
* podstawowe testy ręczne.

Kryterium zakończenia:

* można utworzyć obiekt projektu w pamięci,
* zapisać go do JSON,
* odczytać go z JSON,
* dane po odczycie są takie same.

## Etap 2 - szafy i punkty

Cel:

* zakładka `Szafy`,
* zakładka `Punkty`,
* dodawanie, edycja, usuwanie,
* zapisywanie zmian w projekcie.

Kryterium zakończenia:

* użytkownik może zbudować listę szaf i punktów dla obiektu.

## Etap 3 - połączenia

Cel:

* zakładka `Połączenia`,
* wybór źródła i celu,
* wybór typu sygnału,
* ilość,
* status,
* uwagi.

Kryterium zakończenia:

* użytkownik może opisać relacje między szafą/punktem a innym punktem.

## Etap 4 - oznaczenia

Cel:

* generowanie oznaczeń dla połączeń,
* podgląd oznaczeń w UI,
* obsługa `quantity > 1`.

Kryterium zakończenia:

* po zapisaniu połączenia użytkownik widzi listę oznaczeń.

## Etap 5 - eksport

Cel:

* eksport XLSX przez `openpyxl`,
* arkusz `Lista kablowa`,
* osobny wiersz dla każdego oznaczenia.

Kryterium zakończenia:

* plik XLSX otwiera się w Excelu i zawiera pełną listę kablową.

## Etap 6 - dopracowanie aplikacji

Cel:

* skróty klawiaturowe,
* walidacja formularzy,
* poprawki stylu,
* komunikaty błędów,
* build PyInstaller.

Kryterium zakończenia:

* aplikacja jest wygodna do testów terenowych na Windows 10/11.

---

# 11. Kolejność plików do tworzenia

Najbezpieczniejsza kolejność:

1. `models.py`
2. `storage.py`
3. `naming.py`
4. `export_xlsx.py`
5. `main.py`
6. `ui/main_window.py`
7. `ui/project_page.py`
8. `ui/cabinets_page.py`
9. `ui/endpoints_page.py`
10. `ui/connections_page.py`
11. `requirements.txt`
12. `README.md`

Taka kolejność pozwala najpierw ustabilizować dane i logikę, a dopiero potem budować UI.

---

# 12. Potencjalne ryzyka

## 12.1. Zbyt skomplikowany interfejs

Ryzyko:

* aplikacja stanie się wolniejsza w obsłudze niż arkusz Excel.

Odpowiedź:

* każda główna czynność powinna być możliwa z tabeli i formularza,
* minimalizować liczbę kliknięć,
* nie dodawać kreatorów.

## 12.2. Brak stabilnych ID

Ryzyko:

* zmiana nazwy punktu popsuje połączenia.

Odpowiedź:

* od początku używać `id` w relacjach.

## 12.3. Niejasne reguły numeracji

Ryzyko:

* użytkownik może oczekiwać innego sposobu numerowania kabli.

Odpowiedź:

* numerować globalnie w ramach projektu osobno dla każdego typu sygnału,
* automatycznie dobierać szerokość numeru do największej liczby przewodów danego typu,
* utrzymać stabilną kolejność numerowania.

## 12.4. Eksport niezgodny z praktyką terenową

Ryzyko:

* kolumny będą formalnie poprawne, ale mało użyteczne.

Odpowiedź:

* po pierwszym eksporcie zrobić test na przykładowej sali,
* dopisać kolumny dopiero po realnej potrzebie.

---

# 13. Decyzje projektowe

Potwierdzone decyzje:

1. Numeracja kabli ma być unikalna globalnie w projekcie osobno dla każdego typu sygnału.
2. Szerokość numeru ma być dobierana automatycznie: `NN` dla zakresu dwucyfrowego, `NNN` gdy dany typ sygnału przekroczy 99 przewodów itd.
3. Szafy sterujące, racki, szafy elektryczne, przyłącza i urządzenia podpięte na stałe są obiektami, które mogą być końcami połączeń.
4. Połączenia mogą występować we wszystkich kombinacjach: Szafa -> Punkt, Punkt -> Szafa, Punkt -> Punkt, Szafa -> Szafa.
5. Źródło i cel połączenia mają być wybierane ze wspólnej listy obiektów.
6. Obiekt wybrany jako źródło nie powinien być dostępny jako cel tego samego połączenia.
7. Typy sygnałów, statusy i typy punktów mają być edytowalne z poziomu UI już w MVP.
8. Eksport XLSX ma pytać o potwierdzenie nadpisania istniejącego pliku.
9. Przy eksporcie nowego pliku użytkownik powinien móc podać nazwę lub skorzystać z proponowanej nazwy opartej np. o nazwę projektu.
10. W danych należy zachować dwie główne kategorie: `Cabinet` oraz `Endpoint`.
11. Subkategorie szaf i punktów mają być edytowalne przez użytkownika z poziomu UI.
12. Numeracja ma bazować na priorytetach liczbowych ustalanych przez użytkownika.
13. Domyślnie najwyższy priorytet ma `Cabinet` z najmniejszym numerem w nazwie.
14. Przy numerowaniu nie ma znaczenia, czy priorytetowa szafa jest po stronie `source`, czy `destination`.
15. Połączenia bez `Cabinet` są numerowane po połączeniach zawierających `Cabinet`.
16. Dla połączeń bez `Cabinet` kolejność wynika z najniższej nazwy obiektu typu `Endpoint` w połączeniu.
17. Priorytet liczbowy szafy ma być widoczny tylko w konfiguracji szaf, nie w tabeli połączeń.
18. W konfiguracji szaf powinien być przycisk automatycznego przeliczenia priorytetów na podstawie numerów w nazwach szaf.

Wyjaśnienie pytania o ustawialny wzór generatora:

* pytanie dotyczyło tego, czy użytkownik ma w MVP samodzielnie zmieniać szablon oznaczenia, np. `{PROJECT}-{FROM}-{TO}-{TYPE}-{NN}`,
* na ten moment przyjmujemy, że wzór pozostaje stały w MVP,
* w przyszłości można dodać edytor wzoru, jeżeli pojawi się taka potrzeba.

Otwarte pytania po aktualizacji:

Brak otwartych pytań w tej sekcji na ten moment.

---

# 14. Wskazówki na przyszłość

Możliwe rozszerzenia po MVP:

* import z XLSX,
* duplikowanie połączeń,
* szybkie filtrowanie po statusie,
* wyszukiwarka punktów,
* kolorowanie statusów,
* szablony projektów,
* historia ostatnio otwieranych plików,
* automatyczne kopie zapasowe JSON,
* walidacja brakujących pól przed eksportem,
* dodatkowe kolumny: długość kabla, trasa, kategoria, komentarz montażowy,
* ustawienia generatora oznaczeń,
* eksport PDF jako raport,
* druk etykiet w dalszej przyszłości.

Priorytet rozszerzeń powinien wynikać z realnej pracy z aplikacją na jednym lub dwóch przykładowych obiektach.

---

# 15. Zasada prowadzenia bazy wiedzy

W katalogu `baza informacji` należy zapisywać:

* plany,
* decyzje projektowe,
* notatki z rozmów,
* założenia,
* otwarte pytania,
* przyszłe pomysły,
* wnioski po testach.

Nie należy tutaj zapisywać:

* kodu programu,
* wygenerowanych plików build,
* środowiska wirtualnego,
* plików tymczasowych.

Proponowane przyszłe pliki:

* `DECYZJE.md` - zatwierdzone decyzje projektowe,
* `PYTANIA.md` - pytania otwarte przed kolejnymi etapami,
* `TESTY_RECZNE.md` - scenariusze ręcznego testowania aplikacji,
* `POMYSLY.md` - pomysły spoza MVP.
