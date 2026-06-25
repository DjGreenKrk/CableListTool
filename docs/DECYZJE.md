# DECYZJE.md

# CableListTool - decyzje projektowe

Ten dokument zbiera zatwierdzone decyzje, które wynikają z rozmów i doprecyzowań. Ma pomagać utrzymać spójność projektu przy kolejnych etapach implementacji.

---

# 2026-06-21

## Numeracja oznaczeń kablowych

Numeracja ma być unikalna globalnie w projekcie osobno dla każdego typu sygnału.

Przykład:

* ETH ma własną numerację,
* DMX ma własną numerację,
* DALI ma własną numerację.

Szerokość numeru ma być dobierana automatycznie:

* jeżeli największa liczba przewodów danego typu mieści się w dwóch cyfrach, stosowany jest zapis `NN`, np. `01`, `02`, `99`,
* jeżeli dany typ sygnału przekroczy 99 przewodów, cała numeracja tego typu przechodzi na zapis trzycyfrowy `NNN`, np. `001`, `002`, `123`.

Konsekwencja techniczna:

* generator oznaczeń powinien przeliczać oznaczenia w kontekście całego projektu,
* numeracja powinna być stabilna i przewidywalna.

## Obiekty połączeń

Końcami połączeń mogą być różne typy obiektów:

* szafy sterujące,
* racki,
* szafy elektryczne,
* przyłącza,
* urządzenia podpięte na stałe, np. oprawy oświetleniowe, panele sterujące, projektory.

Połączenia mogą występować we wszystkich kombinacjach:

* Szafa -> Punkt,
* Punkt -> Szafa,
* Punkt -> Punkt,
* Szafa -> Szafa.

W UI połączeń źródło i cel powinny być wybierane ze wspólnej listy obiektów.

Jeżeli obiekt jest wybrany jako źródło, nie powinien pojawiać się jako możliwy cel w tym samym połączeniu.

Połączenie może mieć nieznany koniec `Dokąd`. Jest to potrzebne przy inwentaryzacji, gdy wiadomo, że np. w `RSC-1` jest 14 przewodów ETH, ale część końców trzeba dopiero znaleźć.

Reguły dla nieznanego końca:

* `source` jest wymagane,
* `destination` może być puste i oznacza `Nieznane`,
* oznaczenie używa tokenu `NIEZNANE`,
* domyślny status takiego połączenia to `Niezidentyfikowany`,
* później użytkownik może uzupełnić `Dokąd` bez tworzenia połączenia od nowa.

W danych należy zachować dwie główne kategorie:

* `Cabinet` - szafy sterujące, racki, szafy elektryczne i podobne punkty centralne,
* `Endpoint` - przyłącza, urządzenia, oprawy, panele, projektory i inne punkty podpięte na stałe.

Mimo rozdzielenia danych na dwie kategorie, formularz połączeń powinien pokazywać wspólną listę `Cabinet + Endpoint`.

Subkategorie szaf i punktów mają być edytowalne przez użytkownika.

## Pojedynczy przewód jako wiersz

Po teście pierwszej sali zmieniono założenie edycji połączeń:

* tabela `Połączenia` powinna pokazywać każdy przewód jako osobny wiersz,
* kolumna `Oznaczenie` ma być częścią głównej tabeli połączeń,
* dodawanie wielu przewodów przez `Ilość nowych` tworzy wiele osobnych wierszy,
* stary zapis `quantity > 1` jest tylko formatem zgodności i po otwarciu projektu powinien zostać rozbity na pojedyncze przewody,
* osobna sekcja `Oznaczenia` w formularzu nie jest już potrzebna.

Uzasadnienie:

* znaleziony przewód musi dać się edytować, usunąć, odwrócić lub połączyć z innym wierszem bez manipulowania całą grupą.

## Łączenie i odwracanie przewodów

Gdy dwa niezidentyfikowane przewody okażą się tym samym fizycznym przewodem, użytkownik powinien móc zaznaczyć oba wiersze i połączyć je w jeden.

Przykład:

