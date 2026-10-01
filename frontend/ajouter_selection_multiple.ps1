# =========================================================================
# Script : ajouter_selection_multiple.ps1
# Objet  : Ajoute une case a cocher "Tout selectionner" en tete de tableau,
#          une case a cocher sur chaque ligne, et un bouton "Supprimer la
#          selection" qui apparait des qu'au moins un element est coche,
#          sur les 4 pages de gestion :
#            - Produits
#            - Categories
#            - Fournisseurs
#            - Mouvements de stock
#          La suppression multiple reutilise exactement la meme suppression
#          (douce, vers la Corbeille) que le bouton "Supprimer" individuel
#          deja en place : aucun changement cote backend n'est necessaire.
#          Reserve aux roles qui peuvent deja gerer (canManage) : le role
#          Agent Logistique (lecture seule) ne voit ni cases a cocher, ni
#          bouton de suppression groupee, exactement comme pour les boutons
#          Modifier/Supprimer individuels.
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

foreach ($f in $files) {
    if (-not (Test-Path $f)) {
        Write-Host "ERREUR : $f est introuvable." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Sauvegarde des fichiers existants (.bak-selection) ..." -ForegroundColor Cyan
foreach ($f in $files) {
    Copy-Item $f "$f.bak-selection" -Force
}
Write-Host "Sauvegardes creees (extension .bak-selection a cote de chaque fichier)." -ForegroundColor Green
Write-Host ""

function Apply-Replacement {
    param(
        [string]$Path,
        [string]$Content,
        [string]$Anchor,
        [string]$Replacement,
        [string]$Label
    )
    $count = ([regex]::Matches($Content, [regex]::Escape($Anchor))).Count
    if ($count -ne 1) {
        Write-Host "ERREUR : ancre '$Label' introuvable (ou trouvee $count fois) dans $Path." -ForegroundColor Red
        Write-Host "Aucun fichier n'a ete modifie sur le disque a partir de cette etape. Restaure si besoin avec les fichiers .bak-selection." -ForegroundColor Yellow
        exit 1
    }
    return $Content.Replace($Anchor, $Replacement)
}

# =========================================================================
# Bloc HTML commun aux 4 pages : barre d'actions groupees, entre la fin du
# page-header et le debut de la barre de recherche.
# =========================================================================
$anchorBulkBar = @'
    </div>
  </div>

  <div class="search-bar no-print">
'@

$replacementBulkBar = @'
    </div>
  </div>

  @if (canManage && selectedIds.size > 0) {
    <div class="bulk-actions no-print" style="display:flex; align-items:center; gap:10px; margin:0 0 14px 0; padding:10px 14px; background:#eaf1fa; border:1px solid #b8d4f0; border-radius:8px;">
      <span style="font-weight:600; color:#1e3a5f;">{{ selectedIds.size }} sélectionné(s)</span>
      <button class="btn-delete" (click)="deleteSelected()">🗑️ Supprimer la sélection</button>
      <button class="btn-secondary" (click)="clearSelection()">Annuler la sélection</button>
    </div>
  }

  <div class="search-bar no-print">
'@

# =========================================================================
# Bloc HTML commun aux 4 pages : case "Tout selectionner" dans l'entete.
# =========================================================================
$anchorThead = @'
<thead>
          <tr>
'@

$replacementThead = @'
<thead>
          <tr>
            @if (canManage) {
              <th style="width:36px; text-align:center;">
                <input type="checkbox" [checked]="allSelected" (change)="toggleSelectAll()">
              </th>
            }
'@

# =========================================================================
# 1) PRODUITS
# =========================================================================
Write-Host "Traitement de products.ts / products.html ..." -ForegroundColor Cyan

$tsPath = "src\app\pages\products\products.ts"
$content = Get-Content -Path $tsPath -Raw

$anchorDelete = @'
  async deleteProduct(product: Product): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer ce produit ?',
      message: `Voulez-vous vraiment supprimer le produit "${product.name}" ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.productService.delete(product.id).subscribe({
      next: () => this.load(),
      error: (err) => console.error(err)
    });
  }
'@

$newMethods = @'
  async deleteProduct(product: Product): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer ce produit ?',
      message: `Voulez-vous vraiment supprimer le produit "${product.name}" ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.productService.delete(product.id).subscribe({
      next: () => this.load(),
      error: (err) => console.error(err)
    });
  }

  selectedIds = new Set<number>();

  isSelected(product: Product): boolean {
    return this.selectedIds.has(product.id);
  }

  toggleSelect(product: Product): void {
    if (this.selectedIds.has(product.id)) {
      this.selectedIds.delete(product.id);
    } else {
      this.selectedIds.add(product.id);
    }
  }

  get allSelected(): boolean {
    const list = this.filteredProducts;
    return list.length > 0 && list.every(p => this.selectedIds.has(p.id));
  }

  toggleSelectAll(): void {
    if (this.allSelected) {
      this.filteredProducts.forEach(p => this.selectedIds.delete(p.id));
    } else {
      this.filteredProducts.forEach(p => this.selectedIds.add(p.id));
    }
  }

  clearSelection(): void {
    this.selectedIds.clear();
  }

  async deleteSelected(): Promise<void> {
    const count = this.selectedIds.size;
    if (count === 0) return;

    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer les produits sélectionnés ?',
      message: `Voulez-vous vraiment supprimer ${count} produit(s) ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    const ids = Array.from(this.selectedIds);
    let remaining = ids.length;
    let hadError = false;

    ids.forEach(id => {
      this.productService.delete(id).subscribe({
        next: () => {
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            if (hadError) alert("Certains produits n'ont pas pu être supprimés.");
          }
        },
        error: (err) => {
          console.error(err);
          hadError = true;
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            alert("Certains produits n'ont pas pu être supprimés.");
          }
        }
      });
    });
  }
'@

$content = Apply-Replacement -Path $tsPath -Content $content -Anchor $anchorDelete -Replacement $newMethods -Label "deleteProduct"
Set-Content -Path $tsPath -Value $content -Encoding utf8 -NoNewline

$htmlPath = "src\app\pages\products\products.html"
$content = Get-Content -Path $htmlPath -Raw

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorThead -Replacement $replacementThead -Label "thead"

$anchorForRow = @'
          @for (product of filteredProducts; track product.id) {
            <tr [class.low-stock]="product.quantity < product.minQuantity">
'@
$replacementForRow = @'
          @for (product of filteredProducts; track product.id) {
            <tr [class.low-stock]="product.quantity < product.minQuantity">
              @if (canManage) {
                <td style="text-align:center;">
                  <input type="checkbox" [checked]="isSelected(product)" (change)="toggleSelect(product)">
                </td>
              }
'@
$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorForRow -Replacement $replacementForRow -Label "for-row"

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorBulkBar -Replacement $replacementBulkBar -Label "bulk-bar"

Set-Content -Path $htmlPath -Value $content -Encoding utf8 -NoNewline
Write-Host "OK : Produits." -ForegroundColor Green
Write-Host ""

# =========================================================================
# 2) CATEGORIES
# =========================================================================
Write-Host "Traitement de categories.ts / categories.html ..." -ForegroundColor Cyan

$tsPath = "src\app\pages\categories\categories.ts"
$content = Get-Content -Path $tsPath -Raw

$anchorDelete = @'
  async deleteCategory(category: Category): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer cette catégorie ?',
      message: `Voulez-vous vraiment supprimer la catégorie "${category.name}" ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.categoryService.delete(category.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        console.error(err);
        alert('Erreur lors de la suppression (vérifiez le backend).');
      }
    });
  }
