import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Product, ProductService } from '../../services/product';
import { Category, CategoryService } from '../../services/category';
import { Supplier, SupplierService } from '../../services/supplier';
import { ConfirmDialogService } from '../../services/confirm-dialog';
import { Auth } from '../../services/auth';
import { LangService } from '../../services/lang';
import { TranslatePipe } from '../../pipes/translate';

@Component({
  selector: 'app-products',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslatePipe],
  templateUrl: './products.html',
  styleUrl: './products.css'
})
export class Products implements OnInit {
  products: Product[] = [];
  categories: Category[] = [];
  suppliers: Supplier[] = [];
  loading = true;
  error = '';
  saveError = '';

  searchTerm = '';

  showForm = false;
  editingProduct: Product | null = null;
  formData: Partial<Product> = this.emptyForm();

  constructor(
    private productService: ProductService,
    private categoryService: CategoryService,
    private supplierService: SupplierService,
    private confirmDialog: ConfirmDialogService,
    private cdr: ChangeDetectorRef,
    private route: ActivatedRoute,
    public auth: Auth,
    public lang: LangService
  ) {}

  get canManage(): boolean {
    const role = this.auth.currentUser()?.role;
    return role === 'ADMIN' || role === 'DIRECTEUR_GENERAL' || role === 'RESPONSABLE_LOGISTIQUE';
  }

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      this.searchTerm = params['search'] || '';
      this.cdr.detectChanges();
    });
    this.load();
    this.loadCategories();
    this.loadSuppliers();
  }

  get filteredProducts(): Product[] {
    const term = this.searchTerm.trim().toLowerCase();
    if (!term) return this.products;
    return this.products.filter(p =>
      p.name?.toLowerCase().includes(term) ||
      p.sku?.toLowerCase().includes(term) ||
      p.description?.toLowerCase().includes(term) ||
      p.category?.name?.toLowerCase().includes(term)
    );
  }

  clearSearch(): void {
    this.searchTerm = '';
  }

  printPage(): void {
    window.print();
  }

  load(): void {
    this.loading = true;
    this.productService.getAll().subscribe({
      next: (data) => {
        this.products = data;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = this.lang.t('products.errorLoad');
        this.loading = false;
        this.cdr.detectChanges();
        console.error(err);
      }
    });
  }

  loadCategories(): void {
    this.categoryService.getAll().subscribe({
      next: (data) => {
        this.categories = data;
        this.cdr.detectChanges();
      },
      error: (err) => console.error(err)
    });
  }

  loadSuppliers(): void {
    this.supplierService.getAll().subscribe({
      next: (data) => {
        this.suppliers = data;
        this.cdr.detectChanges();
      },
      error: (err) => console.error(err)
    });
  }

  emptyForm(): Partial<Product> {
    return {
      name: '', sku: '', description: '', price: 0, quantity: 0, minQuantity: 5,
      categoryId: null, supplierId: null, imageUrl: null
    };
  }

  openCreateForm(): void {
    this.editingProduct = null;
    this.formData = this.emptyForm();
    this.saveError = '';
    this.showForm = true;
  }

  openEditForm(product: Product): void {
    this.editingProduct = product;
    this.formData = {
      name: product.name,
      sku: product.sku,
      description: product.description,
      price: product.price,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      categoryId: product.categoryId,
      supplierId: product.supplierId,
      imageUrl: product.imageUrl || null
    };
    this.saveError = '';
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingProduct = null;
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files && input.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      this.saveError = this.lang.t('products.imageInvalid');
      return;
    }

    if (file.size > 3 * 1024 * 1024) {
      this.saveError = this.lang.t('products.imageTooLarge');
      return;
    }

    this.saveError = '';
    const reader = new FileReader();
    reader.onload = () => {
      this.formData.imageUrl = reader.result as string;
      this.cdr.detectChanges();
    };
    reader.readAsDataURL(file);
  }

  removeImage(): void {
    this.formData.imageUrl = null;
  }

  saveProduct(): void {
    this.saveError = '';

    if (this.editingProduct) {
      this.productService.update(this.editingProduct.id, this.formData).subscribe({
        next: () => {
          this.showForm = false;
          this.load();
        },
        error: (err) => {
          this.saveError = err?.error?.error || this.lang.t('products.errorUpdate');
          console.error(err);
        }
      });
    } else {
      this.productService.create(this.formData).subscribe({
        next: () => {
          this.showForm = false;
          this.load();
        },
        error: (err) => {
          this.saveError = err?.error?.error || this.lang.t('products.errorCreate');
          console.error(err);
        }
      });
    }
  }

  selectionMode = false;

  toggleSelectionMode(): void {
    this.selectionMode = !this.selectionMode;
    if (!this.selectionMode) {
      this.clearSelection();
    }
  }
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
    return this.filteredProducts.length > 0 && this.filteredProducts.every((x: { id: number }) => this.selectedIds.has(x.id));
  }

  toggleSelectAll(): void {
    if (this.allSelected) {
      this.clearSelection();
    } else {
      this.filteredProducts.forEach((x: { id: number }) => this.selectedIds.add(x.id));
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
      this.productService.delete(id).subscribe({
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
  async deleteProduct(product: Product): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: this.lang.t('products.confirmDeleteTitle'),
      message: this.lang.t('products.confirmDeleteMsg', { name: product.name }),
      confirmText: this.lang.t('common.delete'),
      cancelText: this.lang.t('common.cancel')
    });

    if (!confirmed) return;

    this.productService.delete(product.id).subscribe({
      next: () => this.load(),
      error: (err) => console.error(err)
    });
  }

  formatPrice(price: number | undefined | null): string {
    if (price === undefined || price === null) return '0 FCFA';
    return Math.round(price).toLocaleString('fr-FR') + ' FCFA';
  }
}