* `ETH-01`: `RSC-1 -> Nieznane`,
* `ETH-14`: `Proj-1 -> Nieznane`,
* po połączeniu zostaje jeden przewód `RSC-1 -> Proj-1`.

Użytkownik powinien mieć też opcję odwrócenia kierunku dla wybranych przewodów, np. z `WB-1 -> RSC-1` na `RSC-1 -> WB-1`.

## Trwałość numeru po stronie szafy

Numer przewodu powiązany z szafą nie może zmieniać się po późniejszym uzupełnieniu drugiego końca.

Uzasadnienie:

* numer może odpowiadać fizycznemu gniazdu w patchpanelu lub pozycji w szafie,
* jeżeli w `RSC-1` przewód jest oznaczony jako `ETH-04`, to po znalezieniu końca przy projektorze nadal musi pozostać `ETH-04`,
* dopuszczalne jest, aby numery przewodów bez udziału szafy zmieniały się po uzupełnieniach i sortowaniu.

Reguły:

* przewody zawierające `Cabinet` dostają trwałe pole `cable_number`,
* przy łączeniu `Cabinet -> Nieznane` z `Endpoint -> Nieznane` zostaje numer strony szafowej,
* przy łączeniu dwóch szaf zostaje numer strony szafy o wyższym priorytecie,
* oznaczenie może zmienić część `FROM/TO`, ale nie numer końcowy.

Przykład:

```text
S4.2-RSC1-NIEZNANE-ETH-04
```

po znalezieniu projektora staje się:

```text
S4.2-RSC1-Proj1-ETH-04
```

## Priorytety numeracji

Numeracja oznaczeń ma bazować na priorytetach liczbowych ustalanych przez użytkownika.

Domyślna reguła:

* `Cabinet` z najmniejszym numerem w nazwie ma najwyższy priorytet,
* jego połączenia dostają najniższe numery,
* nie ma znaczenia, czy ta szafa występuje w połączeniu jako `source`, czy jako `destination`,
* połączenia bez żadnego `Cabinet` są numerowane po połączeniach zawierających `Cabinet`,
* dla połączeń bez `Cabinet` kolejność wynika z najniższej nazwy obiektu typu `Endpoint` w danym połączeniu,
* priorytet liczbowy szafy jest widoczny tylko w konfiguracji szaf,
* tabela połączeń nie pokazuje priorytetu jako informacji pomocniczej,
* konfiguracja szaf powinna mieć przycisk automatycznego przeliczenia priorytetów na podstawie numerów w nazwach szaf,
* każdy typ sygnału nadal jest numerowany niezależnie.

Przykład interpretacji:

* jeżeli `RSC-1` i `RSC-2` mają połączenia ETH, najpierw numerowane są połączenia powiązane z `RSC-1`,
* połączenia powiązane z `RSC-2` dostają dalsze numery ETH.
* połączenie `Floorbox <-> Projektor`, bez udziału szafy, dostaje kolejny numer dopiero po połączeniach z szafami.

## Listy słownikowe

Typy sygnałów, statusy i typy punktów mają być edytowalne z poziomu UI już w MVP.

## Dodawanie szaf i punktów

Po zapisaniu nowej szafy lub punktu formularz nie powinien pozostawać w trybie edycji dopiero utworzonego rekordu.

Zasady:

* kliknięcie `Zapisz` dla nowego elementu tworzy rekord i od razu wraca do trybu dodawania,
* typ i lokalizacja zostają w formularzu, aby szybciej dodawać podobne elementy,
* nazwa przechodzi na następną sugerowaną wartość,
* opis jest czyszczony,
* pole `Ilość nowych` pozwala dodać wiele elementów naraz,
* jeżeli nazwa zawiera numer, program nada kolejne numery, np. `RSC-1`, `RSC-2`, `RSC-3`,
* jeżeli numer ma zera wiodące, zostają zachowane, np. `FB-01`, `FB-02`, `FB-03`,
* jeżeli nazwa nie zawiera numeru, program dodaje suffix `-1`, `-2`, `-3`.

## Domyślne nazwy według typu

Jeżeli użytkownik zostawi puste pole `Nazwa`, aplikacja powinna sama nadać nazwę na podstawie wybranego typu.

