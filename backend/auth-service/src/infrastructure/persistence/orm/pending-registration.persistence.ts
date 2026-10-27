import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

/**
 * Persistence record for a pending registration (before the account exists).
 * Keyed by email (unique). Cleared once the user completes set-password.
 */
@Entity('pending_registrations')
@Unique(['email'])
export class PendingRegistrationRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255 })
  email: string;

  @Column({ type: 'varchar', length: 20, default: 'unspecified' })
  title: string;

  @Column({ type: 'varchar', length: 60 })
  username: string;

  @Column({ type: 'varchar', length: 80 })
  firstName: string;

  @Column({ type: 'varchar', length: 80 })
  lastName: string;

  @Column({ type: 'text' })
  otpHash: string;

  @Column({ type: 'timestamptz' })
  otpExpiresAt: Date;

  @Column({ type: 'int', default: 0 })
  attempts: number;

  @Column({ type: 'boolean', default: false })
  emailVerified: boolean;

  @Column({ type: 'text', nullable: true })
  setupTicket: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  setupTicketExpiresAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
