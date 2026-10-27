/**
 * Domain model for a customer profile. Pure TypeScript, no framework/DB deps.
 * Linked to the identity in auth-service via `ssoId` (the JWT `sub`).
 * `username` is unique and also serves as a login identifier (auth resolves
 * username → ssoId through this service).
 */
/** Allowed honorific titles (prefix). `unspecified` = user chose not to say. */
export const TITLE_VALUES = ['mr', 'mrs', 'ms', 'unspecified'] as const;
export type Title = (typeof TITLE_VALUES)[number];

export interface CustomerProfileProps {
  id?: number; // running PK (assigned by DB); optional before persistence
  ssoId: string;
  title: Title;
  username: string;
  firstName: string;
  lastName: string;
  avatarBase64: string | null;
  status: string | null;
  birthDate: string | null; // ISO date yyyy-mm-dd
  createdAt: Date;
  updatedAt: Date;
}

export class CustomerProfile {
  readonly id?: number;
  readonly ssoId: string;
  title: Title;
  username: string;
  firstName: string;
  lastName: string;
  avatarBase64: string | null;
  status: string | null;
  birthDate: string | null;
  readonly createdAt: Date;
  updatedAt: Date;

  constructor(props: CustomerProfileProps) {
    this.id = props.id;
    this.ssoId = props.ssoId;
    this.title = props.title;
    this.username = props.username;
    this.firstName = props.firstName;
    this.lastName = props.lastName;
    this.avatarBase64 = props.avatarBase64;
    this.status = props.status;
    this.birthDate = props.birthDate;
    this.createdAt = props.createdAt;
    this.updatedAt = props.updatedAt;
  }

  /** Factory used when auth-service provisions a profile at registration. */
  static create(params: {
    ssoId: string;
    title?: Title;
    username: string;
    firstName: string;
    lastName: string;
  }): CustomerProfile {
    const now = new Date();
    return new CustomerProfile({
      ssoId: params.ssoId,
      title: params.title ?? 'unspecified',
      username: params.username.trim(),
      firstName: params.firstName.trim(),
      lastName: params.lastName.trim(),
      avatarBase64: null,
      status: null,
      birthDate: null,
      createdAt: now,
      updatedAt: now,
    });
  }

  /** Fallback factory for a profile accessed before it was provisioned. */
  static createDefault(ssoId: string): CustomerProfile {
    return CustomerProfile.create({
      ssoId,
      username: '',
      firstName: '',
      lastName: '',
    });
  }

  /** Apply partial updates, mutating only provided fields. */
  applyUpdate(patch: {
    title?: Title;
    username?: string;
    firstName?: string;
    lastName?: string;
    avatarBase64?: string | null;
    status?: string | null;
    birthDate?: string | null;
  }): void {
    if (patch.title !== undefined) this.title = patch.title;
    if (patch.username !== undefined) this.username = patch.username;
    if (patch.firstName !== undefined) this.firstName = patch.firstName;
    if (patch.lastName !== undefined) this.lastName = patch.lastName;
    if (patch.avatarBase64 !== undefined) this.avatarBase64 = patch.avatarBase64;
    if (patch.status !== undefined) this.status = patch.status;
    if (patch.birthDate !== undefined) this.birthDate = patch.birthDate;
    this.updatedAt = new Date();
  }
}
