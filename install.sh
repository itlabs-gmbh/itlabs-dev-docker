#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# itlabs Developer Container – macOS / Linux Installer
# Einmalig ausführen:
#   bash <(curl -fsSL '<raw-url>/install.sh')
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ACR_NAME="itlabscr"
IMAGE_NAME="itlabs-dev"
IMAGE_TAG="latest"
ADO_ORG="itlabsde"
ADO_PROJECT="Konexi"
ADO_REPO="itlabs-dev-docker"
ADO_BRANCH="main"
INSTALL_DIR="$HOME/itlabs-dev"
COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║       itlabs Developer Container – Einrichtung          ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
}

print_section() {
  echo ""
  echo "── $1 ─────────────────────────────────────────────────────"
}

print_ok()   { echo "  ✓ $1"; }
print_warn() { echo "  ⚠  $1"; }
print_err()  { echo "  ✗ $1" >&2; }

command_exists() { command -v "$1" &>/dev/null; }

# ── Start ─────────────────────────────────────────────────────────────────────
print_header

# ── 1. Voraussetzungen prüfen ─────────────────────────────────────────────────
print_section "Voraussetzungen prüfen"

MISSING=()

if ! command_exists docker; then
  print_err "Docker Desktop nicht gefunden"
  echo "    → Download: https://www.docker.com/products/docker-desktop/"
  MISSING+=("Docker Desktop")
else
  if docker info &>/dev/null; then
    print_ok "Docker Desktop gefunden und läuft"
  else
    print_err "Docker Desktop gefunden, aber nicht gestartet"
    echo "    → Bitte Docker Desktop starten und nochmals ausführen"
    MISSING+=("Docker Desktop (nicht gestartet)")
  fi
fi

if ! command_exists az; then
  print_err "Azure CLI (az) nicht gefunden"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "    → Installation: brew install azure-cli"
  else
    echo "    → Download: https://learn.microsoft.com/cli/azure/install-azure-cli"
  fi
  MISSING+=("Azure CLI")
else
  print_ok "Azure CLI gefunden"
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "Bitte zuerst folgende Tools installieren und danach erneut ausführen:"
  for item in "${MISSING[@]}"; do echo "  • $item"; done
  echo ""
  exit 1
fi

# ── 2. Azure Login ─────────────────────────────────────────────────────────────
print_section "Azure Login"

echo "Prüfe ob du bereits eingeloggt bist..."
if ! az account show &>/dev/null; then
  echo "Ein Browser-Fenster öffnet sich für den Azure Login..."
  az login --output none
fi

ACCOUNT_NAME=$(az account show --query user.name -o tsv)
print_ok "Eingeloggt als: $ACCOUNT_NAME"

# ── 3. ACR Login ───────────────────────────────────────────────────────────────
print_section "Azure Container Registry Login"

echo "Verbinde mit ${ACR_NAME}.azurecr.io ..."
az acr login --name "$ACR_NAME"
print_ok "ACR Login erfolgreich"

# ── 4. docker-compose.yml herunterladen ──────────────────────────────────────
print_section "Konfiguration herunterladen"

mkdir -p "$INSTALL_DIR"
print_ok "Ordner: $INSTALL_DIR"

mkdir -p "$INSTALL_DIR/workspace"
print_ok "workspace-Ordner: $INSTALL_DIR/workspace"

echo "Lade docker-compose.yml aus Azure DevOps..."

ADO_RAW_URL="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/git/repositories/${ADO_REPO}/items?path=docker-compose.yml&versionDescriptor.version=${ADO_BRANCH}&api-version=7.1"
TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)

if ! curl -fsSL -H "Authorization: Bearer $TOKEN" "$ADO_RAW_URL" -o "$COMPOSE_FILE"; then
  print_err "Download fehlgeschlagen"
  echo "    Stelle sicher, dass dein Azure-Account Zugriff auf das ADO-Repo hat."
  exit 1
fi

print_ok "docker-compose.yml heruntergeladen: $COMPOSE_FILE"

# ── 5. Image pullen ────────────────────────────────────────────────────────────
print_section "Docker Image laden"

echo "Lade Image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ..."
echo "(Das kann beim ersten Mal einige Minuten dauern)"

cd "$INSTALL_DIR"
docker compose pull

print_ok "Image erfolgreich geladen"

# ── 6. Container starten ───────────────────────────────────────────────────────
print_section "Container starten"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅  Einrichtung abgeschlossen!                          ║"
echo "║                                                          ║"
echo "║  Der Container startet gleich.                           ║"
echo "║  Beim ersten Start läuft ein kurzes Setup durch.         ║"
echo "║                                                          ║"
echo "║  Nächstes Mal Container starten:                         ║"
echo "║    cd ~/itlabs-dev && docker compose run --rm dev        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

docker compose run --rm dev
