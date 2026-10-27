import {
  IsEmail,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

/** Inbound HTTP request DTOs. class-validator lives here, not in domain. */

const USERNAME_RE = /^[a-zA-Z0-9._-]+$/;

export class RegisterRequest {
  @IsEmail({}, { message: 'invalid email' })
  email: string;

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
