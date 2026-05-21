# ─────────────────────────────────────────────────────────────────────────────
# itlabs Developer Container – Windows Installer
# Einmalig ausführen: iex (iwr -useb 'https://raw.githubusercontent.com/itlabs-gmbh/itlabs-dev-docker/main/install.ps1').Content
# ─────────────────────────────────────────────────────────────────────────────
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$GITHUB_ORG     = "itlabs-gmbh"
$GITHUB_REPO    = "itlabs-dev-docker"
$GITHUB_BRANCH  = "main"
$INSTALL_DIR    = "$env:USERPROFILE\itlabs-dev"
$COMPOSE_FILE   = "$INSTALL_DIR\docker-compose.yml"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       itlabs Developer Container – Einrichtung          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section($title) {
    Write-Host ""
    Write-Host "── $title ─────────────────────────────────────────────────" -ForegroundColor Yellow
}

function Test-CommandExists($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ── Start ─────────────────────────────────────────────────────────────────────
Write-Header

# ── 1. Voraussetzungen prüfen ─────────────────────────────────────────────────
Write-Section "Voraussetzungen prüfen"

$missing = @()

if (-not (Test-CommandExists "docker")) {
    $missing += "Docker Desktop"
    Write-Host "  ✗ Docker Desktop nicht gefunden" -ForegroundColor Red
    Write-Host "    → Download: https://www.docker.com/products/docker-desktop/" -ForegroundColor Gray
} else {
    $dockerRunning = $false
    try { docker info 2>&1 | Out-Null; $dockerRunning = $true } catch {}
    if ($dockerRunning) {
        Write-Host "  ✓ Docker Desktop gefunden und läuft" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Docker Desktop gefunden, aber nicht gestartet" -ForegroundColor Red
        Write-Host "    → Bitte Docker Desktop starten und nochmals ausführen" -ForegroundColor Gray
        $missing += "Docker Desktop (nicht gestartet)"
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Bitte zuerst folgende Tools installieren und danach erneut ausführen:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host ""
    Read-Host "Drücke Enter zum Schließen"
    return
}

# ── 2. docker-compose.yml herunterladen ──────────────────────────────────────
Write-Section "Konfiguration herunterladen"

if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR | Out-Null
    Write-Host "  ✓ Ordner erstellt: $INSTALL_DIR" -ForegroundColor Green
} else {
    Write-Host "  ✓ Ordner vorhanden: $INSTALL_DIR" -ForegroundColor Green
}

# workspace-Ordner anlegen (wird in Container gemountet)
$workspaceDir = "$INSTALL_DIR\workspace"
if (-not (Test-Path $workspaceDir)) {
    New-Item -ItemType Directory -Path $workspaceDir | Out-Null
    Write-Host "  ✓ workspace-Ordner erstellt: $workspaceDir" -ForegroundColor Green
}

$githubRawUrl = "https://raw.githubusercontent.com/$GITHUB_ORG/$GITHUB_REPO/$GITHUB_BRANCH/docker-compose.yml"
Write-Host "Lade docker-compose.yml von GitHub..."

try {
    Invoke-WebRequest -Uri $githubRawUrl -OutFile $COMPOSE_FILE -UseBasicParsing
    Write-Host "  ✓ docker-compose.yml heruntergeladen: $COMPOSE_FILE" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Download fehlgeschlagen: $_" -ForegroundColor Red
    Write-Host "    URL: $githubRawUrl" -ForegroundColor Gray
    Read-Host "Drücke Enter zum Schließen"
    return
}

# ── 3. Image pullen ──────────────────────────────────────────────────────────────
Write-Section "Docker Image laden"

Write-Host "Lade Image ghcr.io/itlabs-gmbh/itlabs-dev:latest ..."
Write-Host "(Das kann beim ersten Mal einige Minuten dauern)" -ForegroundColor Gray

Set-Location $INSTALL_DIR
docker compose pull

Write-Host "  ✓ Image erfolgreich geladen" -ForegroundColor Green

# ── 4. Container starten ───────────────────────────────────────────────────────
Write-Section "Container starten"

Write-Host "Starte itlabs Developer Container..."
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅  Einrichtung abgeschlossen!                          ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  Der Container startet gleich.                           ║" -ForegroundColor Green
Write-Host "║  Beim ersten Start läuft ein kurzes Setup durch.         ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  Nächstes Mal Container starten:                         ║" -ForegroundColor Green
Write-Host "║    cd $INSTALL_DIR" -ForegroundColor Green
Write-Host "║    docker compose run --rm dev                           ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

docker compose run --rm dev
