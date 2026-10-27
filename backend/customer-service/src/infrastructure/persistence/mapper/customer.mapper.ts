import { CustomerProfile } from '../../../domain/model/customer-profile';
import { CustomerRecord } from '../orm/customer.persistence';

export class CustomerMapper {
  static toRecord(p: CustomerProfile): CustomerRecord {
    const rec = new CustomerRecord();
    if (p.id !== undefined) rec.id = p.id;
    rec.ssoId = p.ssoId;
    rec.username = p.username;
    rec.firstName = p.firstName;
    rec.lastName = p.lastName;
    rec.avatarBase64 = p.avatarBase64;
    rec.status = p.status;
    rec.birthDate = p.birthDate;
    rec.createdAt = p.createdAt;
    rec.updatedAt = p.updatedAt;
    return rec;
  }

  static toDomain(rec: CustomerRecord): CustomerProfile {
    return new CustomerProfile({
      id: rec.id,
      ssoId: rec.ssoId,
      username: rec.username,
      firstName: rec.firstName,
      lastName: rec.lastName,
      avatarBase64: rec.avatarBase64,
      status: rec.status,
      birthDate: rec.birthDate,
      createdAt: rec.createdAt,
      updatedAt: rec.updatedAt,
    });
  }
}
