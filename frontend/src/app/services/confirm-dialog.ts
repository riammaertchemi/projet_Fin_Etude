import { Injectable, signal } from '@angular/core';

export interface ConfirmOptions {
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
}

@Injectable({ providedIn: 'root' })
export class ConfirmDialogService {
  isOpen = signal(false);
  title = signal('Confirmation');
  message = signal('');
  confirmText = signal('Supprimer');
  cancelText = signal('Annuler');

  private resolver: ((result: boolean) => void) | null = null;

  confirm(options: ConfirmOptions): Promise<boolean> {
    this.title.set(options.title ?? 'Confirmation');
    this.message.set(options.message);
    this.confirmText.set(options.confirmText ?? 'Supprimer');
    this.cancelText.set(options.cancelText ?? 'Annuler');
    this.isOpen.set(true);

    return new Promise<boolean>((resolve) => {
      this.resolver = resolve;
    });
  }

  onConfirm(): void {
    this.isOpen.set(false);
    const resolve = this.resolver;
    this.resolver = null;
    if (resolve) resolve(true);
  }

  onCancel(): void {
    this.isOpen.set(false);
    const resolve = this.resolver;
    this.resolver = null;
    if (resolve) resolve(false);
  }
}
