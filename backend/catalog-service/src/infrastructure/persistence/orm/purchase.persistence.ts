import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('purchases')
@Index(['ssoId', 'purchasedAt'])
export class PurchaseRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  purchaseId: string;

  @Index()
  @Column({ type: 'uuid' })
  productId: string;

  @Index()
  @Column({ type: 'uuid' })
  ssoId: string;

  @Column({ type: 'int', default: 1 })
  quantity: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: 0 })
  price: string;

  @Column({ type: 'varchar', length: 80, nullable: true })
  buyer: string | null;

  @Column({ type: 'varchar', length: 120, nullable: true })
  store: string | null;

  @Column({ type: 'date' })
  purchasedAt: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
