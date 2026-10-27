import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

/**
 * Persistence record for a household item.
 * - `id`: running integer PK (internal)
 * - `itemId`: public UUID
 * - `ssoId`: owner (cross-service ref)
 */
@Entity('household_items')
export class HouseholdItemRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  itemId: string;

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

  @Column({ type: 'int', default: 1 })
  quantity: number;

  @Column({ type: 'varchar', length: 40, nullable: true })
  unitLabel: string | null;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: 0 })
  price: string;

  @Column({ type: 'varchar', length: 120, nullable: true })
  store: string | null;

  @Column({ type: 'date', nullable: true })
  purchaseDate: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  buyer: string | null;

  @Column({ type: 'date', nullable: true })
  expiryDate: string | null;

  @Column({ type: 'text', nullable: true })
  imageBase64: string | null;

  @Column({ type: 'boolean', default: false })
  notifyRecurring: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
