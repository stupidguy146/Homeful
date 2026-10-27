/** Application-level command/result shapes (not HTTP DTOs). */

export interface RegisterCommand {
  email: string;
  username: string;
  firstName: string;
  lastName: string;
  password: string;
}

export interface LoginCommand {
  identifier: string; // email or username
  password: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResult extends AuthTokens {
  user: {
    ssoId: string;
    email: string;
    emailVerified: boolean;
  };
}
