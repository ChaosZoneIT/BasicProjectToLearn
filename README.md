# Symulacja Środowiska Produkcyjnego w Kontenerach

## ⚠️ Dokumentacja w wersji rozwojowej

Ten dokument jest w trakcie tworzenia i może zawierać niekompletne informacje, błędy lub nieaktualne opisy.

## Opis projektu

Projekt ma na celu **symulację konfiguracji środowiska produkcyjnego** w małej organizacji. Głównym celem jest nauka konfiguracji narzędzi od podstaw — początkowo za pomocą skryptów, a w przyszłości być może z wykorzystaniem bardziej zaawansowanych narzędzi (np. Ansible, Terraform, itp.).

Cała struktura systemu opiera się na kontenerach Docker, które **symulują maszyny/serwery w organizacji**, uruchamiając różne narzędzia i usługi. Choć kontenery są mniej zasobożerne niż tradycyjne maszyny wirtualne i łatwiej jest uruchomić cały projekt, mogą występować pewne wyzwania związane z ich użytkowaniem, takie jak problemy z danymi po restarcie, podpinaniem volumenów czy innymi kwestiami związanymi z konfiguracją i zarządzaniem danymi.

---

## Projekt: Infrastruktura do CI/CD

Projekt składa się z kilku etapów, a cała struktura jest budowana za pomocą **Docker Compose**, w którym zdefiniowana jest sieć oraz serwisy odpowiadające za usługi, narzędzia i "serwery". Ta część projektu będzie się rozrastała wraz z kolejnymi zmianami i dodatkami do infrastruktury.

### 1. Nginx jako Reverse Proxy (TODO)

Nginx działa jako **reverse proxy**, które przekierowuje ruch z różnych domen do odpowiednich serwisów uruchomionych w kontenerach Docker. Dzięki tej konfiguracji możliwe jest udostępnienie różnych aplikacji na tym samym porcie, ale różnymi domenami. Nginx na podstawie domeny przekierowuje ruch do odpowiedniego serwisu, działającego w środowisku Docker Compose.

### 2. GitLab CE

- Oparty na systemie **Ubuntu 24.04**
- Dostępny przez **HTTPS** (z lokalnym, samopodpisanym certyfikatem SSL)
- **Zablokowana rejestracja użytkowników** – tylko administrator może tworzyć konta
- Wymagana **weryfikacja adresu e-mail** przed uzyskaniem dostępu do repozytoriów
- Planowana struktura grup/projektów:
  - Dwa zespoły developerskie (Dev)
  - Jeden zespół DevOps
  - Testerzy (docelowo 2 osoby, z możliwością uruchamiania własnych środowisk testowych)
  - Osoba odpowiedzialna za wdrożenia na środowisko produkcyjne

### 3. Mock serwer SMTP (MailHog)

- Symuluje odbiór wiadomości e-mail:
  - rejestracja / aktywacja konta
  - powiadomienia z pipeline'ów
  - inne systemowe powiadomienia z GitLaba

### 4. Przykładowy projekt (TODO)

Repozytorium będzie zawierać przykładowy projekt:

- Proste **REST API** z jedną metodą `GET`
- Dwa **testy uruchamiane w CI/CD**:
  - Test jednostkowy (unit test)
  - Test API (imitacja testu integracyjnego)

Testy będą uruchamiane automatycznie w pipeline GitLaba jako demonstracja działania procesu CI/CD.

---


## 📁 Struktura katalogów