Zasady:

* reguły nazw są edytowane w zakładce `Projekt`,
* format reguły to `Typ=Wzór`,
* dla punktów można dopisać priorytet po znaku `|`, czyli `Typ=Wzór|Priorytet`,
* wzór może zawierać `N` jako miejsce numeru,
* liczba znaków `N` określa szerokość numeru,
* aplikacja szuka najwyższego istniejącego numeru dla danego wzoru i nadaje kolejny.

Przykłady:

```text
Szafa sterująca=RSC-N
Floorbox=FB-NN
Panel=TSC-N|10
Projektor=PROJ-N|20
```

Efekt:

* pusta nazwa + `Szafa sterująca` -> `RSC-1`,
* pusta nazwa + `Floorbox` -> `FB-01`,
* pusta nazwa + `Panel` -> `TSC-1`,
* jeśli istnieją `FB-01` i `FB-02`, kolejny floorbox dostanie `FB-03`.

## Sortowanie list

Listy w aplikacji powinny używać sortowania naturalnego, a nie zwykłego tekstowego.

Zasady:

* `RSC-2` powinno być przed `RSC-10`,
* `TSC-3` dodane po czasie powinno pojawić się między `TSC-2` i `TSC-10`,
* tabele szaf i punktów mają być sortowane po nazwie,
* pola wyboru `Skąd` i `Dokąd` mają pokazywać najpierw posortowane szafy, potem posortowane punkty,
* tabela połączeń ma zachować sortowanie zgodne z generatorami oznaczeń i naturalnym sortowaniem nazw obiektów.

## Priorytety typów punktów

Punkty mogą mieć priorytet wynikający z typu punktu.

Zasady:

* priorytety szaf są nadrzędne wobec priorytetów punktów,
* punkty mają priorytety tylko poniżej szaf,
* priorytet dotyczy typu punktu, np. `Panel=TSC-N|10`, `Projektor=PROJ-N|20`,
* niższy numer priorytetu oznacza wcześniejszą kolejność i niższe numery kabli,
* typ punktu bez wpisanego priorytetu trafia za typami z priorytetem,
* priorytety typów punktów są edytowane w zakładce `Projekt` w tym samym polu co reguły nazw,
* format to `Typ=Wzór|Priorytet`.

Przykład:

```text
Panel=TSC-N|10
Projektor=PROJ-N|20
```

Wtedy przewody do paneli będą numerowane przed przewodami do projektorów, o ile nie decyduje nadrzędna reguła szafy.

## Kody eksportu i priorytety typów sygnałów

Typy sygnałów mogą mieć opcjonalny kod eksportu i priorytet.

Zasady:

* format w zakładce `Projekt` to `Typ=Kod eksportu|Priorytet`,
* kod eksportu jest opcjonalny,
* priorytet jest opcjonalny,
* sam wpis `ETH` nadal jest poprawny,
* jeżeli kod eksportu istnieje, aplikacja używa go w oznaczeniu i eksporcie XLSX,
* jeżeli kodu eksportu nie ma, aplikacja używa nazwy typu sygnału,
* niższy numer priorytetu oznacza wcześniejszą kolejność typu sygnału w generatorze i tabeli połączeń,
* numeracja przewodów nadal jest niezależna dla każdego typu sygnału.

Przykład:

```text
Audio=A|10
DMX=DMX|20
DALI=DL|30
HDMI
```

## Eksport XLSX

Jeżeli wybrany plik eksportu już istnieje, aplikacja powinna zapytać o potwierdzenie nadpisania.

Jeżeli plik nie istnieje, użytkownik powinien mieć możliwość podania nazwy. Aplikacja może proponować nazwę opartą o nazwę projektu.

## Wzór generatora oznaczeń

Pytanie o ustawialny wzór oznaczeń oznaczało możliwość zmiany szablonu, np.:

```text
{PROJECT}-{FROM}-{TO}-{TYPE}-{NN}
```

Na MVP przyjmujemy stały wzór oznaczenia. Edytor wzoru może być rozszerzeniem w przyszłości.
