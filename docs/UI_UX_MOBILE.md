# CableListTool - Kierunek rozwoju interfejsu mobilnego

## Cel

Obecny interfejs działa poprawnie funkcjonalnie, jednak sprawia wrażenie aplikacji desktopowej przeniesionej na telefon.

Celem nie jest przebudowa logiki aplikacji, lecz nadanie jej bardziej natywnego wyglądu Android Material 3 przy zachowaniu technicznego charakteru CableListTool.

Priorytetem jest poprawa UX oraz dopracowanie kolorystyki zgodnej z brandingiem GreenCrew.

---

# Założenia

Nie zmieniamy:

- struktury zakładek,
- logiki działania,
- układu danych,
- nazewnictwa.

Skupiamy się wyłącznie na:

- kolorach,
- odstępach,
- typografii,
- hierarchii elementów,
- wyglądzie formularzy,
- wyglądzie list.

---

# Ogólny charakter aplikacji

Aplikacja ma przypominać profesjonalne narzędzie terenowe używane przez techników.

Inspiracje:

- profesjonalne mierniki,
- aplikacje serwisowe,
- oprogramowanie diagnostyczne,
- urządzenia Fluke,
- etykieciarki,
- dokumentację powykonawczą.

Nie wzorować się na:

- aplikacjach społecznościowych,
- komunikatorach,
- aplikacjach lifestyle,
- dashboardach biznesowych.

---

# Kolorystyka

Priorytetem jest poprawne wykorzystanie kolorów z brandingu GreenCrew.

Kolor główny:

#00C853

Akcenty:

#00E676
#00B248

Tło:

#000000

Powierzchnie:

ciemna zieleń zamiast czystej czerni.

Tekst:

biały

Tekst pomocniczy:

jasnoszary

Nie używać:

- niebieskich akcentów,
- czerwonych elementów,
- przypadkowych odcieni zieleni.

Cała aplikacja powinna wyglądać spójnie z pozostałymi narzędziami GreenCrew Tools.

---

# Górny pasek

Obecny układ jest poprawny.

Drobne zmiany:

- większy odstęp pomiędzy nazwą projektu a kodem projektu,
- kod projektu mniejszą czcionką,
- ikony po prawej wyrównane optycznie.

Nie należy dodawać kolejnych ikon.

---

# Dolna nawigacja

Aktualna nawigacja jest dobra.

Nie należy zwiększać podświetlenia aktywnej zakładki.

Obecny "pill" jest wystarczający.

Można jedynie dopracować:

- kolor aktywnego tła,
- kolor aktywnej ikony,
- animację przejścia.

---

# Formularze

To największy obszar wymagający poprawy.

## Odstępy

Zwiększyć pionowe odstępy pomiędzy polami.

Nie upychać formularza.

Pozostawić więcej "powietrza".

---

## Karty

Zmniejszyć wizualną wagę kart.

Obecnie karta + obramowanie + outline pól tworzą zbyt wiele warstw.

Karta powinna być subtelnym kontenerem.

---

## Pola

Wszystkie pola powinny mieć:

- jednakową wysokość,
- jednakowe promienie zaokrągleń,
- jednakowe odstępy.

Outline powinien być subtelniejszy.

Focus powinien być wyraźniejszy.

---

## Przyciski

Przycisk główny:

- pełna szerokość,
- mocny zielony kolor.

Przycisk usuwania:

- wyłącznie outline,
- bez mocnego kontrastu.

---

# Listy

Listy są obecnie bardzo surowe.

Docelowo każdy rekord powinien przypominać niewielką kartę.

Przykład:

Nazwa

Typ

Lokalizacja

status

zamiast pojedynczego wiersza tabeli.

Ma to być czytelne również podczas pracy w terenie.

---

# Ekran Projekt

Sekcja "Słowniki i reguły nazw"

Obecnie działa poprawnie.

Można poprawić:

- większe odstępy,
- bardziej widoczne nagłówki sekcji,
- delikatniejsze separatory.

---

# Ekran Szafy

Priorytet:

lepsze wizualne oddzielenie formularza od listy istniejących szaf.

---

# Ekran Punkty

Analogicznie do Szaf.

---

# Ekran Kable

Najbardziej złożony ekran.

Należy zadbać o:

- czytelność pól wyboru,
- większe odstępy,
- wyraźniejsze sekcje formularza.

Nie należy przeładowywać kolorami.

---

# Ekran Eksport

To obecnie najbardziej czytelny ekran.

Jedynie:

- lepsze wykorzystanie pustej przestrzeni,
- bardziej widoczny komunikat przy braku danych,
- mocniejszy aktywny przycisk eksportu.

---

# Typografia

Hierarchia powinna być bardziej wyraźna.

Nagłówek ekranu:

duży

Nagłówki kart:

średnie

Etykiety pól:

małe

Tekst pomocniczy:

najmniejszy

Nie stosować wielu różnych rozmiarów.

---

# Ikony

Używać wyłącznie ikon Material.

Nie mieszać stylów.

Nie stosować ozdobnych ikon.

---

# Animacje

Subtelne.

Preferowane:

- Fade
- Scale
- AnimatedContainer

Unikać:

- efektów bounce,
- dużych animacji,
- przesuwania całych ekranów.

---

# Responsywność

Interfejs ma działać poprawnie na:

- telefony 6"
- telefony 6.7"
- tablety
- Fold

Nie projektować wyłącznie pod emulator Pixel.

---

# Najważniejszy cel

Po otwarciu aplikacji użytkownik powinien odnieść wrażenie:

"To profesjonalne narzędzie stworzone do pracy w terenie."

Nie:

"To formularz przeniesiony z aplikacji desktopowej."

Interfejs powinien być prosty, czytelny, nowoczesny i zgodny z identyfikacją wizualną GreenCrew.

# Edytor słowników i reguł nazw

Słowniki nie są listą elementów projektu. Są konfiguracją generatora nazw.

Obecny zapis:

Rack=RACK-N

oznacza:

- `Rack` — nazwa obiektu używana w aplikacji,
- `RACK-N` — wzór oznaczenia generowanego do listy kablowej,
- `RACK` — prefiks typu obiektu,
- `N` — miejsce numeracji,
- liczba znaków `N` określa minimalną liczbę cyfr.

Przykłady:

- `RACK-N` generuje `RACK-1`, `RACK-2`, `RACK-3`
- `FB-NN` generuje `FB-01`, `FB-02`, `FB-03`
- `DEV-NNN` generuje `DEV-001`, `DEV-002`, `DEV-003`

Na mobile nie używać dużego pola tekstowego z wieloma liniami.

Zamiast tego zastosować listę reguł:

- nazwa obiektu,
- wzór oznaczenia,
- podgląd przykładowej wygenerowanej nazwy.

Przykład widoku:

Szafy

Szafa sterująca
RSC-N → RSC-1

Rack
RACK-N → RACK-1

Szafa elektryczna
EL-N → EL-1

Każda reguła powinna być edytowalna osobno.

Formularz edycji reguły:

- Nazwa w aplikacji
- Wzór oznaczenia
- Podgląd
- Zapisz

Przy polu wzoru pokazać krótką legendę:

- `N` — numer bez zer wiodących
- `NN` — numer minimum dwucyfrowy
- `NNN` — numer minimum trzycyfrowy

Nie usuwać obsługi istniejącego formatu tekstowego. Format `Nazwa=Wzór` może pozostać jako format zapisu/importu, ale nie powinien być głównym sposobem edycji na mobile.
