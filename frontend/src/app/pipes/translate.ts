import { Pipe, PipeTransform } from '@angular/core';
import { LangService } from '../services/lang';

@Pipe({
  name: 'translate',
  standalone: true,
  pure: false
})
export class TranslatePipe implements PipeTransform {
  constructor(private lang: LangService) {}

  transform(key: string, params?: Record<string, string | number>): string {
    return this.lang.t(key, params);
  }
}
