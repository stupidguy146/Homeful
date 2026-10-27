/**
 * Outbound port: auth-service talks to customer-service for the parts of
 * identity that live there (username + profile). The application depends on
 * this interface, not on HTTP/axios directly.
 */
export interface CustomerClientPort {
  /** Provision a profile at registration. Returns nothing (or throws). */
  createProfile(params: {
    ssoId: string;
    username: string;
    firstName: string;
    lastName: string;
  }): Promise<void>;

  /** Resolve a username to its ssoId (for username login). null if not found. */
  findSsoIdByUsername(username: string): Promise<string | null>;
}

export const CUSTOMER_CLIENT = Symbol('CUSTOMER_CLIENT');