``` plaintext
.
├── Gitlab/
│   ├── config/
│   │   ├── after-start/                      # skrypty które muszą być uruchomione po starcie GitLab'a
│   │   └── befor-start/                      # skrypty które muszą być uruchomione przed starcie GitLab'a, np modyfikujące /ets/gitlab/gitlab.rb
│   ├── configure-after-start.sh              # Skrypt sprawdzający gotowość GitLaba i uruchamiający konfigurację z katalogu /gitlab-config/after (na dokerze)
│   ├── configure-befor-start.sh              # Skrypt sprawdzający gotowość GitLaba i uruchamiający konfigurację z katalogu /gitlab-config/befor (na dokerze)
│   ├── Dockerfile                            # Obraz bazujący na Ubuntu 24 z preinstalowanym GitLabem
│   └── startGitLab.sh                        # Skrypt startujący GitLaba oraz konfigurujący całe srodowiski
├── storage/
│   └── gitlab/                               # Wolumeny powiązane z GitLabem (logi, dane, konfiguracja, itp.)
│       ├── config/                           # podmontowany folder z dockera (/etc/gitlab)
│       ├── config-after-start/               # podmontowany katalog do kontenera (/gitlab-config/after). Do niego należy skopiować skrypty konfigurujące które powinny się uruchomić po starcie gitLaba
│       │   └── .gitkeep                      # plik aby dało się wysłać folder do github
│       ├── config-after-start-done          # podmontowany folder z dockera (/gitlab-config/after-done) Przechowujący wykonane skrypty aby nie dublować konfiguracji przy kolejnych startach kontenera która jest już zapisana np w redisie
│       ├── config-before-start/              # podmontowany katalog do kontenera (/gitlab-config/before). Do niego należy skopiować skrypty konfigurujące które powinny się uruchomić przed startem gitLaba (np ustawiające dane w /ets/gitlab/gitlab.rb)
│       │   └── .gitkeep                      # plik aby dało się wysłać folder do github
│       ├── config-before-start-done          # podmontowany folder z dockera (/gitlab-config/before-done) Przechowujący wykonane skrypty aby nie dublować konfiguracji przy kolejnych startach kontenera która jest już zapisana np w pliku /etc/gitlab/gitlab.rb
│       ├── data                              # podmontowany folder z dockera (/var/opt/gitlab)
│       └── logs                              # podmontowany folder z dockera (/var/log/gitlab)
├── tools/                                    # Narzędzia do konfiguracji
│   └── gitlab/                               # dla gitLaba
├── .gitignore
├── docker-compose.yml                        # Główny plik uruchamiający środowisko
└── Makefile                                  # Automatyzuje zadania konfiguracyjne (zawarte w tools/)
└── README.md                                 # Dokumentacja 

```


📌 **Uwaga:**  
Folder `storage/gitlab` jest zamontowany jako wolumen w `docker-compose.yml`, co pozwala zachować dane (repozytoria, użytkownicy, konfiguracja, logi) pomiędzy restartami kontenera.

## 🚀 Uruchamianie projektu

Projekt jest przygotowywany i testowany na systemie **Linux**.

### 1. 🧭 Wymagane mapowanie w `/etc/hosts`

Aby dostęp do GitLaba po nazwie domenowej działał lokalnie, należy dodać wpis do pliku `/etc/hosts`:

``` bash
sudo nano /etc/hosts
```

``` bash
172.0.10.3 gitlab.company.local
```

📌 **Adres IP** odpowiada ustawieniu statycznego IP kontenera w pliku `docker-compose.yml`.

### 2. 🛠️ Budowanie i uruchomienie projektu

W katalogu głównym projektu (pierwsze uruchomienie po pobraniu):

#### 2.1 Kopiujemy skrypty konfiguracyjne za pomocą polecenia

``` bash
make gitLab-copy-configuration-before-start
make gitLab-copy-configuration-after-start
```

lub

``` bash
./tools/gitlab/copy-config-before.sh
./tools/gitlab/copy-config-after.sh
```

Powyższe polecenia kopiują(na hoscie) przykładową konfigurację z

- GitLab/config/after-satrt
- GitLab/config/before-satrt

do (który jest podmontowany do kontenera):

- store/gitlab/config-after-start
- store/gitlab/config-before-start

Skrypty są uniwersalne i powinny zadziałać na każdym środowisku na którym chce sie skonfigurować GitLaba, dlatego są w sekcji GirLab.

#### 2.2 Budujemy projekt

