/**
 * Outbound port for sending transactional emails.
 * The application depends on this interface, not on any mail provider.
 */
export interface MailerPort {
  sendVerificationEmail(to: string, verifyUrl: string): Promise<void>;
  sendPasswordResetEmail(to: string, resetUrl: string): Promise<void>;
}

export const MAILER = Symbol('MAILER');
