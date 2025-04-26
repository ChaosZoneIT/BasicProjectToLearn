# Symulacja Środowiska Produkcyjnego w Kontenerach

## ⚠️ Dokumentacja robocza

> **Uwaga:** Dokumentacja jest w trakcie rozwoju. Może zawierać niekompletne informacje, błędy lub nieaktualne opisy.

## Opis projektu

Celem projektu jest **symulacja środowiska produkcyjnego** w małej organizacji — jako piaskownica do nauki i testów z zakresu DevOps, automatyzacji oraz zarządzania infrastrukturą (Ansible, GitLab, Terraform itd.).

Środowisko można łatwo rozwijać, czyścić i odtwarzać za pomocą prostych skryptów.

Całość opiera się na kontenerach Docker, które **symulują maszyny/serwery organizacyjne**, uruchamiając różne usługi i narzędzia.  
Kontenery są lżejsze niż tradycyjne maszyny wirtualne, co ułatwia uruchamianie całego środowiska.

> ℹ️ **Uwaga:** Choć kontenery są wygodne, mogą pojawiać się pewne wyzwania, takie jak:
> - utrata danych po restarcie kontenera,
> - problemy z wolumenami (np. właściciel i grupa plików lub nadpisywanie zawartości katalogu, gdy host zawiera dane, a kontener nie lub odwrotnie),
> - inne kwestie związane z konfiguracją i zarządzaniem danymi.

Projekt wykorzystuje **lokalne, samopodpisane certyfikaty SSL**.

---

## Sieć

Wszystkie kontenery są uruchamiane w dedykowanej sieci Docker z adresem bazowym `172.0.10.0/24`.  
Każdy kontener ma przypisane dedykowane IP w zakresie `172.0.10.x`, ale dostęp do usług odbywa się głównie poprzez domeny obsługiwane przez Nginx (reverse proxy), który ma wystawione porty `80` i `443`.

| Kontener             | Rola                                | IP           | Dostęp                                         |
|----------------------|-------------------------------------|--------------|------------------------------------------------|
| nginx_reverse_proxy  | Reverse Proxy (Nginx)               | 172.0.10.2   | Porty 80/443 (wystawione na hosta)             |
| bastion              | Bastion Host (CentOS + SSH + Ansible) | 172.0.10.3   | Port 2221 (SSH)                               |
| gitlab_server        | GitLab CE + SMTP + SSL              | 172.0.10.4   | Dostęp przez Reverse Proxy i SSH z bastionu    |
| mailhog              | SMTP Mock (Mailhog)                 | 172.0.10.5   | Dostęp przez Reverse Proxy                    |

---

## Wolumeny

Serwisy mają podmontowane wolumeny na komputerze hosta, co zapewnia im trwałość danych (konfiguracji, logów) po restarcie kontenerów.

---

## Architektura sieci i bezpieczeństwo

Schemat działania (logiczny):

```bash
    ┌─────────────────────────────┐               ┌────────────────────────────┐
    │        Przeglądarka         │               │           Konsola          │
    │ (np. gitlab.company.local)  │               │  (172.0.10.3 - port 2221)  │
    └────────────┬────────────────┘               └────────────┬───────────────┘
                 │ HTTPS / HTTP                               │ SSH
                 ▼                                            ▼
┌─────────────────────────────────────┐       ┌────────────────────────────────────┐
│                Nginx                │       │           Bastion Host             │
│           (Reverse Proxy)           │       │                                    │
│  - Odbiera ruch (443/80)            │       │                                    │
│  - Terminacja SSL (jeśli włączona)  │       │                                    │
│  - Routing po domenie               │       │                                    │
└────────────────┬────────────────────┘       └────────────────┬───────────────────┘
                 │ HTTPS / HTTP                                │ SSH
     ┌───────────┴────┬────────────────────────────────────────┘
 SSH ▼ HTTPS     HTTP ▼             
┌────────────┐ ┌────────────┐ 
│   GitLab   │ │   MailHog  │
│  (HTTPS)   │ │   (HTTP)   │ 
└────────────┘ └────────────┘ 
```

## Projekt: Infrastruktura do CI/CD

