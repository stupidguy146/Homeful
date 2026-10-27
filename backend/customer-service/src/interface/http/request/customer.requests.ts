import { IsBase64OrDataUrl } from './validators';
import {
  IsDateString,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

// username: 3-30 chars, letters/numbers/dot/underscore/hyphen
const USERNAME_RE = /^[a-zA-Z0-9._-]+$/;

/** Internal request used by auth-service to provision a profile at register. */
export class CreateProfileRequest {
  @IsUUID()
  ssoId: string;

  @IsString()
  @MinLength(3)
  @MaxLength(30)
  @Matches(USERNAME_RE, { message: 'username contains invalid characters' })
  username: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  firstName: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  lastName: string;
}

/** Inbound HTTP request DTO for updating the signed-in user's profile. */
export class UpdateProfileRequest {
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(30)
  @Matches(USERNAME_RE, { message: 'username contains invalid characters' })
  username?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  firstName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  lastName?: string;

  // base64 data URL (e.g. "data:image/png;base64,....") or null to clear
  @IsOptional()
  @IsBase64OrDataUrl()
  avatarBase64?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  status?: string | null;

  @IsOptional()
  @IsDateString()
  birthDate?: string | null;
}