'@

$newMethods = @'
  async deleteCategory(category: Category): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer cette catégorie ?',
      message: `Voulez-vous vraiment supprimer la catégorie "${category.name}" ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.categoryService.delete(category.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        console.error(err);
        alert('Erreur lors de la suppression (vérifiez le backend).');
      }
    });
  }

  selectedIds = new Set<number>();

  isSelected(category: Category): boolean {
    return this.selectedIds.has(category.id);
  }

  toggleSelect(category: Category): void {
    if (this.selectedIds.has(category.id)) {
      this.selectedIds.delete(category.id);
    } else {
      this.selectedIds.add(category.id);
    }
  }

  get allSelected(): boolean {
    const list = this.filteredCategories;
    return list.length > 0 && list.every(c => this.selectedIds.has(c.id));
  }

  toggleSelectAll(): void {
    if (this.allSelected) {
      this.filteredCategories.forEach(c => this.selectedIds.delete(c.id));
    } else {
      this.filteredCategories.forEach(c => this.selectedIds.add(c.id));
    }
  }

  clearSelection(): void {
    this.selectedIds.clear();
  }

  async deleteSelected(): Promise<void> {
    const count = this.selectedIds.size;
    if (count === 0) return;

    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer les catégories sélectionnées ?',
      message: `Voulez-vous vraiment supprimer ${count} catégorie(s) ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    const ids = Array.from(this.selectedIds);
    let remaining = ids.length;
    let hadError = false;

    ids.forEach(id => {
      this.categoryService.delete(id).subscribe({
        next: () => {
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            if (hadError) alert("Certaines catégories n'ont pas pu être supprimées.");
          }
        },
        error: (err) => {
          console.error(err);
          hadError = true;
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            alert("Certaines catégories n'ont pas pu être supprimées.");
          }
        }
      });
    });
  }
