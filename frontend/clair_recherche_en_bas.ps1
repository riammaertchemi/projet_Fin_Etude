$ErrorActionPreference = "Stop"

if (-not (Test-Path "src\app\app.ts")) {
    Write-Host "ERREUR : ce script doit etre execute depuis la racine du projet 'albideynet-frontend' (le dossier qui contient 'src')." -ForegroundColor Red
    exit 1
}

$homeCssPath = "src\app\pages\home\home.css"

if (-not (Test-Path $homeCssPath)) {
    Write-Host "ERREUR : fichier introuvable : $homeCssPath" -ForegroundColor Red
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$cssBackup = "$homeCssPath.bak-bas-clair"
if (-not (Test-Path $cssBackup)) {
    Copy-Item $homeCssPath $cssBackup
    Write-Host "Sauvegarde creee : $cssBackup" -ForegroundColor DarkGray
}

$css = [System.IO.File]::ReadAllText((Resolve-Path $homeCssPath), [System.Text.Encoding]::UTF8)

# --- 1. .stat-card devient un conteneur flex vertical (pour coller la recherche en bas) ---
if ($css -match 'flex-direction:\s*column' -and $css -match '\.stat-card \{[^\}]*flex-direction') {
    Write-Host "home.css : .stat-card est deja en colonne flex, rien a changer ici." -ForegroundColor Yellow
} else {
    $pattern = "\.stat-card \{[^\}]*\}"
    $m = [regex]::Matches($css, $pattern)
    if ($m.Count -ne 1) {
        Write-Host "ERREUR : bloc .stat-card introuvable ou ambigu (trouve $($m.Count) fois)." -ForegroundColor Red
        exit 1
    }
    $block = $m[0].Value
    $newBlock = $block -replace '(\r?\n\})$', "`n  display: flex;`n  flex-direction: column;`$1"
    $css = $css.Remove($m[0].Index, $m[0].Length).Insert($m[0].Index, $newBlock)
    Write-Host "  OK : .stat-card en colonne flex." -ForegroundColor Green
}

# --- 2. .stat-card-link grandit pour occuper l'espace restant, poussant la recherche tout en bas ---
$pattern = "\.stat-card-link \{[^\}]*\}"
$m = [regex]::Matches($css, $pattern)
if ($m.Count -ne 1) {
    Write-Host "ERREUR : bloc .stat-card-link introuvable ou ambigu (trouve $($m.Count) fois)." -ForegroundColor Red
    exit 1
}
$block = $m[0].Value
if ($block -match 'flex:\s*1') {
    Write-Host "home.css : .stat-card-link a deja flex:1, rien a changer ici." -ForegroundColor Yellow
} else {
    $newBlock = $block -replace '(\r?\n\})$', "`n  flex: 1 1 auto;`$1"
    $css = $css.Remove($m[0].Index, $m[0].Length).Insert($m[0].Index, $newBlock)
    Write-Host "  OK : .stat-card-link pousse la recherche vers le bas." -ForegroundColor Green
}

# --- 3. Couleur beaucoup plus claire sur chaque carte ---
$overlays = @(
    @{ Name = "products";   Selector = "\.stat-card\.products \.stat-card-overlay";     C1 = "99,102,241";  C2 = "79,70,229" },
    @{ Name = "categories"; Selector = "\.stat-card\.categories \.stat-card-overlay";   C1 = "20,184,166";  C2 = "13,148,136" },
    @{ Name = "suppliers";  Selector = "\.stat-card\.suppliers \.stat-card-overlay";    C1 = "245,158,11";  C2 = "217,119,6" },
    @{ Name = "movements";  Selector = "\.stat-card\.movements \.stat-card-overlay";    C1 = "139,92,246";  C2 = "124,58,237" },
    @{ Name = "alerts";     Selector = "\.stat-card\.alerts \.stat-card-overlay";       C1 = "244,63,94";   C2 = "225,29,72" }
)

foreach ($o in $overlays) {
    $pattern2 = "$($o.Selector) \{[^\}]*\}"
    $m2 = [regex]::Matches($css, $pattern2)
    if ($m2.Count -eq 0) {
        Write-Host "ATTENTION : bloc CSS introuvable pour la carte $($o.Name), ignore." -ForegroundColor Yellow
        continue
    }
    if ($m2.Count -gt 1) {
        Write-Host "ERREUR : bloc CSS trouve $($m2.Count) fois (attendu 1) pour la carte $($o.Name)." -ForegroundColor Red
        exit 1
    }

    $selectorText = $o.Selector -replace '\\', ''
    $newBlock2 = @"
$selectorText {
  background: linear-gradient(180deg, rgba($($o.C1),0) 0%, rgba($($o.C1),0) 55%, rgba($($o.C2),0.35) 100%);
}
"@

    $css = $css.Remove($m2[0].Index, $m2[0].Length).Insert($m2[0].Index, $newBlock2)
    Write-Host "  OK : carte $($o.Name) -> couleur tres claire." -ForegroundColor Green
}

[System.IO.File]::WriteAllText((Resolve-Path $homeCssPath), $css, $utf8NoBom)
Write-Host "home.css mis a jour." -ForegroundColor Green

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : recherche en bas, couleur tres claire." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Relance 'ng serve' (ou rafraichis la page) pour voir le resultat." -ForegroundColor Cyan
Write-Host ""
