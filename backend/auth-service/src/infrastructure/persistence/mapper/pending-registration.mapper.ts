import { PendingRegistration } from '../../../domain/model/pending-registration';
import { PendingRegistrationRecord } from '../orm/pending-registration.persistence';

/** Maps between the domain PendingRegistration and its persistence record. */
export class PendingRegistrationMapper {
  static toRecord(p: PendingRegistration): PendingRegistrationRecord {
    const rec = new PendingRegistrationRecord();
    if (p.id !== undefined) rec.id = p.id;
    rec.email = p.email;
    rec.title = p.title;
    rec.username = p.username;
    rec.firstName = p.firstName;
    rec.lastName = p.lastName;
    rec.otpHash = p.otpHash;
    rec.otpExpiresAt = p.otpExpiresAt;
    rec.attempts = p.attempts;
    rec.emailVerified = p.emailVerified;
    rec.setupTicket = p.setupTicket;
    rec.setupTicketExpiresAt = p.setupTicketExpiresAt;
    rec.createdAt = p.createdAt;
    return rec;
  }

  static toDomain(rec: PendingRegistrationRecord): PendingRegistration {
    return new PendingRegistration({
      id: rec.id,
      email: rec.email,
      title: rec.title,
      username: rec.username,
      firstName: rec.firstName,
      lastName: rec.lastName,
      otpHash: rec.otpHash,
      otpExpiresAt: rec.otpExpiresAt,
      attempts: rec.attempts,
      emailVerified: rec.emailVerified,
      setupTicket: rec.setupTicket,
      setupTicketExpiresAt: rec.setupTicketExpiresAt,
      createdAt: rec.createdAt,
    });
  }
}
