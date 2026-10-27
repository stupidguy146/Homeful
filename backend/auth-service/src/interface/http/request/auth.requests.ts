import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

/** Inbound HTTP request DTOs. class-validator lives here, not in domain. */

const USERNAME_RE = /^[a-zA-Z0-9._-]+$/;
const TITLE_VALUES = ['mr', 'mrs', 'ms', 'unspecified'] as const;
const OTP_RE = /^[0-9]{6}$/;

/** Step 1: start registration (no password here — set after OTP verify). */
export class RegisterRequest {
  @IsEmail({}, { message: 'invalid email' })
  email: string;

  @IsEnum(TITLE_VALUES, { message: 'invalid title' })
  title: string;

  @IsString()
  @MinLength(3)
  @MaxLength(30)
  @Matches(USERNAME_RE, { message: 'username contains invalid characters' })
  username: string;

  @IsString()
  @IsNotEmpty({ message: 'first name is required' })
  @MaxLength(80)
  firstName: string;

  @IsString()
  @IsNotEmpty({ message: 'last name is required' })
  @MaxLength(80)
  lastName: string;
}

/** Step 2: verify the emailed OTP. */
export class VerifyOtpRequest {
  @IsEmail({}, { message: 'invalid email' })
  email: string;

  @IsString()
  @Matches(OTP_RE, { message: 'OTP must be 6 digits' })
  otp: string;
}

/** Re-send the OTP for an in-progress registration. */
export class ResendOtpRequest {
  @IsEmail({}, { message: 'invalid email' })
  email: string;
}

/** Step 3: set the password using the ticket from verify-otp. */
export class SetPasswordRequest {
  @IsEmail({}, { message: 'invalid email' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'setup ticket is required' })
  setupTicket: string;

  @IsString()
  @MinLength(8, { message: 'password must be at least 8 characters' })
  @MaxLength(100)
  password: string;
}

export class LoginRequest {
  // email or username
  @IsString()
  @IsNotEmpty({ message: 'identifier is required' })
  identifier: string;

  @IsString()
  @IsNotEmpty({ message: 'password is required' })
  password: string;
}

export class RefreshRequest {
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}

export class ChangePasswordRequest {
  @IsString()
  @IsNotEmpty({ message: 'current password is required' })
  oldPassword: string;

  @IsString()
  @MinLength(8, { message: 'new password must be at least 8 characters' })
  @MaxLength(100)
  newPassword: string;
}

export class ForgotPasswordRequest {
  @IsEmail({}, { message: 'invalid email' })
  email: string;
}

export class ResetPasswordRequest {
  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @MinLength(8, { message: 'new password must be at least 8 characters' })
  @MaxLength(100)
  newPassword: string;
}
