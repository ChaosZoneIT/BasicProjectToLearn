# Symulacja Środowiska Produkcyjnego w Kontenerach

## Opis projektu

Projekt ma na celu **symulację konfiguracji środowiska produkcyjnego** w małej organizacji. Głównym celem jest nauka konfiguracji narzędzi od podstaw — początkowo za pomocą skryptów, a w przyszłości być może z wykorzystaniem bardziej zaawansowanych narzędzi (np. Ansible, Terraform, itp.).

Zmiany w repozytorium będą dodawane w postaci **spójnych commitów**, z dokładnym opisem każdej funkcjonalności oraz uzasadnieniem wykonanych zmian.

Cała struktura systemu opiera się na kontenerach Docker, które **symulują maszyny/serwery w organizacji**, uruchamiając różne narzędzia i usługi.

---

## Etap 1: GitLab + Mock SMTP

W pierwszym etapie projektu tworzona jest sieć w `docker-compose`, która zawiera dwa kontenery:

### 1. GitLab CE

- Oparty na systemie **Ubuntu 24.04**
- Dostępny przez **HTTPS** (z lokalnym, samopodpisanym certyfikatem SSL)
- **Zablokowana rejestracja użytkowników** – tylko administrator może tworzyć konta
- Wymagana **weryfikacja adresu e-mail** przed uzyskaniem dostępu do repozytoriów
- Planowana struktura grup/projektów:
  - Dwa zespoły developerskie (Dev)
  - Jeden zespół DevOps
  - Testerzy (docelowo 2 osoby, z możliwością uruchamiania własnych środowisk testowych)
  - Osoba odpowiedzialna za wdrożenia na środowisko produkcyjne

### 2. Mock serwer SMTP

- Symuluje odbiór wiadomości e-mail:
  - rejestracja / aktywacja konta
  - powiadomienia z pipeline'ów
  - inne systemowe powiadomienia z GitLaba

---

## Przykładowy projekt

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
│   ├── Dockerfile                            # Obraz bazujący na Ubuntu 24 z preinstalowanym GitLabem
│   ├── init.scripts.sh                       # Skrypt sprawdzający gotowość GitLaba i uruchamiający konfigurację z katalogu init.scripts
│   └── start.scripts.sh                      # Skrypt startujący GitLaba oraz wywołujący init.scripts.sh
├── storage/
│   └── gitlab/                               # Wolumeny powiązane z GitLabem (logi, dane, konfiguracja, itp.)
│       ├── init.scripts/                     # Katalog z pierwotną konfiguracją – skrypty uruchamiane tylko raz
│       │   ├── 01_disable_signup.sh          # Wyłączenie rejestracji użytkowników
│       │   ├── 02_required_confirm_email.sh  # Wymaganie potwierdzenia adresu e-mail
│       │   └── 03_visible_repository.sh      # Ustawienie widoczności projektów
│       └── init.scripts.done/                # Folder zawierający skrypty, które zostały już wykonane (i są pomijane przy kolejnym uruchomieniu)
├── clean-storage.sh                          # Skrypt czyszczący wolumeny (z wyjątkiem początkowych skryptów konfiguracyjnych GitLaba)
└── docker-compose.yml                        # Główny plik uruchamiający środowisko (GitLab + SMTP)

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

W katalogu głównym projektu uruchamiamy polecenia:

``` bash
docker compose build docker compose up -d
```


### 3. 🕐 Czekanie na pełne uruchomienie

GitLab uruchamia się przez dłuższy czas. Choć interfejs może być wcześniej dostępny, konfiguracja wykonywana przez skrypty startowe może jeszcze trwać. Z tego względu:

✅ **Zaleca się korzystanie z systemu dopiero po wykonaniu wszystkich skryptów inicjalizacyjnych.**  
Sprawdź, czy katalogi `init.scripts` i `init.scripts.done` mają identyczną zawartość.

Po poprawnym uruchomieniu (co trochę trwa) serwis GitLaba powinien być dostępny pod adresem:

```
https://gitlab.company.local
```


📌 Pamiętaj: jest używany lokalny certyfikat SSL, więc przeglądarka może zgłaszać ostrzeżenie.

### 4. 🔐 Dostęp do GitLaba

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
- **IP:** `172.0.10.3`  
- **Domena:** `gitlab.company.local` *(musi być zmapowana w pliku `/etc/hosts`)*  
- **Porty wystawione przez kontener:** `80`, `443`, `22`  
- **Certyfikat SSL:** generowany automatycznie dla `gitlab.company.local`  
- **Konfiguracja domeny i HTTPS:** modyfikacja pliku `gitlab.rb` w czasie budowania obrazu  

---

### 📁 Struktura katalogów i konfiguracji

GitLab działa z trzema głównymi katalogami konfiguracyjnymi:

#### 1. `/startScript` → `$BASE_SCRIPTS_DIR`

