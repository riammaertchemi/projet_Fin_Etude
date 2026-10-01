# =========================================================================
# Script : renommer_titres_pages.ps1
# Objet  : Change le titre affiche en haut des 4 pages (en francais) :
#            Produits             -> Liste des produits
#            Categories           -> Liste des categories
#            Fournisseurs         -> Liste des fournisseurs
#            Mouvements de stock  -> Liste des mouvements de stock
#          Modifie uniquement src\app\services\translations.ts (les textes
#          anglais et arabes ne sont pas touches).
#
# A executer depuis la racine du projet : albideynet-frontend
# (le dossier qui contient le sous-dossier "src")
# =========================================================================

$ErrorActionPreference = "Stop"

if (-not (Test-Path "src\app\app.ts")) {
    Write-Host "ERREUR : ce script doit etre execute depuis la racine du projet 'albideynet-frontend' (le dossier qui contient 'src')." -ForegroundColor Red
    Write-Host "Fais d'abord : cd chemin\vers\albideynet-frontend" -ForegroundColor Yellow
    exit 1
}

$path = "src\app\services\translations.ts"

if (-not (Test-Path $path)) {
    Write-Host "ERREUR : $path est introuvable." -ForegroundColor Red
    exit 1
}

Write-Host "Sauvegarde de $path (.bak-titres) ..." -ForegroundColor Cyan
Copy-Item $path "$path.bak-titres" -Force

$content = Get-Content -Path $path -Raw

# Le "e" accentue est construit a partir de son code Unicode plutot que
# tape directement, pour eviter tout probleme d'encodage lors du
# copier-coller de ce script dans le Bloc-notes.
$e = [char]0x00E9

$pairs = @(
    @{ old = '"products.title": "Produits",';                    new = '"products.title": "Liste des produits",' },
    @{ old = ('"categories.title": "Cat' + $e + 'gories",');      new = ('"categories.title": "Liste des cat' + $e + 'gories",') },
    @{ old = '"suppliers.title": "Fournisseurs",';                new = '"suppliers.title": "Liste des fournisseurs",' },
    @{ old = '"movements.title": "Mouvements de stock",';         new = '"movements.title": "Liste des mouvements de stock",' }
)

foreach ($pair in $pairs) {
    $count = ([regex]::Matches($content, [regex]::Escape($pair.old))).Count
    if ($count -ne 1) {
        Write-Host "ERREUR : ligne attendue introuvable (ou trouvee $count fois) : $($pair.old)" -ForegroundColor Red
        Write-Host "Aucune modification n'a ete faite sur $path. Restaure si besoin : Copy-Item '$path.bak-titres' '$path' -Force" -ForegroundColor Yellow
        exit 1
    }
    $content = $content.Replace($pair.old, $pair.new)
}

Set-Content -Path $path -Value $content -Encoding utf8 -NoNewline
Write-Host "OK : les 4 titres ont ete mis a jour (en francais)." -ForegroundColor Green
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT :" -ForegroundColor Yellow
Write-Host "  1. Regarde le terminal 'ng serve' : s'il affiche une erreur rouge," -ForegroundColor Yellow
Write-Host "     envoie-moi une capture d'ecran." -ForegroundColor Yellow
Write-Host "  2. Verifie les 4 pages dans le navigateur." -ForegroundColor Yellow
Write-Host "  3. En cas de souci, restaure :" -ForegroundColor Yellow
Write-Host "     Copy-Item 'src\app\services\translations.ts.bak-titres' 'src\app\services\translations.ts' -Force" -ForegroundColor Yellow
Write-Host ""