import { ComponentFixture, TestBed } from '@angular/core/testing';
import { StockMovements } from './stock-movements';

describe('StockMovements', () => {
  let component: StockMovements;
  let fixture: ComponentFixture<StockMovements>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [StockMovements],
    }).compileComponents();

    fixture = TestBed.createComponent(StockMovements);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