- Zawiera plik `startGitLab.sh`
- Jest montowany z hosta i inicjalizowany przy starcie kontenera
- Odpowiada za:
  - Uruchomienie usług systemowych (np. `gitlab-ctl`)
  - Skopiowanie konfiguracji `gitlab.rb` (ze względu na nadpisanie wolumenem)
  - Wykonanie `gitlab-ctl reconfigure`
  - Uruchomienie `init.scripts.sh`

#### 2. `/gitlab-init-config` → `$CONFIGURE_SCRIPTS_TO_EXECUTE`

- Zawiera **bazowe skrypty konfiguracyjne** GitLaba
- Montowany z hosta z katalogu: `./storage/gitlab/init.scripts/`
- Skrypty w tym folderze:
  - Wykonywane tylko jeśli **nie zostały wcześniej uruchomione**
  - Wymagają unikalnej nazwy i numerowania (`01_`, `02_` itd.)
  - Pozwalają przetrwać restart kontenera bez utraty konfiguracji

#### 3. `/gitlab-init.done` → `$CONFIGURE_SCRIPTS_TO_DONE`

- Zawiera **skrypty, które zostały już wykonane**
- Montowany z hosta z katalogu: `./storage/gitlab/init.scripts.done/`
- Pliki w tym katalogu:
  - Pomijane przy kolejnym uruchamianiu
  - Pozwalają na zachowanie stanu konfiguracji nawet po restarcie kontenera

---

### ⚙️ Skrypty konfiguracyjne

#### `startGitLab.sh`

Kroki realizowane przez skrypt:

1. Uruchamia wymagane usługi systemowe (`gitlab-ctl`)
2. Kopiuje plik `gitlab.rb` (ze względu na montowanie katalogu `/etc/gitlab`)
3. Uruchamia `gitlab-ctl reconfigure`
4. Uruchamia `init.scripts.sh`

#### `init.scripts.sh`

Odpowiada za:

1. Sprawdzenie, czy GitLab się uruchomił:
   - Monitorowanie usługi `sidekiq` (jedna z ostatnich usług)
   - Sprawdzenie dostępności portu `443`
   - *(Opcjonalnie)* Sprawdzenie odpowiedzi HTTP `200 OK`
2. Uruchomienie skryptów z katalogu `/gitlab-init-config`:
   - W kolejności alfabetycznej
   - Tylko jeśli plik **nie istnieje** w `/gitlab-init.done`
   - Po wykonaniu pliku, jego kopia trafia do `init.scripts.done`

---

### ➕ Dodawanie własnych skryptów

Aby dodać własny skrypt konfiguracyjny:

1. Umieść go w katalogu na hoście: `./storage/gitlab/init.scripts/`
2. Nazwij plik zgodnie z formatem: `XX_nazwa.sh`, np. `04_add_runner.sh`
3. Uruchom ponownie kontener:
   docker compose restart gitlab_server
4. Skrypt zostanie wykonany automatycznie, o ile nie znajduje się w `init.scripts.done`

---

## 🧰 Moduły ogólne

Moduły ogólne to zbiór narzędzi i skryptów pomocniczych, które nie są bezpośrednio związane z logiką głównych komponentów systemu (jak GitLab, SMTP itp.), ale wspierają jego rozwój, testowanie oraz utrzymanie. Poniżej opisano dostępne moduły, które w przyszłości mogą zostać rozbudowane o kolejne elementy.

### 🧹 Clean Storage

Skrypt `clean-storage.sh` umożliwia szybkie i kontrolowane wyczyszczenie danych kontenera GitLaba, z zachowaniem podstawowej konfiguracji.

#### 🔧 Działanie skryptu:

- Usuwa całą zawartość katalogu `storage/gitlab/`, **z wyjątkiem katalogu `init.scripts/`**, zawierającego pierwotne skrypty konfiguracyjne GitLaba.
- Dzięki temu, przy kolejnym uruchomieniu kontenera:
  - Brak katalogu `init.scripts.done` oznacza, że żadne skrypty konfiguracyjne nie zostały jeszcze wykonane.
  - Redis startuje z pustym stanem (jego dane są również usuwane), co powoduje ponowne zastosowanie konfiguracji.
  - Wszystkie skrypty z `init.scripts/` zostają automatycznie uruchomione, odtwarzając świeży stan systemu.

#### 💡 Użycie:

Skrypt jest szczególnie przydatny w środowiskach testowych i rozwojowych, gdzie często istnieje potrzeba zresetowania GitLaba do stanu początkowego — bez ręcznego usuwania plików i danych.

---

## 📌 Notatki końcowe

### 🛠️ W przygotowaniu

- W miarę rozwoju projektu będą dodawane nowe komponenty.
- W przyszłości możliwe jest przejście na automatyzację konfiguracji (np. Ansible, Terraform).
- Wersja dokumentacji w języku angielskim.

---

© Projekt edukacyjny tworzony w wolnym czasie.