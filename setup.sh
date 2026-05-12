#!/bin/zsh
# ─────────────────────────────────────────────────────────────────────────────
# itlabs Developer Container – First-run setup
# Runs automatically on container start if setup is incomplete.
# ─────────────────────────────────────────────────────────────────────────────

SETUP_DONE_FILE="$HOME/.itlabs-setup-done"
SSH_KEY="$HOME/.ssh/id_rsa"
NPMRC="$HOME/.npmrc"

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║        itlabs Developer Container – Ersteinrichtung     ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
}

print_section() {
  echo ""
  echo "── $1 ─────────────────────────────────────────────────────"
}

# ── Already done? ─────────────────────────────────────────────────────────────
if [[ -f "$SETUP_DONE_FILE" ]]; then
  return 0 2>/dev/null || exit 0
fi

print_header

# ─────────────────────────────────────────────────────────────────────────────
# 1. PAT
# ─────────────────────────────────────────────────────────────────────────────
print_section "Azure DevOps Personal Access Token (PAT)"

echo "Du benötigst einen PAT mit folgenden Berechtigungen:"
echo "  • Packaging        → Read"
echo "  • User Profile     → Read & write  (für SSH Key Upload)"
echo ""
echo "PAT erstellen unter:"
echo "  https://dev.azure.com/itlabsde/_usersSettings/tokens"
echo ""
read -rs "ADO_PAT?Bitte ADO PAT eingeben (wird nicht angezeigt): "
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 2. SSH Key
# ─────────────────────────────────────────────────────────────────────────────
print_section "SSH Key"

if [[ ! -f "$SSH_KEY" ]]; then
  echo "Kein SSH Key gefunden – wird generiert..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -q
  echo "✅ SSH Key erstellt: $SSH_KEY"
else
  echo "✅ SSH Key bereits vorhanden: $SSH_KEY"
fi

if [[ -n "$ADO_PAT" ]]; then
  echo "SSH Key wird automatisch in ADO hinterlegt..."
  PUB_KEY=$(cat "${SSH_KEY}.pub")
  HTTP_STATUS=$(curl -s -o /tmp/ado_ssh_response.json -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $(echo -n ":${ADO_PAT}" | base64)" \
    "https://vssps.dev.azure.com/itlabsde/_apis/ssh?api-version=7.1" \
    -d "{\"publicData\":\"${PUB_KEY}\",\"description\":\"itlabs-dev-container\"}")

  if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "201" ]]; then
    echo "✅ SSH Key in ADO hinterlegt."
  else
    echo "⚠️  SSH Key Upload fehlgeschlagen (HTTP $HTTP_STATUS)."
    echo "    Bitte manuell hinterlegen:"
    echo "    https://dev.azure.com/itlabsde/_usersSettings/keys"
    echo ""
    echo "┌─ Dein Public Key ──────────────────────────────────────────────────────┐"
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
    echo "└────────────────────────────────────────────────────────────────────────┘"
    echo ""
    read -r "?[Enter] drücken wenn der Key in ADO hinterlegt wurde..."
  fi
else
  echo ""
  echo "┌─ Dein Public Key (in ADO hinterlegen) ─────────────────────────────────┐"
  echo ""
  cat "${SSH_KEY}.pub"
  echo ""
  echo "└─────────────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "👉  Azure DevOps → User Settings → SSH Public Keys → New Key"
  echo "    https://dev.azure.com/itlabsde/_usersSettings/keys"
  echo ""
  read -r "?[Enter] drücken wenn der Key in ADO hinterlegt wurde..."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. .npmrc für ADO Artifacts
# ─────────────────────────────────────────────────────────────────────────────
print_section ".npmrc (ADO Artifacts)"

if [[ ! -f "$NPMRC" ]]; then
  echo "Kein .npmrc gefunden – wird erstellt."
  echo ""

  if [[ -z "$ADO_PAT" ]]; then
    echo "⚠️  Kein PAT vorhanden – .npmrc wird übersprungen."
    echo "    Führe später 'itlabs-setup' aus um nachzuholen."
  else
    ENCODED_PAT=$(echo -n "$ADO_PAT" | base64)
    cat > "$NPMRC" <<EOF
; Azure DevOps Artifacts – generiert von itlabs-setup
@alberta:registry=https://pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/registry/

always-auth=true

; ADO Artifacts Auth
//pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/registry/:username=itlabs
//pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/registry/:_password=${ENCODED_PAT}
//pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/registry/:email=npm@itlabs.at

//pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/:username=itlabs
//pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/:_password=${ENCODED_PAT}
//pkgs.dev.azure.com/itlabsde/_packaging/itlabs/npm/:email=npm@itlabs.at
EOF
    echo "✅ .npmrc erstellt: $NPMRC"
  fi
else
  echo "✅ .npmrc bereits vorhanden: $NPMRC"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅  Setup abgeschlossen – viel Spaß beim Entwickeln!   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

touch "$SETUP_DONE_FILE"
