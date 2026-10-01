import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Auth } from '../../services/auth';
import { LangService } from '../../services/lang';
import { TranslatePipe } from '../../pipes/translate';

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, TranslatePipe],
  templateUrl: './reset-password.html',
  styleUrl: './reset-password.css',
})
export class ResetPassword {
  token = '';
  newPassword = '';
  confirmPassword = '';
  errorMessage = signal('');
  successMessage = signal('');
  loading = signal(false);
  showPassword = signal(false);

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private auth: Auth,
    public lang: LangService
  ) {
    this.token = this.route.snapshot.queryParamMap.get('token') || '';
  }

  togglePassword(): void {
    this.showPassword.update((v) => !v);
  }

  onSubmit(): void {
    this.errorMessage.set('');
    this.successMessage.set('');

    if (!this.token) {
      this.errorMessage.set(this.lang.t('resetPassword.errorInvalidToken'));
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      this.errorMessage.set(this.lang.t('resetPassword.errorMismatch'));
      return;
    }

    this.loading.set(true);

    this.auth.resetPassword(this.token, this.newPassword).subscribe({
      next: (res) => {
        this.loading.set(false);
        this.successMessage.set(res.message || this.lang.t('resetPassword.successMessage'));
        setTimeout(() => this.router.navigate(['/login']), 2500);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(err.error?.error || this.lang.t('resetPassword.errorDefault'));
      },
    });
  }
}
