# ─────────────────────────────────────────────────────────────────────────────
# itlabs Developer Container – Windows Installer
# Einmalig ausführen: iex (iwr -useb '<raw-url>/install.ps1').Content
# ─────────────────────────────────────────────────────────────────────────────
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$ACR_NAME       = "itlabscr"
$IMAGE_NAME     = "itlabs-dev"
$IMAGE_TAG      = "latest"
$ADO_ORG        = "itlabsde"
$ADO_PROJECT    = "Konexi"
$ADO_REPO       = "itlabs-dev-docker"
$ADO_BRANCH     = "main"
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

if (-not (Test-CommandExists "az")) {
    $missing += "Azure CLI"
    Write-Host "  ✗ Azure CLI (az) nicht gefunden" -ForegroundColor Red
    Write-Host "    → Download: https://aka.ms/installazurecliwindows" -ForegroundColor Gray
} else {
    Write-Host "  ✓ Azure CLI gefunden" -ForegroundColor Green
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Bitte zuerst folgende Tools installieren und danach erneut ausführen:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
}

# ── 2. Azure Login ─────────────────────────────────────────────────────────────
Write-Section "Azure Login"

Write-Host "Prüfe ob du bereits eingeloggt bist..."
$account = $null
try { $account = az account show 2>$null | ConvertFrom-Json } catch {}

if ($null -eq $account) {
    Write-Host "Ein Browser-Fenster öffnet sich für den Azure Login..." -ForegroundColor Yellow
    az login --output none
    $account = az account show | ConvertFrom-Json
}

Write-Host "  ✓ Eingeloggt als: $($account.user.name)" -ForegroundColor Green

# ── 3. ACR Login ───────────────────────────────────────────────────────────────
Write-Section "Azure Container Registry Login"

Write-Host "Verbinde mit ${ACR_NAME}.azurecr.io ..."
az acr login --name $ACR_NAME
Write-Host "  ✓ ACR Login erfolgreich" -ForegroundColor Green

# ── 4. docker-compose.yml herunterladen ──────────────────────────────────────
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

Write-Host "Lade docker-compose.yml aus Azure DevOps..."

$adoRawUrl = "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_apis/git/repositories/$ADO_REPO/items?path=docker-compose.yml&versionDescriptor.version=$ADO_BRANCH&api-version=7.1"

$token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv
$headers = @{ Authorization = "Bearer $token" }

try {
    Invoke-WebRequest -Uri $adoRawUrl -Headers $headers -OutFile $COMPOSE_FILE -UseBasicParsing
    Write-Host "  ✓ docker-compose.yml heruntergeladen: $COMPOSE_FILE" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Download fehlgeschlagen: $_" -ForegroundColor Red
    Write-Host "    Stelle sicher, dass dein Azure-Account Zugriff auf das ADO-Repo hat." -ForegroundColor Gray
    exit 1
}

# ── 5. Image pullen ────────────────────────────────────────────────────────────
Write-Section "Docker Image laden"

Write-Host "Lade Image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} ..."
Write-Host "(Das kann beim ersten Mal einige Minuten dauern)" -ForegroundColor Gray

Set-Location $INSTALL_DIR
docker compose pull

Write-Host "  ✓ Image erfolgreich geladen" -ForegroundColor Green

# ── 6. Container starten ───────────────────────────────────────────────────────
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
