import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface StockMovement {
  id: number;
  productId: number;
  type: string;
  quantity: number;
  reason?: string | null;
  createdAt: string;
  product?: { id: number; name: string };
}

@Injectable({ providedIn: 'root' })
export class StockMovementService {
  private apiUrl = 'http://localhost:3000/api/movements';

  constructor(private http: HttpClient) {}

  getAll(): Observable<StockMovement[]> {
    return this.http.get<StockMovement[]>(this.apiUrl);
  }

  create(movement: { productId: number; type: string; quantity: number; reason?: string; date?: string }): Observable<StockMovement> {
    return this.http.post<StockMovement>(this.apiUrl, movement);
  }

  update(id: number, movement: { productId: number; type: string; quantity: number; reason?: string; date?: string }): Observable<StockMovement> {
    return this.http.put<StockMovement>(`${this.apiUrl}/${id}`, movement);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}