# =========================================================================
# Script : ajouter_bouton_selectionner.ps1
# Objet  : Ajoute un bouton "Selectionner" sur les 4 pages (Produits,
#          Categories, Fournisseurs, Mouvements de stock). Les cases a
#          cocher (ajoutees par ajouter_selection_multiple_v2.ps1) restent
#          cachees tant qu'on n'a pas clique sur ce bouton.
#
# IMPORTANT : ce script doit etre execute APRES
#             ajouter_selection_multiple_v2.ps1 (il modifie le code que
#             ce dernier a ajoute).
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

function Fail($msg) {
    Write-Host "ERREUR : $msg" -ForegroundColor Red
    Write-Host "Aucun fichier n'a ete modifie a partir de cette etape. Restaure si besoin avec les fichiers .bak-selectbtn." -ForegroundColor Yellow
    exit 1
}

function Apply-LiteralReplacement {
    param($Content, $Anchor, $Replacement, $Label, $Path)
    $count = ([regex]::Matches($Content, [regex]::Escape($Anchor))).Count
    if ($count -ne 1) {
        Fail "ancre '$Label' introuvable (ou trouvee $count fois) dans $Path."
    }
    return $Content.Replace($Anchor, $Replacement)
}

$files = @(
    "src\app\pages\products\products.ts",
    "src\app\pages\products\products.html",
    "src\app\pages\categories\categories.ts",
    "src\app\pages\categories\categories.html",
    "src\app\pages\suppliers\suppliers.ts",
    "src\app\pages\suppliers\suppliers.html",
    "src\app\pages\stock-movements\stock-movements.ts",
    "src\app\pages\stock-movements\stock-movements.html"
)

Write-Host "Sauvegarde des fichiers existants (.bak-selectbtn) ..." -ForegroundColor Cyan
foreach ($f in $files) {
    if (-not (Test-Path $f)) {
        Write-Host "ERREUR : $f est introuvable." -ForegroundColor Red
        exit 1
    }
    Copy-Item $f "$f.bak-selectbtn" -Force
}
Write-Host "Sauvegardes creees (extension .bak-selectbtn a cote de chaque fichier)." -ForegroundColor Green
Write-Host ""

$tsTsAnchor = '  selectedIds = new Set<number>();'
$tsInsertion = @'
  selectionMode = false;

  toggleSelectionMode(): void {
    this.selectionMode = !this.selectionMode;
    if (!this.selectionMode) {
      this.clearSelection();
    }
  }

'@

$svgIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:5px;"><circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/></svg>'

$pages = @(
    @{
        Name           = "Produits"
        TsPath         = "src\app\pages\products\products.ts"
        HtmlPath       = "src\app\pages\products\products.html"
        NewButtonLine  = '        <button class="btn-primary" (click)="openCreateForm()">' + $svgIcon + "{{ 'products.newProduct' | translate }}</button>"
        LoopVar        = 'product'
    },
    @{
        Name           = "Categories"
        TsPath         = "src\app\pages\categories\categories.ts"
        HtmlPath       = "src\app\pages\categories\categories.html"
        NewButtonLine  = '        <button class="btn-primary" (click)="openCreateForm()">' + $svgIcon + "{{ 'categories.newCategory' | translate }}</button>"
        LoopVar        = 'category'
    },
    @{
        Name           = "Fournisseurs"
        TsPath         = "src\app\pages\suppliers\suppliers.ts"
        HtmlPath       = "src\app\pages\suppliers\suppliers.html"
        NewButtonLine  = '        <button class="btn-primary" (click)="openCreateForm()">' + $svgIcon + "{{ 'suppliers.newSupplier' | translate }}</button>"
        LoopVar        = 'supplier'
    },
    @{
        Name           = "Mouvements de stock"
        TsPath         = "src\app\pages\stock-movements\stock-movements.ts"
        HtmlPath       = "src\app\pages\stock-movements\stock-movements.html"
        NewButtonLine  = '        <button class="btn-primary" (click)="openCreateForm()">' + $svgIcon + "{{ 'movements.newMovement' | translate }}</button>"
        LoopVar        = 'movement'
    }
)

