import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  isDark = signal<boolean>(this.getInitial());

  constructor() {
    this.applyTheme(this.isDark());
  }

  toggle(): void {
    const newValue = !this.isDark();
    this.isDark.set(newValue);
    localStorage.setItem('albideynet-theme', newValue ? 'dark' : 'light');
    this.applyTheme(newValue);
  }

  private getInitial(): boolean {
    const saved = localStorage.getItem('albideynet-theme');
    if (saved) return saved === 'dark';
    return !!(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);
  }

  private applyTheme(dark: boolean): void {
    if (dark) {
      document.body.classList.add('dark-theme');
    } else {
      document.body.classList.remove('dark-theme');
    }
  }
}