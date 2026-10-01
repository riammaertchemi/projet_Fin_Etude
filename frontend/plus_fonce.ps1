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

$cssBackup = "$homeCssPath.bak-plus-fonce"
if (-not (Test-Path $cssBackup)) {
    Copy-Item $homeCssPath $cssBackup
    Write-Host "Sauvegarde creee : $cssBackup" -ForegroundColor DarkGray
}

$css = [System.IO.File]::ReadAllText((Resolve-Path $homeCssPath), [System.Text.Encoding]::UTF8)

# --- 1. Texte du chiffre en noir pur ---
$pattern = "\.stat-value \{[^\}]*\}"
$m = [regex]::Matches($css, $pattern)
if ($m.Count -ne 1) {
    Write-Host "ERREUR : bloc .stat-value introuvable ou ambigu (trouve $($m.Count) fois)." -ForegroundColor Red
    exit 1
}
$block = $m[0].Value
$newBlock = $block -replace 'color:\s*#111827;', 'color: #000000;'
if ($newBlock -eq $block) {
    Write-Host "ATTENTION : impossible de trouver 'color: #111827;' dans .stat-value, ignore." -ForegroundColor Yellow
} else {
    $css = $css.Remove($m[0].Index, $m[0].Length).Insert($m[0].Index, $newBlock)
    Write-Host "  OK : .stat-value en noir pur." -ForegroundColor Green
}

# --- 2. Texte du libelle en noir pur ---
$pattern = "\.stat-label \{[^\}]*\}"
$m = [regex]::Matches($css, $pattern)
if ($m.Count -ne 1) {
    Write-Host "ERREUR : bloc .stat-label introuvable ou ambigu (trouve $($m.Count) fois)." -ForegroundColor Red
    exit 1
}
$block = $m[0].Value
$newBlock = $block -replace 'color:\s*#111827;', 'color: #000000;'
if ($newBlock -eq $block) {
    Write-Host "ATTENTION : impossible de trouver 'color: #111827;' dans .stat-label, ignore." -ForegroundColor Yellow
} else {
    $css = $css.Remove($m[0].Index, $m[0].Length).Insert($m[0].Index, $newBlock)
    Write-Host "  OK : .stat-label en noir pur." -ForegroundColor Green
}

# --- 3. Couleur des cartes encore plus soutenue ---
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
  background: linear-gradient(180deg, rgba($($o.C1),0) 0%, rgba($($o.C1),0) 50%, rgba($($o.C2),0.84) 100%);
}
"@

    $css = $css.Remove($m2[0].Index, $m2[0].Length).Insert($m2[0].Index, $newBlock2)
    Write-Host "  OK : carte $($o.Name) -> couleur plus foncee." -ForegroundColor Green
}

[System.IO.File]::WriteAllText((Resolve-Path $homeCssPath), $css, $utf8NoBom)
Write-Host "home.css mis a jour." -ForegroundColor Green

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : couleur plus foncee, texte en noir pur." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Relance 'ng serve' (ou rafraichis la page) pour voir le resultat." -ForegroundColor Cyan
Write-Host ""
