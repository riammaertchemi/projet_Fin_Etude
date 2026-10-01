import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Auth } from '../../services/auth';
import { LangService } from '../../services/lang';
import { TranslatePipe } from '../../pipes/translate';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, TranslatePipe],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  email = localStorage.getItem('rememberedEmail') || '';
  password = '';
  rememberMe = !!localStorage.getItem('rememberedEmail');
  errorMessage = signal('');
  loading = signal(false);
  showPassword = signal(false);

  constructor(private auth: Auth, private router: Router, public lang: LangService) {}

  togglePassword(): void {
    this.showPassword.update((v) => !v);
  }

  onSubmit(): void {
    this.errorMessage.set('');
    this.loading.set(true);

    this.auth.login(this.email, this.password).subscribe({
      next: () => {
        this.loading.set(false);
        if (this.rememberMe) {
          localStorage.setItem('rememberedEmail', this.email);
        } else {
          localStorage.removeItem('rememberedEmail');
        }
        this.router.navigate(['/home']);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(err.error?.error || this.lang.t('login.errorDefault'));
      },
    });
  }
}