Projekt ma na celu stworzenie infrastruktury umożliwiającej automatyzację procesów CI/CD z wykorzystaniem narzędzi takich jak GitLab oraz Nginx jako reverse proxy.  
Struktura została zbudowana przy użyciu Docker Compose, co pozwala na uruchomienie wielu kontenerów w izolowanej, wspólnej sieci.

W skład projektu wchodzą następujące główne komponenty:

- **Nginx** jako Reverse Proxy
- **Bastion Host**
- **GitLab CE**
- **Mock serwer SMTP** (MailHog)

---

### 1. Nginx jako Reverse Proxy

Nginx jest głównym punktem wejścia do usług działających w środowisku. Został skonfigurowany jako reverse proxy, co pozwala na zarządzanie ruchem przychodzącym do aplikacji z jednego miejsca.  
Dzięki temu użytkownicy mogą korzystać z usług takich jak GitLab bez konieczności podawania numerów portów.

#### Główne cechy

- Umożliwia dostęp do serwisów bez podawania portu w URL (np. `http://email.company.local` zamiast `http://localhost:8025`).
- Przekierowuje ruch HTTP/HTTPS do odpowiednich kontenerów w zależności od domeny.
- Obsługuje terminację SSL: odbiera ruch HTTPS, a następnie przekazuje go do usług wewnętrznych jako HTTP lub HTTPS.
- W przyszłości możliwe jest dodanie TLS passthrough dla wybranych usług (np. Jenkins, SonarQube).

Obsługiwane domeny:
- `gitlab.company.local` (SSL, port 443)
- `email.company.local` (HTTP)

##### Mapowanie usług

| Usługa     | Domena lokalna         | Protokół         | Certyfikat SSL               | Obsługa przez Nginx | Port docelowy | Rodzaj Reverse Proxy |
|------------|-------------------------|------------------|-------------------------------|---------------------|---------------|----------------------|
| GitLab CE  | gitlab.company.local     | HTTP ➔ HTTPS / HTTPS | `gitlab.company.local.crt` | Tak                 | 443           | SSL termination      |
| MailHog    | email.company.local      | HTTP             | Brak                          | Tak                 | 8025          | Standard HTTP        |

---

### 2. Bastion Host

**Bastion Host** jest specjalnym kontenerem, który pełni rolę komputera administratora.  
Jest dostępny z zewnątrz przez SSH, co umożliwia zarządzanie całą infrastrukturą.

- **System**: CentOS Stream 9
- **Dostęp**: `ssh devops@localhost -p 2221`
- **Użytkownik**: `devops` (z uprawnieniami `sudo`)
- **Hasło**: `devops`
- **Narzędzia**: Ansible

---

### 3. GitLab CE

**GitLab CE** (Community Edition) to centralna platforma do zarządzania kodem źródłowym oraz automatyzacji procesów CI/CD.  
Uruchomiony został w kontenerze opartym na systemie **Ubuntu 24.04**.

- Dostęp przez HTTPS (lokalny, samopodpisany certyfikat SSL).
- Dostęp przez SSH (user: admin, hasło: admin, uprawnienia sudo).
- Blokada rejestracji użytkowników — tylko administrator może tworzyć konta.
- Weryfikacja e-mail obowiązkowa przed dostępem do repozytoriów.
- Wszystkie repozytoria ustawione jako prywatne.
- Integracja SMTP z MailHog do testowania wiadomości e-mail (np. rejestracja, powiadomienia).

---

### 4. Mock serwer SMTP (MailHog)

**MailHog** działa jako symulator serwera SMTP.  
Pozwala przechwytywać i przeglądać wiadomości e-mail wysyłane z systemów takich jak GitLab.

Zalety MailHoga:

- **Testowanie e-maili**: Możliwość przeglądania wysyłanych wiadomości.
- **Bezpieczne testowanie**: Żadne wiadomości nie wychodzą na zewnętrzne serwery.
- **Dostępność**: Serwis działa lokalnie pod `http://email.company.local`.

---

## 🚀 Uruchamianie projektu

Projekt przygotowano i testowano na systemie **Linux**.

### 1. 🧭 Mapowanie domen w `/etc/hosts`

Aby dostęp do GitLaba po nazwie domenowej działał lokalnie, należy dodać wpisy do pliku `/etc/hosts`:

