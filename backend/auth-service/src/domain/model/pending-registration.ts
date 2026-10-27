/**
 * Domain model for a pending (not-yet-completed) registration.
 *
 * New registration flow:
 *   1. register    → create a PendingRegistration + email an OTP
 *   2. verify-otp  → mark verified, issue a short-lived setup ticket
 *   3. set-password→ create the real User + customer profile, delete pending
 *
 * Pure TypeScript — no framework/DB dependencies.
 */
export class PendingRegistration {
  readonly id?: number;
  readonly email: string;
  title: string;
  username: string;
  firstName: string;
  lastName: string;
  otpHash: string;
  otpExpiresAt: Date;
  attempts: number;
  emailVerified: boolean;
  /** Random ticket proving OTP was verified; required to set the password. */
  setupTicket: string | null;
  setupTicketExpiresAt: Date | null;
  readonly createdAt: Date;

  constructor(props: {
    id?: number;
    email: string;
    title: string;
    username: string;
    firstName: string;
    lastName: string;
    otpHash: string;
    otpExpiresAt: Date;
    attempts?: number;
    emailVerified?: boolean;
    setupTicket?: string | null;
    setupTicketExpiresAt?: Date | null;
    createdAt?: Date;
  }) {
    this.id = props.id;
    this.email = props.email.toLowerCase().trim();
    this.title = props.title;
    this.username = props.username;
    this.firstName = props.firstName;
    this.lastName = props.lastName;
    this.otpHash = props.otpHash;
    this.otpExpiresAt = props.otpExpiresAt;
    this.attempts = props.attempts ?? 0;
    this.emailVerified = props.emailVerified ?? false;
    this.setupTicket = props.setupTicket ?? null;
    this.setupTicketExpiresAt = props.setupTicketExpiresAt ?? null;
    this.createdAt = props.createdAt ?? new Date();
  }

  isOtpExpired(now: Date = new Date()): boolean {
    return this.otpExpiresAt.getTime() < now.getTime();
  }

  isTicketValid(ticket: string, now: Date = new Date()): boolean {
    return (
      this.emailVerified &&
      this.setupTicket !== null &&
      this.setupTicket === ticket &&
      this.setupTicketExpiresAt !== null &&
      this.setupTicketExpiresAt.getTime() >= now.getTime()
    );
  }
}