'@

$content = Apply-Replacement -Path $tsPath -Content $content -Anchor $anchorDelete -Replacement $newMethods -Label "deleteCategory"
Set-Content -Path $tsPath -Value $content -Encoding utf8 -NoNewline

$htmlPath = "src\app\pages\categories\categories.html"
$content = Get-Content -Path $htmlPath -Raw

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorThead -Replacement $replacementThead -Label "thead"

$anchorForRow = @'
          @for (category of filteredCategories; track category.id; let i = $index) {
            <tr>
'@
$replacementForRow = @'
          @for (category of filteredCategories; track category.id; let i = $index) {
            <tr>
              @if (canManage) {
                <td style="text-align:center;">
                  <input type="checkbox" [checked]="isSelected(category)" (change)="toggleSelect(category)">
                </td>
              }
'@
$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorForRow -Replacement $replacementForRow -Label "for-row"

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorBulkBar -Replacement $replacementBulkBar -Label "bulk-bar"

Set-Content -Path $htmlPath -Value $content -Encoding utf8 -NoNewline
Write-Host "OK : Categories." -ForegroundColor Green
Write-Host ""

# =========================================================================
# 3) FOURNISSEURS
# =========================================================================
Write-Host "Traitement de suppliers.ts / suppliers.html ..." -ForegroundColor Cyan

$tsPath = "src\app\pages\suppliers\suppliers.ts"
$content = Get-Content -Path $tsPath -Raw

$anchorDelete = @'
  async deleteSupplier(supplier: Supplier): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer ce fournisseur ?',
      message: `Voulez-vous vraiment supprimer le fournisseur "${supplier.name}" ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.supplierService.delete(supplier.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        console.error(err);
        alert('Erreur lors de la suppression (vérifiez le backend).');
      }
    });
  }
'@

$newMethods = @'
  async deleteSupplier(supplier: Supplier): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer ce fournisseur ?',
      message: `Voulez-vous vraiment supprimer le fournisseur "${supplier.name}" ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.supplierService.delete(supplier.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        console.error(err);
        alert('Erreur lors de la suppression (vérifiez le backend).');
      }
    });
  }

  selectedIds = new Set<number>();

  isSelected(supplier: Supplier): boolean {
    return this.selectedIds.has(supplier.id);
  }

  toggleSelect(supplier: Supplier): void {
    if (this.selectedIds.has(supplier.id)) {
      this.selectedIds.delete(supplier.id);
    } else {
      this.selectedIds.add(supplier.id);
    }
  }

  get allSelected(): boolean {
    const list = this.filteredSuppliers;
    return list.length > 0 && list.every(s => this.selectedIds.has(s.id));
  }

  toggleSelectAll(): void {
    if (this.allSelected) {
      this.filteredSuppliers.forEach(s => this.selectedIds.delete(s.id));
    } else {
      this.filteredSuppliers.forEach(s => this.selectedIds.add(s.id));
    }
  }

  clearSelection(): void {
    this.selectedIds.clear();
  }

  async deleteSelected(): Promise<void> {
    const count = this.selectedIds.size;
    if (count === 0) return;

    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer les fournisseurs sélectionnés ?',
      message: `Voulez-vous vraiment supprimer ${count} fournisseur(s) ? Cette action est irréversible.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    const ids = Array.from(this.selectedIds);
    let remaining = ids.length;
    let hadError = false;

    ids.forEach(id => {
      this.supplierService.delete(id).subscribe({
        next: () => {
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            if (hadError) alert("Certains fournisseurs n'ont pas pu être supprimés.");
          }
        },
        error: (err) => {
          console.error(err);
          hadError = true;
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            alert("Certains fournisseurs n'ont pas pu être supprimés.");
          }
        }
      });
    });
  }
'@

$content = Apply-Replacement -Path $tsPath -Content $content -Anchor $anchorDelete -Replacement $newMethods -Label "deleteSupplier"
Set-Content -Path $tsPath -Value $content -Encoding utf8 -NoNewline

$htmlPath = "src\app\pages\suppliers\suppliers.html"
$content = Get-Content -Path $htmlPath -Raw

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorThead -Replacement $replacementThead -Label "thead"

$anchorForRow = @'
          @for (supplier of filteredSuppliers; track supplier.id) {
            <tr>
'@
$replacementForRow = @'
          @for (supplier of filteredSuppliers; track supplier.id) {
            <tr>
              @if (canManage) {
                <td style="text-align:center;">
                  <input type="checkbox" [checked]="isSelected(supplier)" (change)="toggleSelect(supplier)">
                </td>
              }
'@
$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorForRow -Replacement $replacementForRow -Label "for-row"

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorBulkBar -Replacement $replacementBulkBar -Label "bulk-bar"

Set-Content -Path $htmlPath -Value $content -Encoding utf8 -NoNewline
Write-Host "OK : Fournisseurs." -ForegroundColor Green
Write-Host ""

# =========================================================================
# 4) MOUVEMENTS DE STOCK
# =========================================================================
Write-Host "Traitement de stock-movements.ts / stock-movements.html ..." -ForegroundColor Cyan

$tsPath = "src\app\pages\stock-movements\stock-movements.ts"
$content = Get-Content -Path $tsPath -Raw

$anchorDelete = @'
  async deleteMovement(movement: StockMovement): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer ce mouvement ?',
      message: `Voulez-vous vraiment supprimer ce mouvement (${movement.type} ${movement.quantity}) ? Le stock du produit sera ajusté en conséquence.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.stockMovementService.delete(movement.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        alert(err?.error?.error || 'Erreur lors de la suppression du mouvement.');
        console.error(err);
      }
    });
  }
