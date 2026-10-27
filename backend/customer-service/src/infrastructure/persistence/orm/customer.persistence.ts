import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * Persistence record for a customer profile.
 * - `id`: running integer primary key (internal)
 * - `ssoId`: UUID from auth-service (cross-service reference, JWT sub) — unique
 * - `username`: unique handle, also a login identifier (auth resolves via this)
 */
@Entity('customer_profiles')
export class CustomerRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  ssoId: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 60 })
  username: string;

  @Column({ type: 'varchar', length: 80, default: '' })
  firstName: string;

  @Column({ type: 'varchar', length: 80, default: '' })
  lastName: string;

  // base64 data URL of the avatar image (dev); nullable
  @Column({ type: 'text', nullable: true })
  avatarBase64: string | null;

  @Column({ type: 'varchar', length: 280, nullable: true })
  status: string | null;

  @Column({ type: 'date', nullable: true })
  birthDate: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