``` bash
sudo nano /etc/hosts
```

Dodaj poniższe linie na końcu pliku:

``` bash
172.0.10.2 gitlab.company.local
172.0.10.2 email.company.local
```

📌 Uwaga: Reverse Proxy (Nginx) obsługuje obie domeny pod jednym adresem IP, co umożliwia dostęp do usług bez konieczności podawania portów.

### 2. 🛠️ Budowanie i uruchomienie projektu

W katalogu głównym projektu (przed pierwszym uruchomieniem) wykonaj następujące kroki:

---

#### 2.1 Kopiowanie konfiguracji

Skopiuj przykładowe pliki konfiguracyjne do katalogów podmontowanych jako wolumeny w kontenerach.

Możesz to zrobić za pomocą polecenia `make`:

```bash
make startConfigurationAll
# lub pojedynczo:
make bastion-set-permission
make gitLab-copy-configuration-before-start
make gitLab-copy-configuration-after-start
make nginx-copy-config
```

Alternatywnie, możesz uruchomić skrypty bezpośrednio:

```bash
./tools/bastion/set-default-permission.sh
./tools/gitlab/copy-config-before.sh
./tools/gitlab/copy-config-after.sh
./tools/nginxReverseProxy/copy-configuration.sh
```

Te polecenia kopiują konfiguracje z katalogów:

- GitLab/config/after-satrt/
- GitLab/config/before-satrt/
- nginxReverseProxy/config/

do odpowiednich katalogów wolumenów:

- store/gitlab/config-after-start/
- store/gitlab/config-before-start/
- store/nginxReverseProxy/confing/

oraz nadają uprawnienia do katalogu, w którym można przekazywać skrypty do wykonania w kontenerze bastion.

#### 2.2 Budowanie obrazów Docker

```bash
docker compose build
```

#### 2.3 Uruchomienie kontenerów

```bash
docker compose up -d
```

#### 2.3.1 🕐 Oczekiwanie na pełne uruchomienie GitLaba

GitLab może potrzebować kilku minut na pełne uruchomienie i wykonanie skryptów inicjalizacyjnych.
Chociaż interfejs WWW może być dostępny wcześniej, zaleca się poczekać na zakończenie procesu konfiguracyjnego.

✅ Po zakończeniu inicjalizacji katalogi:

- `config-after-start`
- `config-after-start-done`
powinny mieć identyczną zawartość (lub pojawi się inny sygnał potwierdzający zakończenie inicjalizacji – szczegóły w dalszej części dokumentacji).

Serwis GitLab będzie dostępny pod adresem:

```bash
https://gitlab.company.local
```

>📌 Uwaga:
Ponieważ używany jest lokalny, samopodpisany certyfikat SSL, przeglądarka może wyświetlić ostrzeżenie dotyczące bezpieczeństwa.

---

### 3. 🔐 Korzystanie z projektu

#### 3.1 Konfiguracja (podstawowe operacje: dodanie użytkownika, klucz SSH, połączenie między kontenerami)

Ponieważ katalogi domowe użytkowników są montowane na hoście, aby zachować konfigurację (np. klucze SSH), domyślnie mają właściciela `root:root`.  
W przypadku tych folderów jest to niepożądane — należy zmienić właściciela.  
Poniżej instrukcja na przykładzie kontenerów **Bastion** i **GitLab**.

---

##### 3.1.1 Kopiowanie skryptów na hosta

Na komputerze hosta kopiujemy pliki, które wykorzystamy w kontenerach:

Z katalogu:

- `BastionHost/bash/`

kopiujemy:

- `create_user.sh`
- `generate_ssh_key.sh`

do katalogu:

- `storage/a_bastion/scripts/`

---

##### 3.1.2 Ustawienie uprawnień katalogu domowego użytkownika `devops` (na Bastionie)

Logujemy się do kontenera:

```bash
ssh devops@172.0.10.3 -p 2221 # hasło: devops
```

Sprawdzamy uprawnienia katalogu domowego:

```bash
🐳 devops@172.0.10.3:~ $ ls -ld /home/$USER
drwxr-xr-x 2 root root 4096 Apr 26 04:48 /home/devops
```

Jeśli właścicielem jest root, zmieniamy:

