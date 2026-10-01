import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Auth, AppUser } from '../../services/auth';
import { LangService } from '../../services/lang';
import { TranslatePipe } from '../../pipes/translate';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslatePipe],
  templateUrl: './profile.html',
  styleUrl: './profile.css'
})
export class Profile implements OnInit {
  user: AppUser | null = null;
  showForm = false;
  saving = false;
  errorMessage = '';

  form: { name: string; email: string; phone: string; avatarUrl: string | null } = {
    name: '',
    email: '',
    phone: '',
    avatarUrl: null
  };

  private roleKeyMap: Record<string, string> = {
    ADMIN: 'admin',
    MANAGER: 'manager',
    EMPLOYE: 'employe',
    AGENT_LOGISTIQUE: 'agentLogistique',
    RESPONSABLE_LOGISTIQUE: 'responsableLogistique',
    DIRECTEUR_GENERAL: 'directeurGeneral'
  };

  constructor(private auth: Auth, private cdr: ChangeDetectorRef, public lang: LangService) {}

  ngOnInit(): void {
    this.auth.getMe().subscribe({
      next: (user) => {
        this.user = user;
        this.cdr.detectChanges();
      },
      error: () => {
        this.user = this.auth.currentUser();
        this.cdr.detectChanges();
      }
    });
  }

  get roleLabel(): string {
    if (!this.user?.role) return '';
    const key = this.roleKeyMap[this.user.role];
    return key ? this.lang.t('roles.' + key) : this.user.role;
  }

  get initials(): string {
    const name = this.user?.name || '';
    return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]?.toUpperCase()).join('');
  }

  openEditForm(): void {
    if (!this.user) return;
    this.form = {
      name: this.user.name || '',
      email: this.user.email || '',
      phone: this.user.phone || '',
      avatarUrl: this.user.avatarUrl || null
    };
    this.errorMessage = '';
    this.showForm = true;
  }

  closeForm(): void {
    this.showForm = false;
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      this.errorMessage = this.lang.t('profile.errorImageInvalid');
      return;
    }
    if (file.size > 3 * 1024 * 1024) {
      this.errorMessage = this.lang.t('profile.errorImageTooLarge');
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      this.form.avatarUrl = reader.result as string;
      this.cdr.detectChanges();
    };
    reader.readAsDataURL(file);
  }

  removeImage(): void {
    this.form.avatarUrl = null;
  }

  save(): void {
    this.saving = true;
    this.errorMessage = '';
    this.auth.updateProfile({
      name: this.form.name,
      email: this.form.email,
      phone: this.form.phone || null,
      avatarUrl: this.form.avatarUrl
    }).subscribe({
      next: (user) => {
        this.user = user;
        this.saving = false;
        this.showForm = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.errorMessage = err.error?.error || this.lang.t('profile.errorUpdate');
        this.saving = false;
        this.cdr.detectChanges();
      }
    });
  }
}