``` bash
docker compose build
```

#### 2.3 Uruchamiamy

``` bash
docker compose up -d
```

#### 2.3.1 🕐 Czekanie na pełne uruchomienie

GitLab uruchamia się przez dłuższy czas. Choć interfejs może być wcześniej dostępny, konfiguracja wykonywana przez skrypty startowe może jeszcze trwać. Z tego względu:

✅ **Zaleca się korzystanie z systemu dopiero po wykonaniu wszystkich skryptów inicjalizacyjnych.**  
Sprawdź, czy katalogi `config-after-start` i `config-after-start-done` mają identyczną zawartość.

Po poprawnym uruchomieniu (co trochę trwa) serwis GitLaba powinien być dostępny pod adresem:

``` bash
https://gitlab.company.local
```

📌 Pamiętaj: jest używany lokalny certyfikat SSL, więc przeglądarka może zgłaszać ostrzeżenie.

### 3. 🧹 Czyszczenie/przywracanie projektu do pierwotnej postaci (np w celu sprawdzenia nowej autokonfiguracji)

### 3.1 Porządek z kontenerami i obrazami

``` bash
docker compose down                     # jak nie był jeszcze zatrzymany
docker ps -a --filter "name=GitLabCE"   # czy przypadkiem nie został kontener
docker ps -a --filter "name=Mailhog"    # czy przypadkiem nie został kontener
docker rm GitLabCE Mailhog              # usunięcie kontenerów jakby zostały
docker rmi gitlab-ce-ubuntu:latest      # usunięcie obrazu
docker rmi mailhog/mailhog:latest       # usunięcie obrazu
```

### 3.1 Porządek z volumenami i konfiguracją (z głownego katalogu projektu)

