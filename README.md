# itlabs Developer Container

Ein Docker-Container mit allem, was für die itlabs-Entwicklung benötigt wird.

---

## 🚀 Schnellstart (für alle – kein technisches Vorwissen nötig)

### Schritt 1 – Voraussetzungen installieren

Einmalig installieren, falls noch nicht vorhanden:

| Tool                                                              | Download                                        |
| ----------------------------------------------------------------- | ----------------------------------------------- |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | https://www.docker.com/products/docker-desktop/ |
| [Azure CLI](https://aka.ms/installazurecliwindows)                | https://aka.ms/installazurecliwindows           |

> **Wichtig:** Docker Desktop nach der Installation starten und sicherstellen, dass es läuft (Whale-Icon in der Taskleiste).

### Schritt 2 – Installer ausführen

**Windows** – PowerShell als normaler Benutzer öffnen und ausführen:

```powershell
irm https://dev.azure.com/itlabsde/Konexi/_apis/git/repositories/itlabs-dev-docker/items?path=install.ps1&versionDescriptor.version=main&api-version=7.1 | iex
```

**macOS / Linux** – Terminal öffnen und ausführen:

```bash
curl -fsSL "https://dev.azure.com/itlabsde/Konexi/_apis/git/repositories/itlabs-dev-docker/items?path=install.sh&versionDescriptor.version=main&api-version=7.1" | bash
```

> Ein Browser-Fenster öffnet sich für den Azure Login – dort mit dem itlabs-Account anmelden. Der Rest läuft automatisch.

### Nächstes Mal starten

```powershell
# Windows
cd $env:USERPROFILE\itlabs-dev
docker compose run --rm dev
```

```bash
# macOS / Linux
cd ~/itlabs-dev && docker compose run --rm dev
```

---

## Enthält

| Tool                                               | Version                               |
| -------------------------------------------------- | ------------------------------------- |
| Ubuntu                                             | 24.04 LTS                             |
| git                                                | aktuell aus apt                       |
| nvm                                                | v0.40.3                               |
| Node.js                                            | LTS (aktuellste stabile Version)      |
| npm                                                | (mit Node gebündelt)                  |
| Claude Code                                        | aktuell (`@anthropic-ai/claude-code`) |
| Azure CLI (`az`)                                   | aktuell                               |
| zsh + oh-my-zsh                                    | aktuell                               |
| build-essential, curl, wget, jq, unzip, ssh-client | aktuell                               |

---

## Voraussetzungen

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installiert

> **Windows:** Docker Desktop mit WSL2-Backend verwenden. Befehle in **Git Bash** oder **WSL2** ausführen (nicht PowerShell/CMD) – `make` und der SSH Agent (`SSH_AUTH_SOCK`) funktionieren dort korrekt. In PowerShell ist SSH-Forwarding nicht verfügbar (kein `SSH_AUTH_SOCK`), alles andere funktioniert.

---

## Container starten

### 1. Repository klonen

```bash
git clone <repo-url>
cd itlabs-dev-docker
```

### 2. Container bauen und starten

```bash
make run
```

Das Image wird beim ersten Aufruf automatisch lokal gebaut. Der `workspace/`-Ordner im Repository wird in den Container gemountet.

---

## Ersteinrichtung (automatisch beim ersten Start)

Beim ersten Containerstart läuft `itlabs-setup` automatisch und führt durch:

1. **SSH Key** – wird generiert und der Public Key angezeigt (in Azure DevOps hinterlegen)
2. **`.npmrc`** – wird mit einem ADO Personal Access Token für den itlabs Artifact Feed konfiguriert

Der Setup-Status wird in `~/.itlabs-setup-done` gespeichert (im `dev-home`-Volume, überlebt Container-Neustarts).

---

## Claude Code nutzen

Der Inference-Endpoint und Token sind bereits in `docker-compose.yml` vorkonfiguriert. Einfach den Container starten und im Container aufrufen:

```bash
# Standard Claude (konfigurierter Endpoint)
claude

# itlabs-Modell (Qwen)
claude-itlabs
```

---

## Git-Konfiguration

Die lokale `~/.gitconfig` wird automatisch read-only in den Container gemountet.
Alternativ manuell im Container setzen:

```bash
git config --global user.name "Dein Name"
git config --global user.email "dein@email.com"
```

---

## Für Maintainer: Image bauen und pushen

### Einmalige Konfiguration

Passe in der `Makefile` den `ACR_NAME` an:

```makefile
ACR_NAME ?= yourregistry   # ← hier den echten Registry-Namen eintragen
```

### Build & Push

```bash
make push
# oder mit explizitem Tag:
make push IMAGE_TAG=1.0.0
```

### Alle Make-Targets

```
make help
```