foreach ($cfg in $pages) {
    Write-Host "Traitement de $($cfg.Name) ..." -ForegroundColor Cyan

    # ---- Fichier .ts : ajout de selectionMode + toggleSelectionMode() ----
    $tsContent = Get-Content -Path $cfg.TsPath -Raw
    $tsContent = Apply-LiteralReplacement -Content $tsContent -Anchor $tsTsAnchor -Replacement ($tsInsertion + $tsTsAnchor) -Label "selectedIds" -Path $cfg.TsPath
    Set-Content -Path $cfg.TsPath -Value $tsContent -Encoding utf8 -NoNewline
    Write-Host "  OK : $($cfg.TsPath) mis a jour." -ForegroundColor Green

    # ---- Fichier .html ----
    $htmlContent = Get-Content -Path $cfg.HtmlPath -Raw

    # 1) bouton "Selectionner" juste apres le bouton "Nouveau ..."
    $selectBtn = "`r`n        " + '<button class="btn-secondary" (click)="toggleSelectionMode()">{{ selectionMode ? ' + "'Annuler la selection' : 'Selectionner'" + ' }}</button>'
    $htmlContent = Apply-LiteralReplacement -Content $htmlContent -Anchor $cfg.NewButtonLine -Replacement ($cfg.NewButtonLine + $selectBtn) -Label "bouton Nouveau" -Path $cfg.HtmlPath

    # 2) la case a cocher du thead ne s'affiche que si selectionMode est actif
    $theadOld = '@if (canManage) { <th style="width:36px; text-align:center;"><input type="checkbox" [checked]="allSelected" (change)="toggleSelectAll()"></th> }'
    $theadNew = '@if (canManage && selectionMode) { <th style="width:36px; text-align:center;"><input type="checkbox" [checked]="allSelected" (change)="toggleSelectAll()"></th> }'
    $htmlContent = Apply-LiteralReplacement -Content $htmlContent -Anchor $theadOld -Replacement $theadNew -Label "case a cocher thead" -Path $cfg.HtmlPath

    # 3) la case a cocher de chaque ligne ne s'affiche que si selectionMode est actif
    $rowOld = '@if (canManage) { <td style="text-align:center;"><input type="checkbox" [checked]="isSelected(' + $cfg.LoopVar + ')" (change)="toggleSelect(' + $cfg.LoopVar + ')"></td> }'
    $rowNew = '@if (canManage && selectionMode) { <td style="text-align:center;"><input type="checkbox" [checked]="isSelected(' + $cfg.LoopVar + ')" (change)="toggleSelect(' + $cfg.LoopVar + ')"></td> }'
    $htmlContent = Apply-LiteralReplacement -Content $htmlContent -Anchor $rowOld -Replacement $rowNew -Label "case a cocher ligne" -Path $cfg.HtmlPath

    # 4) la barre d'actions groupees ne s'affiche que si selectionMode est actif
    $bulkOld = '@if (canManage && selectedIds.size > 0) {'
    $bulkNew = '@if (canManage && selectionMode && selectedIds.size > 0) {'
    $htmlContent = Apply-LiteralReplacement -Content $htmlContent -Anchor $bulkOld -Replacement $bulkNew -Label "barre actions groupees" -Path $cfg.HtmlPath

    Set-Content -Path $cfg.HtmlPath -Value $htmlContent -Encoding utf8 -NoNewline
    Write-Host "  OK : $($cfg.HtmlPath) mis a jour." -ForegroundColor Green
    Write-Host ""
}

Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : bouton 'Selectionner' ajoute sur les 4 pages" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT :" -ForegroundColor Yellow
Write-Host "  1. Regarde le terminal 'ng serve' : s'il affiche une erreur rouge," -ForegroundColor Yellow
Write-Host "     envoie-moi une capture d'ecran." -ForegroundColor Yellow
Write-Host "  2. Dans le navigateur, les cases a cocher doivent maintenant etre" -ForegroundColor Yellow
Write-Host "     invisibles par defaut. Un bouton 'Selectionner' apparait a cote" -ForegroundColor Yellow
Write-Host "     du bouton 'Nouveau ...'. En cliquant dessus, les cases a cocher" -ForegroundColor Yellow
Write-Host "     apparaissent sur toutes les lignes." -ForegroundColor Yellow
Write-Host "  3. En cas de souci, restaure un fichier precis, par exemple :" -ForegroundColor Yellow
Write-Host "     Copy-Item 'src\app\pages\products\products.ts.bak-selectbtn' 'src\app\pages\products\products.ts' -Force" -ForegroundColor Yellow
Write-Host ""