```bash
🐳 devops@172.0.10.3:~ $ sudo chown -R $USER:$USER /home/$USER
🐳 devops@172.0.10.3:~ $ ls -ld /home/$USER
drwxr-xr-x 2 devops devops 4096 Apr 26 04:48 /home/devops
```

Przykład:

```bash
drwxr-xr-x 2 root root 4096 Apr 26 04:48 /home/devops
# po zmianie:
drwxr-xr-x 2 devops devops 4096 Apr 26 04:48 /home/devops
```

3.1.3 Generowanie klucza SSH (na Bastionie)

Generujemy klucz za pomocą skryptu:

```bash
🐳 devops@172.0.10.3:~ $ /my-scripts/generate_ssh_key.sh
Created .ssh directory for devops
SSH key for user devops has been generated at: /home/devops/.ssh/devops-rsa-key
Public key: /home/devops/.ssh/devops-rsa-key.pub
🐳 devops@172.0.10.3:~ $
```

> Domyślna nazwa klucza: `[user]-rsa-key`. Można ją zmienić podając parametr do skryptu.

Sprawdzamy uprawnienia:

```bash
🐳 devops@172.0.10.3:~ $ ls -ld /home/$USER/.ssh/
drwx------ 2 devops devops 4096 Apr 26 17:06 /home/devops/.ssh/
🐳 devops@172.0.10.3:~ $ ls -ld /home/$USER/.ssh/devops-rsa-key
-rw------- 1 devops devops 3381 Apr 26 17:06 /home/devops/.ssh/devops-rsa-key
🐳 devops@172.0.10.3:~ $ ls -ld /home/$USER/.ssh/devops-rsa-key.pub
-rw-r--r-- 1 devops devops 743 Apr 26 17:06 /home/devops/.ssh/devops-rsa-key.pub
🐳 devops@172.0.10.3:~ $
```

##### 3.1.4 Dodanie użytkownika ansible z uprawnieniami sudo (na GitLab)

> Operacje wykonujemy z kontenera **Bastion**.

Tworzenie użytkownika poleceniem:

```bash
🐳 devops@172.0.10.3:~ $ ssh admin@172.0.10.4 'sudo bash -s' < /my-scripts/create_user.sh ansible
admin@172.0.10.4's password: 
Could not chdir to home directory /home/admin: No such file or directory
Creating user ansible with password ansible
useradd: warning: the home directory /home/ansible already exists.
useradd: Not copying any file from skel directory into it.
Granting ansible sudo privileges without password
Configuring SSH to allow ansible to login
User ansible created successfully with sudo privileges and SSH access.
```

> Alternatywy:
    1. Przesłanie skryptu i wykonanie lokalnie:
    scp /my-scripts/create_user.sh admin@172.0.10.4:/tmp
    ssh admin@172.0.10.4
    /tmp/create_user.sh ansible
    2. Pobranie skryptu na maszynie GitLab:
    ssh admin@172.0.10.4
    scp devops@172.0.10.3:/my-scripts/create_user.sh /tmp/
    /tmp/create_user.sh ansible
    3. Ręczne tworzenie użytkownika (komendy w skrypcie).

Parametry skryptu:

- nazwa użytkownika (ansible)
- opcjonalnie hasło (domyślnie takie samo jak nazwa użytkownika)

Sprawdzamy, czy użytkownik działa:

```bash
🐳 devops@172.0.10.3:~ $ ssh ansible@172.0.10.4
ansible@172.0.10.4's password: (hasło: ansible)
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.11.0-24-generic x86_64)
...
...
...
[gitLab] ansible@gitlab.company.local:~ $
```

Jeśli logowanie przebiegło pomyślnie, zmieniamy właściciela katalogu domowego:

```bash
[gitLab] ansible@gitlab.company.local:~ $ ls -ld /home/$USER
drwxr-xr-x 2 root root 4096 Apr 26 04:48 /home/ansible
[gitLab] ansible@gitlab.company.local:~ $ sudo chown -R $USER:$USER /home/$USER
[gitLab] ansible@gitlab.company.local:~ $ ls -ld /home/$USER
drwxr-xr-x 2 ansible ansible 4096 Apr 26 04:48 /home/ansible
[gitLab] ansible@gitlab.company.local:~ $
```

