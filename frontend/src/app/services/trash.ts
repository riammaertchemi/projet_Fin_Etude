import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Product } from './product';
import { Category } from './category';
import { Supplier } from './supplier';
import { StockMovement } from './stock-movement';
 
export interface TrashData {
  products: (Product & { deletedAt: string })[];
  categories: (Category & { deletedAt: string })[];
  suppliers: (Supplier & { deletedAt: string })[];
  movements: (StockMovement & { deletedAt: string })[];
}
 
@Injectable({ providedIn: 'root' })
export class TrashService {
  private apiUrl = 'http://localhost:3000/api';
 
  constructor(private http: HttpClient) {}
 
  getTrash(): Observable<TrashData> {
    return this.http.get<TrashData>(`${this.apiUrl}/trash`);
  }
 
  restoreProduct(id: number): Observable<Product> {
    return this.http.post<Product>(`${this.apiUrl}/products/${id}/restore`, {});
  }
 
  restoreCategory(id: number): Observable<Category> {
    return this.http.post<Category>(`${this.apiUrl}/categories/${id}/restore`, {});
  }
 
  restoreSupplier(id: number): Observable<Supplier> {
    return this.http.post<Supplier>(`${this.apiUrl}/suppliers/${id}/restore`, {});
  }
 
  restoreMovement(id: number): Observable<StockMovement> {
    return this.http.post<StockMovement>(`${this.apiUrl}/movements/${id}/restore`, {});
  }
 
  permanentDeleteProduct(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/products/${id}/permanent`);
  }
 
  permanentDeleteCategory(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/categories/${id}/permanent`);
  }
 
  permanentDeleteSupplier(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/suppliers/${id}/permanent`);
  }
 
  permanentDeleteMovement(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/movements/${id}/permanent`);
  }
}
