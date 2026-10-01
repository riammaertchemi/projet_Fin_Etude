import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Supplier, SupplierService } from '../../services/supplier';

@Component({
  selector: 'app-suppliers',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './suppliers.html',
  styleUrl: './suppliers.css'
})
export class Suppliers implements OnInit {
  suppliers: Supplier[] = [];
  loading = true;
  error = '';

  constructor(
    private supplierService: SupplierService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.supplierService.getAll().subscribe({
      next: (data) => {
        this.suppliers = data;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = 'Erreur lors du chargement des fournisseurs';
        this.loading = false;
        this.cdr.detectChanges();
        console.error(err);
      }
    });
  }
}