##### 3.1.5 Dodanie klucza SSH dla ansible (logowanie bez hasła)

Z kontenera Bastion:

1. Wyjście z GitLaba:

```bash
[gitLab] ansible@gitlab.company.local:~ $ exit
logout
Connection to 172.0.10.4 closed.
🐳 devops@172.0.10.3:~ $
```

2. Instalacja klucza:

```bash
🐳 devops@172.0.10.3:~ $ ssh-copy-id -i ~/.ssh/devops-rsa-key.pub ansible@172.0.10.4
```

3. Test połączenia:

- Szybko:

```bash
ssh -i ~/.ssh/devops-rsa-key ansible@172.0.10.4
```

- Lub skonfigurować plik ~/.ssh/config (zalecane):

```bash
nano ~/.ssh/config
```

```text
Host 172.0.10.4
    IdentityFile ~/.ssh/devops-rsa-key
    PasswordAuthentication no
```

Zapisz i zamknij nano

```bash
ctrl+o ENTER  # zapisuje plik nano
ctrl+x        # wychodzi z pliku
```

Po tym można logować się zwykłym:

```bash
🐳 devops@172.0.10.3:~ $ ssh ansible@172.0.10.4
```

- Opcjonalnie: dodanie klucza do agenta SSH (nie przetrwa restartu kontenera)

Sprawdzenie czy agent działa:

``` bash
🐳 devops@172.0.10.3:~ $ ssh-add -l
Could not open a connection to your authentication agent.
```

Jeśli brak połączenia, uruchamiamy:

```bash
🐳 devops@172.0.10.3:~ $ eval $(ssh-agent -s)
Agent pid 107
🐳 devops@172.0.10.3:~ $ ssh-add -l
The agent has no identities.
```

Dodanie klucza:

```bash
🐳 devops@172.0.10.3:~ $ ssh-add ~/.ssh/devops-rsa-key
Identity added: /home/devops/.ssh/devops-rsa-key (devops@172.0.10.3)
```

Od teraz logowanie bez hasła działa również w tej sesji.

```bash
🐳 devops@172.0.10.3:~ $ ssh ansible@172.0.10.4
```

#### 3.2 Dostęp do GitLaba

Adres do logowania z przeglądarki:

```bash
https://gitlab.company.local
```

##### 📥 Odzyskanie hasła użytkownika root GitLab

Hasło root jest generowane automatycznie podczas pierwszego uruchomienia.

🔎 **Z poziomu kontenera:**

```bash
docker compose exec -it gitlab_server cat /etc/gitlab/initial_root_password
```

📁 **Z poziomu hosta:**

```bash
cat ./storage/gitlab/config/initial_root_password
```

📌 **Uwaga**: Plik ten jest automatycznie usuwany po pierwszym gitlab-ctl reconfigure lub po 24 godzinach.

---

### 4. 🧹 Czyszczenie/przywracanie projektu do pierwotnej postaci

Sekcja ta opisuje, jak wyczyścić środowisko i przywrócić projekt do pierwotnej postaci — np. w celu przetestowania nowej konfiguracji lub poprawności autokonfiguracji.

### 4.1 Zarządzanie kontenerami i obrazami

Zarządzanie kontenerami i obrazami

1. Zatrzymaj wszystkie kontenery:

```bash
docker compose down
```

2. Sprawdź, czy działają kontenery powiązane z projektem (dostosuj filtry do nazw w Twoim docker-compose.yml):

```bash
docker ps -a --filter "name=GitLabCE"
docker ps -a --filter "name=Mailhog"
```

3. Usuń kontenery (jeżeli nadal istnieją):

```bash
docker rm GitLabCE Mailhog
```

4. Usuń powiązane obrazy Docker (⚠️ uwaga: usunięcie np. obrazu nginx:latest może wpłynąć na inne projekty!):

```bash
docker rmi gitlab-ce-ubuntu:latest
docker rmi mailhog/mailhog:latest
docker rmi nginx:latest
docker rmi cent-os-stream-image:latest
```

### 4.2 Czyszczenie wolumenów i konfiguracji

1. Z katalogu głównego projektu usuń dane generowane podczas pracy kontenerów.

