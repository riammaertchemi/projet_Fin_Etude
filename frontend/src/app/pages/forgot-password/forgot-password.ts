import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Auth } from '../../services/auth';
import { LangService } from '../../services/lang';
import { TranslatePipe } from '../../pipes/translate';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, TranslatePipe],
  templateUrl: './forgot-password.html',
  styleUrl: './forgot-password.css',
})
export class ForgotPassword {
  email = '';
  errorMessage = signal('');
  successMessage = signal('');
  loading = signal(false);

  constructor(private auth: Auth, public lang: LangService) {}

  onSubmit(): void {
    this.errorMessage.set('');
    this.successMessage.set('');
    this.loading.set(true);

    this.auth.forgotPassword(this.email).subscribe({
      next: (res) => {
        this.loading.set(false);
        this.successMessage.set(res.message || this.lang.t('forgotPassword.successMessage'));
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(err.error?.error || this.lang.t('forgotPassword.errorDefault'));
      },
    });
  }
}
