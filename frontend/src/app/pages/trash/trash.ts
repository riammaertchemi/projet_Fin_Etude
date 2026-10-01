import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TrashService, TrashData } from '../../services/trash';
import { ConfirmDialogService } from '../../services/confirm-dialog';
import { LangService } from '../../services/lang';
import { TranslatePipe } from '../../pipes/translate';

type TrashTab = 'products' | 'categories' | 'suppliers' | 'movements';

@Component({
  selector: 'app-trash',
  standalone: true,
  imports: [CommonModule, TranslatePipe],
  templateUrl: './trash.html',
  styleUrl: './trash.css'
})
export class Trash implements OnInit {
  data: TrashData = { products: [], categories: [], suppliers: [], movements: [] };
  loading = true;
  error = '';
  actionError = '';
  activeTab: TrashTab = 'products';

  constructor(
    private trashService: TrashService,
    private confirmDialog: ConfirmDialogService,
    private cdr: ChangeDetectorRef,
    public lang: LangService
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.trashService.getTrash().subscribe({
      next: (data) => {
        this.data = data;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = err?.error?.error || this.lang.t('trash.errorLoad');
        this.loading = false;
        this.cdr.detectChanges();
        console.error(err);
      }
    });
  }

  setTab(tab: TrashTab): void {
    this.activeTab = tab;
    this.actionError = '';
  }

  get totalCount(): number {
    return this.data.products.length + this.data.categories.length + this.data.suppliers.length + this.data.movements.length;
  }

  formatDate(dateStr: string | undefined): string {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleDateString(this.lang.locale) + ' ' + d.toLocaleTimeString(this.lang.locale, { hour: '2-digit', minute: '2-digit' });
  }

  restoreProduct(id: number): void {
    this.actionError = '';
    this.trashService.restoreProduct(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorRestore');
        this.cdr.detectChanges();
      }
    });
  }

  restoreCategory(id: number): void {
    this.actionError = '';
    this.trashService.restoreCategory(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorRestore');
        this.cdr.detectChanges();
      }
    });
  }

  restoreSupplier(id: number): void {
    this.actionError = '';
    this.trashService.restoreSupplier(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorRestore');
        this.cdr.detectChanges();
      }
    });
  }

  restoreMovement(id: number): void {
    this.actionError = '';
    this.trashService.restoreMovement(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorRestore');
        this.cdr.detectChanges();
      }
    });
  }

  async permanentDeleteProduct(id: number, name: string): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: this.lang.t('trash.confirmDeleteForeverTitle'),
      message: this.lang.t('trash.confirmDeleteProductMsg', { name }),
      confirmText: this.lang.t('trash.deleteForever'),
      cancelText: this.lang.t('common.cancel')
    });
    if (!confirmed) return;

    this.actionError = '';
    this.trashService.permanentDeleteProduct(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorDeleteForever');
        this.cdr.detectChanges();
      }
    });
  }

  async permanentDeleteCategory(id: number, name: string): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: this.lang.t('trash.confirmDeleteForeverTitle'),
      message: this.lang.t('trash.confirmDeleteCategoryMsg', { name }),
      confirmText: this.lang.t('trash.deleteForever'),
      cancelText: this.lang.t('common.cancel')
    });
    if (!confirmed) return;

    this.actionError = '';
    this.trashService.permanentDeleteCategory(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorDeleteForever');
        this.cdr.detectChanges();
      }
    });
  }

  async permanentDeleteSupplier(id: number, name: string): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: this.lang.t('trash.confirmDeleteForeverTitle'),
      message: this.lang.t('trash.confirmDeleteSupplierMsg', { name }),
      confirmText: this.lang.t('trash.deleteForever'),
      cancelText: this.lang.t('common.cancel')
    });
    if (!confirmed) return;

    this.actionError = '';
    this.trashService.permanentDeleteSupplier(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorDeleteForever');
        this.cdr.detectChanges();
      }
    });
  }

  async permanentDeleteMovement(id: number): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: this.lang.t('trash.confirmDeleteForeverTitle'),
      message: this.lang.t('trash.confirmDeleteMovementMsg'),
      confirmText: this.lang.t('trash.deleteForever'),
      cancelText: this.lang.t('common.cancel')
    });
    if (!confirmed) return;

    this.actionError = '';
    this.trashService.permanentDeleteMovement(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.actionError = err?.error?.error || this.lang.t('trash.errorDeleteForever');
        this.cdr.detectChanges();
      }
    });
  }
}
