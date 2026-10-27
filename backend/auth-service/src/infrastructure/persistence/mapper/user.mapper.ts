import { User } from '../../../domain/model/user';
import { UserRecord } from '../orm/user.persistence';

/** Maps between the domain User and the persistence UserRecord. */
export class UserMapper {
  static toRecord(user: User): UserRecord {
    const rec = new UserRecord();
    if (user.id !== undefined) rec.id = user.id;
    rec.ssoId = user.ssoId;
    rec.email = user.email;
    rec.passwordHash = user.passwordHash;
    rec.emailVerified = user.emailVerified;
    rec.verifyToken = user.verifyToken;
    rec.resetToken = user.resetToken;
    rec.resetTokenExpiresAt = user.resetTokenExpiresAt;
    rec.createdAt = user.createdAt;
    return rec;
  }

  static toDomain(rec: UserRecord): User {
    return new User(rec.ssoId, rec.email, rec.passwordHash, rec.createdAt, {
      id: rec.id,
      emailVerified: rec.emailVerified,
      verifyToken: rec.verifyToken,
      resetToken: rec.resetToken,
      resetTokenExpiresAt: rec.resetTokenExpiresAt,
    });
  }
}
