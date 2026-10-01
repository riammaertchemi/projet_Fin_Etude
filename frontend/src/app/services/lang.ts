import { Injectable, signal } from '@angular/core';
import { TRANSLATIONS, Lang } from './translations';

export type { Lang };

@Injectable({ providedIn: 'root' })
export class LangService {
  lang = signal<Lang>(this.getInitial());

  constructor() {
    this.applyLang(this.lang());
  }

  setLang(lang: Lang): void {
    this.lang.set(lang);
    localStorage.setItem('albideynet-lang', lang);
    this.applyLang(lang);
  }

  t(key: string, params?: Record<string, string | number>): string {
    const dict = TRANSLATIONS[this.lang()] || TRANSLATIONS['fr'];
    let text = dict[key] ?? TRANSLATIONS['fr'][key] ?? key;
    if (params) {
      for (const k of Object.keys(params)) {
        text = text.split('{' + k + '}').join(String(params[k]));
      }
    }
    return text;
  }

  get locale(): string {
    switch (this.lang()) {
      case 'en': return 'en-US';
      case 'ar': return 'ar-SA';
      default: return 'fr-FR';
    }
  }

  private getInitial(): Lang {
    const saved = localStorage.getItem('albideynet-lang');
    if (saved === 'fr' || saved === 'en' || saved === 'ar') return saved;
    return 'fr';
  }

  private applyLang(lang: Lang): void {
    document.documentElement.setAttribute('lang', lang);
    document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
    document.body.classList.toggle('rtl', lang === 'ar');
  }
}