Usuwa wszystko z storage/gitlab i przywracastan projektu który można budować i uruchamiać (można przeskoczyć do punku [2.2 Budujemy projekt](#22-budujemy-projekt))

``` bash
make gitLab
# lub pojedyńco uruchamiać w takiej kolejności:
./tools/gitlab/clean-storage.sh
./tools/gitlab/clean-before-config.sh
./tools/gitlab/clean-after-config.sh
./tools/gitlab/copy-config-before.sh
./tools/gitlab/copy-config-after.sh
```

### 3.2 pojedyńcze porządki (z głownego katalogu projektu)

### 3.2.1 Usuwa zawartość storage/gitlab/ poza konfiguracją

Przy starcie projektu się wykona konfiguracja ponieważ zostały tylko foldery config-after-satrt i config-before-start (można wrócić do [2.2 Budujemy projekt](#22-budujemy-projekt))

``` bash
make gitLab-clean-storage
# lub 
./tools/gitlab/clean-storage.sh
```

### 3.2.2 Usuwa zawartość konfiguracji before/after

Usuwa konfigurację którą należy wykonać (usuwa tylko z katalogu który jest podmontowany do dockera). Zostawia tylko plik .gitkeep (ten który jest również w repozytorium przy pobieraniu projektu)

``` bash
make gitLab-clean-configuration-before-start
make gitLab-clean-configuration-after-start
# lub 
./tools/gitlab/clean-before-config.sh
./tools/gitlab/clean-after-config.sh
```

📌 Pamiętaj: Samo usnięcie z tego katalogu ma mały sens ponieważ cały czas zostaje folder z wykonanymi skryptami i jak się nawet je ponownie wrzuci to i tak nie zostaną wykonane przy starcie kntenera.

### 4. 🔐 Korzystanie z projektu

#### 📥 Hasło do konta root

Sprawdź hasło w jeden z dwóch sposobów:

🔎 **Z poziomu kontenera**:

``` bash
docker compose exec -it gitlab_server cat /etc/gitlab/initial_root_password
```

📁 **Z poziomu hosta**:

``` bash
cat ./storage/gitlab/config/initial_root_password
```

📌 **Uwaga**: Plik ten jest automatycznie usuwany po pierwszym `gitlab-ctl reconfigure` lub po 24 godzinach.

---

## 🧩 Moduł: GitLab

### 📌 Podstawowe informacje

- **Nazwa kontenera:** `gitlab_server`
- **Nazwa obrazu:** `gitlab-ce-ubuntu`
- **IP:** `172.0.10.3`  
- **Domena:** `gitlab.company.local` *(musi być zmapowana w pliku `/etc/hosts`)*  
- **Porty wystawione przez kontener:** `80`, `443`, `22`  
- **Certyfikat SSL:** generowany automatycznie dla `gitlab.company.local`  
- **Konfiguracja:** modyfikacja pliku `gitlab.rb` w czasie budowania obrazu (będzie zastąpione przez skrypt), podczas stary nadpisanie konfiguracji smtp, po uruchomieniu skrypty konfigurujące aplikację (np dane przechowywane w redisie)

---

### 📁 Struktura katalogów i konfiguracji

GitLab działa z trzema głównymi katalogami konfiguracyjnymi:

#### 1. `/startScript`(w kontenerze) → `$BASE_SCRIPTS_DIR`(zmienna)

- Zawiera plik `startGitLab.sh`
- Jest kopiowany z hosta i inicjalizowany przy starcie kontenera
- Odpowiada za:
  - Uruchomienie usług systemowych (np. `gitlab-ctl`)
  - Skopiowanie konfiguracji `gitlab.rb` (ze względu na nadpisanie wolumenem)
  - Konfiguracja systemy przed startem np. modyfikacja pliku `gitlab.rb` (plik: configure-before-start.sh)
  - Wykonanie `gitlab-ctl reconfigure`
  - Konfiguracja systemy dla której jest potrzebny uruchomiony GitLab (plik: configure-after-start.sh)

#### 2. `/gitlab-config/before` → `$CONFIGURE_BEFORE_START`

- Katalog należy zasilić np poleceniem

``` bash
     make gitLab-copy-configuration-before-start
     lub
    ./tools/gitlab/copy-config-before.sh
```

- Zawiera **bazowe skrypty konfiguracyjne** które należy uruchomić przed startem GitLaba
- Montowany z hosta z katalogu: `./storage/gitlab/config-before-start/`
- Skrypty w tym folderze:
  - Wykonywane tylko jeśli **nie zostały wcześniej uruchomione**
  - Wymagają unikalnej nazwy i numerowania (`01_`, `02_` itd.)
  - Pozwalają przetrwać restart kontenera bez utraty konfiguracji

#### 3. `/gitlab-config/before-done` → `$CONFIGURE_BEFORE_START_DONE`

- Zawiera **skrypty, które zostały już wykonane**
- Automatycznie uzuełniane po wykonaniu skryptu
- Montowany z hosta z katalogu: `./storage/gitlab/config-before-start-done/`
- Pliki w tym katalogu:
  - Pomijane przy kolejnym uruchamianiu
  - Pozwalają na zachowanie stanu konfiguracji nawet po restarcie kontenera

#### 4. `/gitlab-config/after` → `$CONFIGURE_AFTER_START`

- Katalog należy zasilić np poleceniem

``` bash
     make gitLab-copy-configuration-after-start
     lub
    ./tools/gitlab/copy-config-after.sh
```

- Zawiera **bazowe skrypty konfiguracyjne** które należy uruchomić po startem GitLaba
- Montowany z hosta z katalogu: `./storage/gitlab/config-after-start/`
- Skrypty w tym folderze:
  - Wykonywane tylko jeśli **nie zostały wcześniej uruchomione**
  - Wymagają unikalnej nazwy i numerowania (`01_`, `02_` itd.)
  - Pozwalają przetrwać restart kontenera bez utraty konfiguracji

#### 5. `/gitlab-config/after-done` → `$CONFIGURE_AFTER_START_DONE`

- Zawiera **skrypty, które zostały już wykonane**
- Automatycznie uzuełniane po wykonaniu skryptu
- Montowany z hosta z katalogu: `./storage/gitlab/config-after-start-done/`
- Pliki w tym katalogu:
  - Pomijane przy kolejnym uruchamianiu
  - Pozwalają na zachowanie stanu konfiguracji nawet po restarcie kontenera

---

### ⚙️ Skrypty konfiguracyjne

#### `startGitLab.sh`

Kroki realizowane przez skrypt:

1. Uruchamia wymagane usługi systemowe (`gitlab-ctl`)
2. Kopiuje plik `gitlab.rb` z lokalizacji tymczasowej (ze względu na montowanie katalogu `/etc/gitlab`)
3. Uruchamia `configure-before-start.sh`
4. Uruchamia `gitlab-ctl reconfigure`
5. Uruchamia `configure-after-start.sh`

#### `configure-before-start.sh`

Odpowiada za:

1. Uruchomienie skryptów z katalogu `./storage/gitlab/config-before-start/`:
   - W kolejności alfabetycznej
   - Tylko jeśli plik **nie istnieje** w `./storage/gitlab/config-before-start-done/`
   - Po wykonaniu pliku, jego kopia trafia do `./storage/gitlab/config-before-start-done/`

#### `configure-after-start.sh`

Odpowiada za:

1. Sprawdzenie, czy GitLab się uruchomił:
   - Monitorowanie usługi `sidekiq` (jedna z ostatnich usług)
   - Sprawdzenie dostępności portu `443`
   - Sprawdzenie odpowiedzi HTTP `200`
2. Uruchomienie skryptów z katalogu `./storage/gitlab/config-after-start/`:
   - W kolejności alfabetycznej
   - Tylko jeśli plik **nie istnieje** w `./storage/gitlab/config-after-start-done/`
   - Po wykonaniu pliku, jego kopia trafia do `./storage/gitlab/config-after-start-done/`

---

### 📝 Dostępne Skrypty

Projekt bazowo posiada kilka skryptów do konfiguracji GitLaba, w miarę rozwoju projektu będą one uzupełniane gdy zajdzie taka potrzeba lub w celach szkoleniowych

#### Konfiguracje przed uruchomieniem GitLaba

##### [TODO - ta konfiguracja jeszcze jest w Dockerfile] Ustawienie `external_url' - 01_set_external_url.sh

Opis:
Zmienne: w pliku .conf

- lista które są wykorzystywane

##### [TODO - ta konfiguracja jeszcze jest w Dockerfile] Wygenerowanie i ustawienie certyfikatu ssl - 02_generate_and_configurate_ssl.sh

Opis:
Zmienne: katalog: 02_generate_and_configurate_ssl

- lista zmiennych i ich opis

##### Ustawienie smtp - 03_configure_smtp.sh

Opis:
Zmienne: katalog: 03_configure_smtp

- lista zmiennych i ich opis

#### Konfiguracje po uruchomieniem GitLaba

##### Wyłączenie rejestracji - 01_disable_singup.sh

Opis: Konta użytkownika są zakłądane przez administratora poniewaz jest to prywatne repozytorium
Zmienne: ??

- lista zmiennych i ich opis ??

##### Wymagane potwierdzenie emailem podczas rejestracji - 02_required_confirm_email.sh

Opis: po założeniu konta jest wymagane potwierdzenie przez otrzymany email
Zmienne: ??

- lista zmiennych i ich opis ??

##### Widoczność repozytoriów - 03_visible_repository.sh

Opis: Repozytorium może przechowywać tylko prywatnr repozytoria więc dostępne tylko dla zalogowanych ...
Zmienne: ??

- lista zmiennych i ich opis ??

### ➕ Dodawanie własnych skryptów które mają się wykonać przed lub po starcie GitLaba

Aby dodać własny skrypt konfiguracyjny:

XXXXX jest zależne czy skrypt ma się wykonać przed startem czy po pełnym uduchomieniu GitLaba, powinien przyjać wartość `before` lub `after`

1. Umieść go w katalogu na hoście: `./storage/gitlab/config-XXXXX-start/`
2. Nazwij plik zgodnie z formatem: `XX_nazwa.sh`, gdzie XX to pierwszy wolny numer np. `04_add_runner.sh`
3. Jeżeli skrypt korzysta z .config, .env lub innych plików czy folderów umieść je w folderze o nazwie `XX_nazwa` gdzie XX jest tym samym numerem co numer skryptu z powyższego punktu np `04_addrunner`
4. Uruchom ponownie kontener:
   docker compose restart gitlab_server
5. Skrypt zostanie wykonany automatycznie, o ile nie znajduje się w `./storage/gitlab/config-XXXXX-start-done/`
6. Jeżeli plik konfiguracyjny ma być stale zachowany (obecny katalog może być wyczyszczony przez polecenie z punktu [3.2.2 Usuwanie konfiguracji ...](#322-usuwa-zawartosc-konfiguracji-beforeafter)) należy przenieść skrypt `XX_nazwa.sh` (i jego katalog o ile występuje `XX_nazwa`) do GitLab/config/XXXXX-start

---

## 🧩 Moduł: MailHog

### 📌 Podstawowe informacje

- **Nazwa kontenera:** `mailhog`
- **IP:** `172.0.10.4`
- **Domena (opcjonalna):** `mailhog.local` *(można dodać do `/etc/hosts`)*
- **Porty wystawione przez kontener:**
  - `1025` – port SMTP (dla aplikacji wysyłających maile)
  - `8025` – interfejs webowy do podglądu wiadomości e-mail

### 🛠️ Rola w projekcie

MailHog symuluje odbiornik e-mail. Pozwala przetestować mechanizmy powiadomień e-mailowych bez konieczności konfiguracji zewnętrznego serwera pocztowego. W projekcie GitLab jego rola to:

- Obsługa wiadomości aktywacyjnych dla kont użytkowników
- Powiadomienia z pipeline’ów (CI/CD)
- Wiadomości systemowe

### 📁 Montowanie

MailHog nie wymaga trwałego wolumenu — nie jest kluczowe, by zachować historię e-maili między restartami.

### 🌐 Dostęp

Po uruchomieniu kontenera, interfejs użytkownika MailHoga będzie dostępny pod adresem:

```
http://localhost:8025
```

Lub, jeśli została zmapowana domena:

```
http://mailhog.local:8025
```

📌 **Uwaga:** Domyślnie interfejs nie posiada uwierzytelnienia, dlatego nie należy wystawiać go na zewnątrz sieci lokalnej.

### 🧪 Testowanie integracji

Aby przetestować działanie MailHoga, można wysłać e-mail za pomocą narzędzia `sendmail`, `curl` lub biblioteki SMTP z poziomu testowej aplikacji. Wszystkie maile powinny pojawić się w interfejsie webowym MailHoga.

---

## 🧰 Narzędzia ogólne

Narzędzia ogólne to zbiór narzędzi i skryptów pomocniczych, które nie są bezpośrednio związane z logiką głównych komponentów systemu (jak GitLab, SMTP itp.), ale wspierają jego rozwój, testowanie oraz utrzymanie. Poniżej opisano dostępne moduły, które w przyszłości mogą zostać rozbudowane o kolejne elementy. Narzędzia znajdują się w katalogu tools/[MODUŁ]/narzędzie.sh
Listę dostępnych narzędzi będzie można znaleźć w pliku Makefile pod komendą:

``` bash
make help
```

a użyć narzędzia:

``` bash
make [narzędzie]
lub
./tools/[MODUŁ]/narzedzie.sh
```

Przykład:

``` bash
make gitLab-clean-storage
lub
./tools/gitlab/clean-storage.sh
```

### GitLab

Znajdują się w katalogu tools/gitlab/ i mają prefig w Makefile gitlab-

#### 1 🧹 Clean Storage

Skrypt `clean-storage.sh` umożliwia szybkie i kontrolowane wyczyszczenie danych kontenera GitLaba, z zachowaniem podstawowej konfiguracji.

##### 1.1 🔧 Uruchomienie

``` bash
make gitLab-clean-storage
lub
./tools/gitlab/clean-storage.sh

```

##### 1.2 🔧 Działanie skryptu

Środowisko GitLaba zostaje przywrócone **do stanu pierwotnego**, jak przy pierwszym uruchomieniu kontenera — bez żadnych informacji o wcześniejszym działaniu systemu ani historii wykonania konfiguracji.

- Usuwa całą zawartość katalogów `storage/gitlab/`, **z wyjątkiem katalogów `config-before-start/` i `config-after-start`**, zawierających pierwotne skrypty konfiguracyjne GitLaba.
- Dzięki temu, przy kolejnym uruchomieniu kontenera:
  - Brak katalogu `config-before-start-done` i `config-after-start-done` oznacza, że żadne skrypty konfiguracyjne nie zostały jeszcze wykonane.
  - Redis startuje z pustym stanem (jego dane są również usuwane), co powoduje ponowne zastosowanie konfiguracji.
  - Wszystkie skrypty z `config-before-start/` i `config-after-start` zostają automatycznie uruchomione, odtwarzając świeży stan systemu.

##### 1.3 💡 Użycie

Skrypt jest szczególnie przydatny w środowiskach testowych i rozwojowych, gdzie często istnieje potrzeba zresetowania GitLaba do stanu początkowego — bez ręcznego usuwania plików i danych.

#### 2 🧹 Clean Configuration Before Start

Skrypt `clean-config-before.sh` umożliwia szybkie usunięcie wszystkich niestandardowych skryptów konfiguracyjnych z folderu `storage/gitlab/config-before-start/`, przywracając jego pierwotny stan (jak po pobraniu z repozytorium). 

Informacyjnie: skrypty w z tego folderu uruchamiają się przed uruchomieniem GtiLaba

##### 2.1 🔧 skót

``` bash
make gitLab-clean-configuration-before-start
lub
./tools/gitlab/clean-before-config.sh
```

##### 2.2 🔧 Działanie skryptu

- Usuwa wszystkie pliki i foldery z katalogu `storage/gitlab/config-before-start/`, z wyjątkiem ukrytego pliku `.gitkeep`.
- Dzięki temu, przy kolejnym uruchomieniu kontenera:
  - kontener zostanie uruchomiony z takimi samymi ustawieniami jak poprzednio, poniewa wyczyszczony folder zawierał skrypty które maja sie uruchomić przy starcie kontenera i zmienić konfigurację a jest pusty.
  - kontener wstanie szybciej ponieważ będzie sprawdzał mniej skryptów podczas uruchomienia

##### 2.3 💡 Użycie

Skrypt jest użyteczny gdy chcemy wyczyścić katalog z konfiguracją która była uruchomiona (lub nie chcemy nic zmieniać przy kolejnym uruchomieniu/restarcie) przy starcie kontenera.
Można wykorzystać w połączeniu z innymi poleceniami aby przywrócić storage/gitlab/ do pierwotnej postacji jaka się pobrało z repo:

- [1 🧹 Clean Storage](#1--clean-storage)
- [3 🧹 Clean Configuration After Start](#3--clean-configuration-after-start)

#### 3 🧹 Clean Configuration After Start

Skrypt `clean-after-config.sh` umożliwia szybkie usunięcie wszystkich niestandardowych skryptów konfiguracyjnych z folderu `storage/gitlab/config-after-start/`, przywracając jego pierwotny stan (jak po pobraniu z repozytorium).

📌 **Informacja**: Skrypty z tego folderu uruchamiają się **po uruchomieniu GitLaba**, więc mogą modyfikować jego działające środowisko (np. rejestrować runnery, ustawiać tokeny, zmieniać konfiguracje).

##### 3.1 🔧 skót

``` bash
make gitLab-clean-configuration-after-start
lub
./tools/gitlab/clean-after-config.sh
```

##### 3.2 🔧 Działanie skryptu

- Usuwa wszystkie pliki i foldery z katalogu `storage/gitlab/config-after-start/`, z wyjątkiem ukrytego pliku `.gitkeep`.

- Dzięki temu, przy kolejnym uruchomieniu kontenera:
  - GitLab `uruchomi się bez wykonywania dodatkowych działań konfiguracyjnych` z tego folderu.
  - Oszczędzamy czas uruchamiania oraz unikamy potencjalnych konfliktów z wcześniejszymi modyfikacjami.

##### 3.3 💡 Użycie

Skrypt jest użyteczny gdy chcemy wyczyścić katalog z konfiguracją która była uruchomiona (lub nie chcemy nic zmieniać przy kolejnym uruchomieniu/restarcie) po starcie kontenera.

Można wykorzystać w połączeniu z innymi poleceniami aby przywrócić storage/gitlab/ do pierwotnej postacji jaka się pobrało z repo:

- [1 🧹 Clean Storage](#1--clean-storage)
- [2 🧹 Clean Configuration Before Start](#2--clean-configuration-before-start)

#### 4 📝 Copy Configuration Before Start

Skrypt `copy-config-before.sh` służy do skopiowania nowych lub zaktualizowanych plików konfiguracyjnych do katalogu `storage/gitlab/config-before-start/`, który odpowiada za konfigurację GitLaba **przed jego uruchomieniem**.

##### 4.1 🔧 skót

``` bash
make gitLab-copy-configuration-before-start
lub
./tools/gitlab/copy-config-before.sh
```

##### 4.2 🔧 Działanie skryptu

- Kopiuje pliki z katalogu `GitLab/config/before-start/` do `storage/gitlab/config-before-start/`.
- Dzięki temu pliki te będą wykorzystane podczas uruchamiania kontenera GitLaba (zanim zostanie uruchomiona jego właściwa usługa).
- W przypadku istnienia plików o tej samej nazwie — zostaną one nadpisane.

##### 4.3 💡 Użycie

Skrypt stosowany jest najczęściej w celu:

- Wgrania nowej konfiguracji startowej przed uruchomieniem kontenera.
- Przywrócenia konkretnej konfiguracji z repozytorium po wcześniejszym czyszczeniu ([2 🧹 Clean Configuration Before Start](#2--clean-configuration-before-start)).

#### 5 📝 Copy Configuration After Start

Skrypt `copy-config-after.sh` służy do kopiowania plików konfiguracyjnych do katalogu `storage/gitlab/config-after-start/`, odpowiedzialnego za konfigurację **wykonywaną po uruchomieniu GitLaba**.

##### 5.1 🔧 skót

``` bash
make gitLab-copy-configuration-after-start
lub
./tools/gitlab/copy-config-after.sh
```

##### 5.2 🔧 Działanie skryptu

- Kopiuje pliki z katalogu `GitLab/config/after-start/` do `storage/gitlab/config-after-start/`.
- Pliki te zostaną automatycznie wykonane w momencie, gdy GitLab zakończy uruchamianie.
- W przypadku istnienia plików o tej samej nazwie — zostaną one nadpisane.

##### 5.3 💡 Użycie

Przydatny gdy:

- Chcesz zastosować nową konfigurację po uruchomieniu GitLaba, np. widocznosć repozytoriów, mozliwośćrejestracji.
- Przywracasz konfigurację z repozytorium po użyciu skryptu [3 🧹 Clean Configuration After Start](#3--clean-configuration-after-start).

---

## 📌 Notatki końcowe

### 🛠️ W przygotowaniu

- W miarę rozwoju projektu będą dodawane nowe komponenty.
- W przyszłości możliwe jest przejście na automatyzację konfiguracji (np. Ansible, Terraform).
- Wersja dokumentacji w języku angielskim.

---

© Projekt edukacyjny tworzony w wolnym czasie.
