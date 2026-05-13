#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# itlabs Developer Container – macOS / Linux Installer
# Einmalig ausführen:
#   bash <(curl -fsSL 'https://raw.githubusercontent.com/itlabs-gmbh/itlabs-dev-docker/main/install.sh')
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

GITHUB_ORG="itlabs-gmbh"
GITHUB_REPO="itlabs-dev-docker"
GITHUB_BRANCH="main"
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

if ! command_exists curl; then
  print_err "curl nicht gefunden"
  MISSING+=("curl")
else
  print_ok "curl gefunden"
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "Bitte zuerst folgende Tools installieren und danach erneut ausführen:"
  for item in "${MISSING[@]}"; do echo "  • $item"; done
  echo ""
  exit 1
fi

# ── 2. docker-compose.yml herunterladen ──────────────────────────────────────
print_section "Konfiguration herunterladen"

mkdir -p "$INSTALL_DIR"
print_ok "Ordner: $INSTALL_DIR"

mkdir -p "$INSTALL_DIR/workspace"
print_ok "workspace-Ordner: $INSTALL_DIR/workspace"

GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/${GITHUB_BRANCH}/docker-compose.yml"
echo "Lade docker-compose.yml von GitHub..."

if ! curl -fsSL "$GITHUB_RAW_URL" -o "$COMPOSE_FILE"; then
  print_err "Download fehlgeschlagen"
  echo "    URL: $GITHUB_RAW_URL"
  exit 1
fi

print_ok "docker-compose.yml heruntergeladen: $COMPOSE_FILE"

# ── 3. Image pullen ────────────────────────────────────────────────────────────
print_section "Docker Image laden"

echo "Lade Image ghcr.io/itlabs-gmbh/itlabs-dev:latest ..."
echo "(Das kann beim ersten Mal einige Minuten dauern)"

cd "$INSTALL_DIR"
docker compose pull

print_ok "Image erfolgreich geladen"

# ── 4. Container starten ───────────────────────────────────────────────────────
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
