/** Application-level command/result shapes (not HTTP DTOs). */

export interface RegisterCommand {
  email: string;
  title: string;
  username: string;
  firstName: string;
  lastName: string;
}

/** Result of starting a registration (OTP sent, no session yet). */
export interface RegisterResult {
  email: string;
  otpExpiresInSec: number;
}

export interface VerifyOtpCommand {
  email: string;
  otp: string;
}

/** Result of verifying the OTP: a short-lived ticket to set the password. */
export interface VerifyOtpResult {
  email: string;
  setupTicket: string;
}

export interface SetPasswordCommand {
  email: string;
  setupTicket: string;
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