'@

$newMethods = @'
  async deleteMovement(movement: StockMovement): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer ce mouvement ?',
      message: `Voulez-vous vraiment supprimer ce mouvement (${movement.type} ${movement.quantity}) ? Le stock du produit sera ajusté en conséquence.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    this.stockMovementService.delete(movement.id).subscribe({
      next: () => this.load(),
      error: (err) => {
        alert(err?.error?.error || 'Erreur lors de la suppression du mouvement.');
        console.error(err);
      }
    });
  }

  selectedIds = new Set<number>();

  isSelected(movement: StockMovement): boolean {
    return this.selectedIds.has(movement.id);
  }

  toggleSelect(movement: StockMovement): void {
    if (this.selectedIds.has(movement.id)) {
      this.selectedIds.delete(movement.id);
    } else {
      this.selectedIds.add(movement.id);
    }
  }

  get allSelected(): boolean {
    const list = this.filteredMovements;
    return list.length > 0 && list.every(m => this.selectedIds.has(m.id));
  }

  toggleSelectAll(): void {
    if (this.allSelected) {
      this.filteredMovements.forEach(m => this.selectedIds.delete(m.id));
    } else {
      this.filteredMovements.forEach(m => this.selectedIds.add(m.id));
    }
  }

  clearSelection(): void {
    this.selectedIds.clear();
  }

  async deleteSelected(): Promise<void> {
    const count = this.selectedIds.size;
    if (count === 0) return;

    const confirmed = await this.confirmDialog.confirm({
      title: 'Supprimer les mouvements sélectionnés ?',
      message: `Voulez-vous vraiment supprimer ${count} mouvement(s) ? Le stock des produits concernés sera ajusté en conséquence.`,
      confirmText: 'Supprimer',
      cancelText: 'Annuler'
    });

    if (!confirmed) return;

    const ids = Array.from(this.selectedIds);
    let remaining = ids.length;
    let hadError = false;

    ids.forEach(id => {
      this.stockMovementService.delete(id).subscribe({
        next: () => {
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            if (hadError) alert("Certains mouvements n'ont pas pu être supprimés.");
          }
        },
        error: (err) => {
          console.error(err);
          hadError = true;
          remaining--;
          if (remaining === 0) {
            this.selectedIds.clear();
            this.load();
            alert("Certains mouvements n'ont pas pu être supprimés.");
          }
        }
      });
    });
  }
'@

$content = Apply-Replacement -Path $tsPath -Content $content -Anchor $anchorDelete -Replacement $newMethods -Label "deleteMovement"
Set-Content -Path $tsPath -Value $content -Encoding utf8 -NoNewline

$htmlPath = "src\app\pages\stock-movements\stock-movements.html"
$content = Get-Content -Path $htmlPath -Raw

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorThead -Replacement $replacementThead -Label "thead"

$anchorForRow = @'
          @for (movement of filteredMovements; track movement.id) {
            <tr>
'@
$replacementForRow = @'
          @for (movement of filteredMovements; track movement.id) {
            <tr>
              @if (canManage) {
                <td style="text-align:center;">
                  <input type="checkbox" [checked]="isSelected(movement)" (change)="toggleSelect(movement)">
                </td>
              }
'@
$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorForRow -Replacement $replacementForRow -Label "for-row"

$content = Apply-Replacement -Path $htmlPath -Content $content -Anchor $anchorBulkBar -Replacement $replacementBulkBar -Label "bulk-bar"

Set-Content -Path $htmlPath -Value $content -Encoding utf8 -NoNewline
Write-Host "OK : Mouvements de stock." -ForegroundColor Green
Write-Host ""

Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : selection multiple + suppression groupee" -ForegroundColor Green
Write-Host "  ajoutees sur Produits, Categories, Fournisseurs et" -ForegroundColor Green
Write-Host "  Mouvements de stock." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT :" -ForegroundColor Yellow
Write-Host "  1. Si 'ng serve' tourne deja, il devrait recharger automatiquement." -ForegroundColor Yellow
Write-Host "     Sinon : arrete-le (Ctrl+C) et relance 'ng serve'." -ForegroundColor Yellow
Write-Host "  2. Sur chaque page (Produits/Categories/Fournisseurs/Mouvements) :" -ForegroundColor Yellow
Write-Host "     - une case a cocher apparait en tete de tableau (tout selectionner)" -ForegroundColor Yellow
Write-Host "       et sur chaque ligne, uniquement pour les roles qui peuvent gerer" -ForegroundColor Yellow
Write-Host "       (Administrateur, Directeur General, Responsable Logistique)." -ForegroundColor Yellow
Write-Host "     - des qu'au moins une ligne est cochee, une barre bleu clair" -ForegroundColor Yellow
Write-Host "       apparait au-dessus du tableau avec un bouton 'Supprimer la" -ForegroundColor Yellow
Write-Host "       selection' (et un bouton pour annuler la selection)." -ForegroundColor Yellow
Write-Host "     - la suppression groupee redemande confirmation une seule fois," -ForegroundColor Yellow
Write-Host "       puis supprime chaque element selectionne un par un vers la" -ForegroundColor Yellow
Write-Host "       Corbeille (meme mecanisme que le bouton Supprimer individuel)." -ForegroundColor Yellow
Write-Host "     - le role Agent Logistique (lecture seule) ne voit rien de tout ca." -ForegroundColor Yellow
Write-Host "  3. En cas de souci sur un fichier precis, restaure par exemple :" -ForegroundColor Yellow
Write-Host "     Copy-Item 'src\app\pages\products\products.html.bak-selection' 'src\app\pages\products\products.html' -Force" -ForegroundColor Yellow
Write-Host "     Copy-Item 'src\app\pages\products\products.ts.bak-selection' 'src\app\pages\products\products.ts' -Force" -ForegroundColor Yellow
Write-Host "     (idem pour categories / suppliers / stock-movements)" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE :" -ForegroundColor Cyan
Write-Host "  Les textes de cette nouvelle fonctionnalite (sélectionné(s), Supprimer" -ForegroundColor Cyan
Write-Host "  la sélection, Annuler la sélection) sont pour l'instant uniquement en" -ForegroundColor Cyan
Write-Host "  français, contrairement au reste de l'interface qui est traduit en" -ForegroundColor Cyan
Write-Host "  anglais/arabe. Dis-moi si tu veux que je les ajoute aussi a" -ForegroundColor Cyan
Write-Host "  translations.ts (j'ai besoin de voir ce fichier pour le faire sans" -ForegroundColor Cyan
Write-Host "  risque)." -ForegroundColor Cyan
Write-Host ""