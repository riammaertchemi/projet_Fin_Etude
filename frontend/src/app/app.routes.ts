import { Routes } from '@angular/router';
import { Login } from './pages/login/login';
import { Register } from './pages/register/register';
import { ForgotPassword } from './pages/forgot-password/forgot-password';
import { ResetPassword } from './pages/reset-password/reset-password';
import { Home } from './pages/home/home';
import { Products } from './pages/products/products';
import { Categories } from './pages/categories/categories';
import { Suppliers } from './pages/suppliers/suppliers';
import { StockMovements } from './pages/stock-movements/stock-movements';
import { Alerts } from './pages/alerts/alerts';
import { Profile } from './pages/profile/profile';
import { Trash } from './pages/trash/trash';
 
export const routes: Routes = [
  { path: 'login', component: Login },
  { path: 'register', component: Register },
  { path: 'forgot-password', component: ForgotPassword },
  { path: 'reset-password', component: ResetPassword },
  { path: 'home', component: Home },
  { path: 'products', component: Products },
  { path: 'categories', component: Categories },
  { path: 'suppliers', component: Suppliers },
  { path: 'stock-movements', component: StockMovements },
  { path: 'alerts', component: Alerts },
  { path: 'profile', component: Profile },
  { path: 'trash', component: Trash },
  { path: '', redirectTo: '/login', pathMatch: 'full' }
];
