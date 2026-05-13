# itlabs Developer Container

Ein Docker-Container mit allem, was für die itlabs-Entwicklung benötigt wird.

---

## 🚀 Schnellstart (für alle – kein technisches Vorwissen nötig)

### Schritt 1 – Voraussetzungen installieren

Einmalig installieren, falls noch nicht vorhanden:

| Tool                                                              | Download                                        |
| ----------------------------------------------------------------- | ----------------------------------------------- |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | https://www.docker.com/products/docker-desktop/ |

> **Wichtig:** Docker Desktop nach der Installation starten und sicherstellen, dass es läuft (Whale-Icon in der Taskleiste).

### Schritt 2 – Installer ausführen

**Windows** – PowerShell als normaler Benutzer öffnen und ausführen:

```powershell
iex (iwr -useb 'https://raw.githubusercontent.com/itlabs-gmbh/itlabs-dev-docker/main/install.ps1').Content
```

**macOS / Linux** – Terminal öffnen und ausführen:

```bash
curl -fsSL 'https://raw.githubusercontent.com/itlabs-gmbh/itlabs-dev-docker/main/install.sh' | bash
```

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
git clone https://github.com/itlabs-gmbh/itlabs-dev-docker.git
cd itlabs-dev-docker
```

### 2. Container starten

```bash
make run
```

Das Image wird automatisch von GHCR gepullt. Der `workspace/`-Ordner im Repository wird in den Container gemountet.

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

Das Image wird automatisch über GitHub Actions bei jedem Push auf `main` gebaut und nach `ghcr.io/itlabs-gmbh/itlabs-dev:latest` gepusht.

Lokal bauen (für Tests):

```bash
make build
```

### Alle Make-Targets

```
make help
```
