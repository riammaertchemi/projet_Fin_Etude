# =========================================================================
# Script : ajouter_selection_multiple_v2.ps1
# Objet  : Ajoute une case a cocher "Selectionner tout" + suppression
#          groupee sur les 4 pages : Produits, Categories, Fournisseurs,
#          Mouvements de stock. Version corrigee : les ancres utilisees
#          correspondent exactement au contenu actuel des fichiers
#          (verifie ligne par ligne le 17/09/2026).
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
    Write-Host "Aucun fichier n'a ete modifie a partir de cette etape. Restaure si besoin avec les fichiers .bak-selection2." -ForegroundColor Yellow
    exit 1
}

function Get-LiteralAnchorOrFail {
    param($Content, $Anchor, $Label, $Path)
    $count = ([regex]::Matches($Content, [regex]::Escape($Anchor))).Count
    if ($count -ne 1) {
        Fail "ancre '$Label' introuvable (ou trouvee $count fois) dans $Path."
    }
}

function Get-RegexMatchOrFail {
    param($Content, $Pattern, $Label, $Path)
    $ms = [regex]::Matches($Content, $Pattern)
    if ($ms.Count -ne 1) {
        Fail "structure '$Label' introuvable (ou trouvee $($ms.Count) fois) dans $Path."
    }
    return $ms[0]
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

Write-Host "Sauvegarde des fichiers existants (.bak-selection2) ..." -ForegroundColor Cyan
foreach ($f in $files) {
    if (-not (Test-Path $f)) {
        Write-Host "ERREUR : $f est introuvable." -ForegroundColor Red
        exit 1
    }
    Copy-Item $f "$f.bak-selection2" -Force
}
Write-Host "Sauvegardes creees (extension .bak-selection2 a cote de chaque fichier)." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------------
# Modele de code TypeScript a inserer (memes methodes pour les 4 pages,
# seuls le service et la liste filtree changent)
# ------------------------------------------------------------------
$tsTemplate = @'
  selectedIds = new Set<number>();

  isSelected(item: { id: number }): boolean {
    return this.selectedIds.has(item.id);
  }

  toggleSelect(item: { id: number }): void {
    if (this.selectedIds.has(item.id)) {
      this.selectedIds.delete(item.id);
    } else {
      this.selectedIds.add(item.id);
    }
  }

  get allSelected(): boolean {
    return this.__FILTEREDLIST__.length > 0 && this.__FILTEREDLIST__.every((x: { id: number }) => this.selectedIds.has(x.id));
  }

  toggleSelectAll(): void {
    if (this.allSelected) {
      this.clearSelection();
    } else {
      this.__FILTEREDLIST__.forEach((x: { id: number }) => this.selectedIds.add(x.id));
    }
  }

  clearSelection(): void {
    this.selectedIds.clear();
  }

  async deleteSelected(): Promise<void> {
    if (this.selectedIds.size === 0) return;

    const confirmed = await this.confirmDialog.confirm({
      title: 'Confirmer la suppression',
      message: 'Supprimer ' + this.selectedIds.size + ' element(s) selectionne(s) ? (Ils seront envoyes a la Corbeille, restaurables.)',
      confirmText: this.lang.t('common.delete'),
      cancelText: this.lang.t('common.cancel')
    });

    if (!confirmed) return;

    const ids = Array.from(this.selectedIds);
    let remaining = ids.length;
    let hadError = false;

    ids.forEach(id => {
      this.__SERVICE__.delete(id).subscribe({
        next: () => {
          remaining--;
          if (remaining === 0) {
            this.clearSelection();
            this.load();
            if (hadError) { alert('Certains elements n\'ont pas pu etre supprimes.'); }
          }
        },
        error: (err: any) => {
          console.error(err);
          hadError = true;
          remaining--;
          if (remaining === 0) {
            this.clearSelection();
            this.load();
            alert('Certains elements n\'ont pas pu etre supprimes.');
          }
        }
      });
    });
  }

'@

$pages = @(
    @{
        Name         = "Produits"
        TsPath       = "src\app\pages\products\products.ts"
        HtmlPath     = "src\app\pages\products\products.html"
        TsAnchor     = '  async deleteProduct(product: Product): Promise<void> {'
        Service      = 'productService'
        FilteredList = 'filteredProducts'
        ForAnchor    = '@for (product of filteredProducts; track product.id) {'
        LoopVar      = 'product'
    },
    @{
        Name         = "Categories"
        TsPath       = "src\app\pages\categories\categories.ts"
        HtmlPath     = "src\app\pages\categories\categories.html"
        TsAnchor     = '  async deleteCategory(category: Category): Promise<void> {'
        Service      = 'categoryService'
        FilteredList = 'filteredCategories'
        ForAnchor    = '@for (category of filteredCategories; track category.id; let i = $index) {'
        LoopVar      = 'category'
    },
    @{
        Name         = "Fournisseurs"
        TsPath       = "src\app\pages\suppliers\suppliers.ts"
        HtmlPath     = "src\app\pages\suppliers\suppliers.html"
        TsAnchor     = '  async deleteSupplier(supplier: Supplier): Promise<void> {'
        Service      = 'supplierService'
        FilteredList = 'filteredSuppliers'
        ForAnchor    = '@for (supplier of filteredSuppliers; track supplier.id) {'
        LoopVar      = 'supplier'
    },
    @{
        Name         = "Mouvements de stock"
        TsPath       = "src\app\pages\stock-movements\stock-movements.ts"
        HtmlPath     = "src\app\pages\stock-movements\stock-movements.html"
        TsAnchor     = '  async deleteMovement(movement: StockMovement): Promise<void> {'
        Service      = 'stockMovementService'
        FilteredList = 'filteredMovements'
        ForAnchor    = '@for (movement of filteredMovements; track movement.id) {'
        LoopVar      = 'movement'
    }
)

foreach ($cfg in $pages) {
    Write-Host "Traitement de $($cfg.Name) ..." -ForegroundColor Cyan

    # ---- Fichier .ts : ajout des methodes de selection avant deleteXxx ----
    $tsContent = Get-Content -Path $cfg.TsPath -Raw
    Get-LiteralAnchorOrFail -Content $tsContent -Anchor $cfg.TsAnchor -Label "methode delete" -Path $cfg.TsPath
    $tsInsertion = $tsTemplate.Replace('__FILTEREDLIST__', $cfg.FilteredList).Replace('__SERVICE__', $cfg.Service)
    $tsContent = $tsContent.Replace($cfg.TsAnchor, $tsInsertion + $cfg.TsAnchor)
    Set-Content -Path $cfg.TsPath -Value $tsContent -Encoding utf8 -NoNewline
    Write-Host "  OK : $($cfg.TsPath) mis a jour." -ForegroundColor Green

    # ---- Fichier .html ----
    $htmlContent = Get-Content -Path $cfg.HtmlPath -Raw

    # 1) case a cocher "tout selectionner" dans le <thead>
    $theadPattern = [regex]::Escape('        <thead>') + '(\r?\n)(\s*<tr>)'
    $theadMatch = Get-RegexMatchOrFail -Content $htmlContent -Pattern $theadPattern -Label "thead/tr" -Path $cfg.HtmlPath
    $eol = $theadMatch.Groups[1].Value
    $trIndent = ($theadMatch.Groups[2].Value -replace '<tr>', '')
    $newTh = $trIndent + '  @if (canManage) { <th style="width:36px; text-align:center;"><input type="checkbox" [checked]="allSelected" (change)="toggleSelectAll()"></th> }'
    $htmlContent = $htmlContent.Replace($theadMatch.Value, $theadMatch.Value + $eol + $newTh)

    # 2) barre d'actions groupees, juste avant la barre de recherche
    $bulkPattern = '(' + [regex]::Escape('    </div>') + '\r?\n' + [regex]::Escape('  </div>') + '\r?\n\r?\n' + ')(' + [regex]::Escape('  <div class="search-bar no-print">') + ')'
    $bulkMatch = Get-RegexMatchOrFail -Content $htmlContent -Pattern $bulkPattern -Label "en-tete/search-bar" -Path $cfg.HtmlPath
    $bulkLines = @(
        '  @if (canManage && selectedIds.size > 0) {',
        '  <div class="bulk-actions no-print" style="display:flex; align-items:center; gap:12px; padding:10px 16px; background:#eaf1fa; border:1px solid #cfe0f3; border-radius:8px; margin:0 0 12px 0;">',
        '    <span>{{ selectedIds.size }} selectionne(s)</span>',
        '    <button class="btn-delete" (click)="deleteSelected()">Supprimer la selection</button>',
        '    <button class="btn-secondary" (click)="clearSelection()">Annuler la selection</button>',
        '  </div>',
        '  }'
    )
    $bulkBlockText = ($bulkLines -join $eol)
    $bulkReplacement = $bulkMatch.Groups[1].Value + $bulkBlockText + $eol + $eol + $bulkMatch.Groups[2].Value
    $htmlContent = $htmlContent.Replace($bulkMatch.Value, $bulkReplacement)

    # 3) case a cocher sur chaque ligne du tableau
    $rowPattern = [regex]::Escape($cfg.ForAnchor) + '(\r?\n\s*)(<tr[^>]*>)'
    $rowMatch = Get-RegexMatchOrFail -Content $htmlContent -Pattern $rowPattern -Label "ligne du tableau" -Path $cfg.HtmlPath
    $newTd = '  @if (canManage) { <td style="text-align:center;"><input type="checkbox" [checked]="isSelected(' + $cfg.LoopVar + ')" (change)="toggleSelect(' + $cfg.LoopVar + ')"></td> }'
    $htmlContent = $htmlContent.Replace($rowMatch.Value, $rowMatch.Value + $rowMatch.Groups[1].Value + $newTd)

    Set-Content -Path $cfg.HtmlPath -Value $htmlContent -Encoding utf8 -NoNewline
    Write-Host "  OK : $($cfg.HtmlPath) mis a jour." -ForegroundColor Green
    Write-Host ""
}

Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : selection multiple + suppression groupee ajoutees" -ForegroundColor Green
Write-Host "  sur les 4 pages (Produits, Categories, Fournisseurs, Mouvements)" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT :" -ForegroundColor Yellow
Write-Host "  1. Si 'ng serve' tourne deja dans un autre terminal, il devrait recharger" -ForegroundColor Yellow
Write-Host "     automatiquement. Regarde ce terminal : s'il affiche une erreur rouge" -ForegroundColor Yellow
Write-Host "     de compilation, envoie-moi une capture d'ecran." -ForegroundColor Yellow
Write-Host "  2. Verifie les 4 pages dans le navigateur : une case a cocher doit" -ForegroundColor Yellow
Write-Host "     apparaitre en premiere colonne, et des qu'au moins une ligne est" -ForegroundColor Yellow
Write-Host "     cochee, une barre bleu clair apparait avec un bouton 'Supprimer" -ForegroundColor Yellow
Write-Host "     la selection'." -ForegroundColor Yellow
Write-Host "  3. Ce n'est visible que pour les roles qui peuvent gerer (pas pour" -ForegroundColor Yellow
Write-Host "     Agent Logistique)." -ForegroundColor Yellow
Write-Host "  4. En cas de souci, restaure un fichier precis, par exemple :" -ForegroundColor Yellow
Write-Host "     Copy-Item 'src\app\pages\products\products.ts.bak-selection2' 'src\app\pages\products\products.ts' -Force" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE :" -ForegroundColor Cyan
Write-Host "  Le texte de cette nouvelle fonctionnalite (selectionne(s), Supprimer" -ForegroundColor Cyan
Write-Host "  la selection, Annuler la selection) est pour l'instant en francais" -ForegroundColor Cyan
Write-Host "  seulement. Si tu veux l'anglais et l'arabe, dis-le moi." -ForegroundColor Cyan
Write-Host ""