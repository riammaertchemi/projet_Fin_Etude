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

$cssBackup = "$homeCssPath.bak-texte-noir"
if (-not (Test-Path $cssBackup)) {
    Copy-Item $homeCssPath $cssBackup
    Write-Host "Sauvegarde creee : $cssBackup" -ForegroundColor DarkGray
}

$css = [System.IO.File]::ReadAllText((Resolve-Path $homeCssPath), [System.Text.Encoding]::UTF8)

# --- 1. Texte du chiffre en noir ---
$pattern = "\.stat-value \{[^\}]*\}"
$m = [regex]::Matches($css, $pattern)
if ($m.Count -ne 1) {
    Write-Host "ERREUR : bloc .stat-value introuvable ou ambigu (trouve $($m.Count) fois)." -ForegroundColor Red
    exit 1
}
$block = $m[0].Value
if ($block -match 'color:\s*#111827') {
    Write-Host "home.css : .stat-value est deja en noir, rien a changer ici." -ForegroundColor Yellow
} else {
    $newBlock = $block -replace '(\r?\n\})$', "`n  color: #111827;`n  text-shadow: 0 1px 2px rgba(255,255,255,0.85);`$1"
    $css = $css.Remove($m[0].Index, $m[0].Length).Insert($m[0].Index, $newBlock)
    Write-Host "  OK : .stat-value en noir." -ForegroundColor Green
}

# --- 2. Texte du libelle (Produits, Categories, ...) en noir ---
$pattern = "\.stat-label \{[^\}]*\}"
$m = [regex]::Matches($css, $pattern)
if ($m.Count -ne 1) {
    Write-Host "ERREUR : bloc .stat-label introuvable ou ambigu (trouve $($m.Count) fois)." -ForegroundColor Red
    exit 1
}
$block = $m[0].Value
if ($block -match 'color:\s*#111827') {
    Write-Host "home.css : .stat-label est deja en noir, rien a changer ici." -ForegroundColor Yellow
} else {
    $newBlock = $block -replace '(\r?\n\})$', "`n  color: #111827;`n  text-shadow: 0 1px 2px rgba(255,255,255,0.85);`$1"
    $css = $css.Remove($m[0].Index, $m[0].Length).Insert($m[0].Index, $newBlock)
    Write-Host "  OK : .stat-label en noir." -ForegroundColor Green
}

# --- 3. Couleur des cartes un peu plus soutenue ---
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
  background: linear-gradient(180deg, rgba($($o.C1),0) 0%, rgba($($o.C1),0) 55%, rgba($($o.C2),0.55) 100%);
}
"@

    $css = $css.Remove($m2[0].Index, $m2[0].Length).Insert($m2[0].Index, $newBlock2)
    Write-Host "  OK : carte $($o.Name) -> couleur renforcee." -ForegroundColor Green
}

[System.IO.File]::WriteAllText((Resolve-Path $homeCssPath), $css, $utf8NoBom)
Write-Host "home.css mis a jour." -ForegroundColor Green

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : texte noir, couleur renforcee." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Relance 'ng serve' (ou rafraichis la page) pour voir le resultat." -ForegroundColor Cyan
Write-Host ""
