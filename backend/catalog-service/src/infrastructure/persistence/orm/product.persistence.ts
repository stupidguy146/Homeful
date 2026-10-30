import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('products')
export class ProductRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  productId: string;

  @Index()
  @Column({ type: 'uuid' })
  ssoId: string;

  @Column({ type: 'varchar', length: 160 })
  name: string;

  @Column({ type: 'varchar', length: 20 })
  category: string;

  @Column({ type: 'varchar', length: 40, nullable: true })
  size: string | null;

  @Column({ type: 'varchar', length: 40, nullable: true })
  unit: string | null;

  @Column({ type: 'varchar', length: 40, nullable: true })
  unitLabel: string | null;

  @Column({ type: 'text', nullable: true })
  imageBase64: string | null;

  @Column({ type: 'boolean', default: false })
  isRecurring: boolean;

  @Column({ type: 'int', nullable: true })
  recurringDaysManual: number | null;

  @Column({ type: 'date', nullable: true })
  expiryDate: string | null;

  @Column({ type: 'varchar', length: 12, default: 'in_stock' })
  status: string;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  sourceItemId: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
