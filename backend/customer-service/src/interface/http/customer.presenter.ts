import { CustomerProfile } from '../../domain/model/customer-profile';

/** Converts the domain profile into the HTTP JSON shape. */
export class CustomerPresenter {
  static profile(p: CustomerProfile) {
    return {
      id: p.id,
      ssoId: p.ssoId,
      username: p.username,
      firstName: p.firstName,
      lastName: p.lastName,
      avatarBase64: p.avatarBase64,
      status: p.status,
      birthDate: p.birthDate,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    };
  }
}