Jeśli masz Makefile, możesz użyć uproszczonej komendy:

```bash
make cleanAll
```

2. Alternatywnie, ręcznie wykonaj skrypty czyszczące, w następującej kolejności:

```bash
./tools/bastion/clean-storage.sh 
./tools/gitlab/clean-storage.sh
./tools/gitlab/clean-before-config.sh
./tools/gitlab/clean-after-config.sh
./tools/remove-cert-ssl.sh
./tools/nginxReverseProxy/clean-nginx-storage.sh
```

> 🧠 Info:
Te operacje przywracają katalog storage/ do stanu początkowego, takiego jak po pobraniu projektu z repozytorium.
[2.1 Kopiowanie konfiguracji](#21-kopiowanie-konfiguracji).

---

## 📁 Struktura katalogów

```plaintext
.
├── BastionHost/
│   ├── bash/                                 # Skrypty, które można skopiować do Dockera w celu automatyzacji zadań
│   │   ├── add_ssh_key.sh                    # Kopiuje klucz SSH użytkownika devops (z kontenera Bastion) do Ansible (na kontenerze GitLab) do pliku authorized_keys. Wykorzystane są wolumeny.
│   │   ├── create_user.sh                    # Tworzy użytkownika (pierwszy parametr skryptu to nazwa użytkownika, drugi to hasło – domyślne to nazwa użytkownika) z uprawnieniami sudo.
│   │   └── generate_ssh_key.sh               # Generuje klucz SSH dla użytkownika, który uruchamia skrypt. Domyślna nazwa to {USER}-rsa-key, chyba że przekazana zostanie inna w pierwszym parametrze.
│   ├── ansible_aliases.sh                    # Skrypt dodający aliasy dla polecenia ansible
│   └── Dockerfile                            # Obraz bazujący na CentOS Stream 9 z preinstalowanym openSSH-server i Ansible
├── Gitlab/
│   ├── config/
│   │   ├── after-start/                      # Skrypty, które muszą być uruchomione po starcie GitLab'a
│   │   └── before-start/                     # Skrypty, które muszą być uruchomione przed startem GitLab'a, np. modyfikujące /etc/gitlab/gitlab.rb
│   ├── tools/                                # Narzędzia do konfiguracji GitLab'a po uruchomieniu, pełna lista narzędzi będzie opisana w dokumentacji modułu
│   │   └── groups/ (przykładowe)             # Przykładowe narzędzie do tworzenia grup w GitLabie
│   │   │   ├── bash/                         # Skrypty wykonywane z poziomu skryptu bash
│   │   │   │   └── .env                      # Plik konfiguracyjny / zmienne
│   │   │   │   └── create-by-gitlab-api.sh   # Skrypt tworzący grupy za pomocą GitLab API
│   │   │   │   └── delete-by-gitlab-api.sh   # Skrypt usuwający grupy za pomocą GitLab API
│   │   │   └── ansible/                      # Skrypty wykonywane za pomocą Ansible
│   │   │       └── (TODO)                    # ...
│   │   └── .../                              # Kolejne narzędzie z dostosowaną strukturą plików / katalogów wewnątrz
│   ├── configure-after-start.sh              # Skrypt sprawdzający gotowość GitLab'a i uruchamiający konfigurację z katalogu /gitlab-config/after (na Dockerze)
│   ├── configure-before-start.sh             # Skrypt sprawdzający gotowość GitLab'a i uruchamiający konfigurację z katalogu /gitlab-config/before (na Dockerze)
│   ├── Dockerfile                            # Obraz bazujący na Ubuntu 24 z preinstalowanym openSSH-server i GitLabem
│   └── startGitLab.sh                        # Skrypt uruchamiający GitLab'a oraz konfigurujący całe środowisko
├── nginxReverseProxy/
│   └── config/                               # Katalog z domyślną konfiguracją dla nginx
├── storage/                                  # Katalog związany z dostarczaniem plików do kontenerów oraz zapisywaniem stanu kontenera podczas restartów
│   └── a_bastion/                            # Wolumeny powiązane z kontenerem Bastion, prefiks "a_" aby były łatwo zarządzane
│   │   ├── ansible/                          # Playbooki i konfiguracje hostów, przekazane do kontenera w celu wykonania na infrastrukturze (/my-ansible/)
│   │   │   └── .gitkeep                      # Plik, aby folder mógł zostać wysłany do GitHub
│   │   ├── scripts/                          # Skrypty, które będą wykonywane z poziomu kontenera na innych maszynach w sieci (/my-scripts/)
│   │   │   └── .gitkeep                      # Plik, aby folder mógł zostać wysłany do GitHub
│   │   └── user/                             # Katalog z danymi użytkownika (np. klucze SSH)
│   │       └── devops/
│   └── gitlab/                               # Wolumeny powiązane z GitLabem (logi, dane, konfiguracja itd.)
│   │   ├── config/                           # Podmontowany folder z Dockera (/etc/gitlab)
│   │   ├── config-after-start/               # Podmontowany katalog do kontenera (/gitlab-config/after). Skrypty konfigurujące, które muszą być uruchomione po starcie GitLab'a
│   │   │   └── .gitkeep                      # Plik, aby folder mógł zostać wysłany do GitHub
│   │   ├── config-after-start-done/          # Podmontowany folder z Dockera (/gitlab-config/after-done), przechowuje wykonane skrypty, aby uniknąć powtarzania konfiguracji przy kolejnych startach
│   │   ├── config-before-start/              # Podmontowany katalog do kontenera (/gitlab-config/before). Skrypty konfigurujące, które muszą być uruchomione przed startem GitLab'a
│   │   │   └── .gitkeep                      # Plik, aby folder mógł zostać wysłany do GitHub
│   │   ├── config-before-start-done/         # Podmontowany folder z Dockera (/gitlab-config/before-done), przechowuje wykonane skrypty, aby uniknąć powtarzania konfiguracji przy kolejnych startach
│   │   ├── data/                             # Podmontowany katalog z Dockera (/var/opt/gitlab)
│   │   ├── etc/sudoers.d/                    # Podmontowany katalog z Dockera (/etc/sudoers.d)
│   │   ├── logs/                             # Podmontowany katalog z Dockera (/var/log/gitlab)
│   │   ├── ssh/                              # Podmontowany katalog z Dockera (/etc/ssh)
│   │   └── users/                            # Podmontowany katalog z Dockera (/home)
│   ├── nginxReverseProxy/                    # Wolumeny powiązane z nginx (konfiguracja)
│   │   └── config/                           # Konfiguracja
│   └── ssl/                                  # Wolumeny powiązane z certyfikatami (np. nginx i GitLab mogą korzystać z tego samego certyfikatu dla domeny gitlab.company.local)
│       └── gitlab/                           # Certyfikaty związane z GitLabem
├── tools/                                    # Narzędzia do konfiguracji
│   ├── bastion/                              # Dla Bastion host
│   ├── gitlab/                               # Dla GitLab'a
│   └── nginxReverseProxy/                    # Dla nginx'a
├── .gitignore                                # Plik ignorujący katalogi i pliki, które nie powinny trafić do repozytorium
├── docker-compose.yml                        # Główny plik uruchamiający środowisko
└── Makefile                                  # Automatyzuje zadania konfiguracyjne (zawarte w tools/)
└── README.md                                 # Dokumentacja projektu
```

📌 **Uwaga:**  
Foldery w storage/ są montowane jako wolumeny w docker-compose.yml, co pozwala zachować dane (repozytoria, użytkownicy, konfiguracja, logi) pomiędzy restartami kontenerów. Dzięki temu, nawet po restarcie kontenerów, wszystkie zmiany wprowadzone w tych folderach zostaną zachowane i dostępne.

---

## 📌 Notatki końcowe

### 🛠️ W przygotowaniu

- Projekt będzie rozwijany o nowe komponenty i funkcjonalności.
- Planowane jest wprowadzenie automatyzacji konfiguracji za pomocą narzędzi takich jak Ansible i Terraform. Automatyzacja będzie obejmować procesy takie jak provisioning, konfiguracja środowiska, zarządzanie infrastrukturą.
- Dokumentacja będzie dostępna również w wersji angielskiej, aby projekt był bardziej dostępny dla międzynarodowych użytkowników.

---

© Projekt edukacyjny tworzony w wolnym czasie.
