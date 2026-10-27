/** Application-level command shapes (framework-agnostic). */

import { Title } from '../../domain/model/customer-profile';

export interface CreateProfileCommand {
  ssoId: string;
  title?: Title;
  username: string;
  firstName: string;
  lastName: string;
}

export interface UpdateProfileCommand {
  title?: Title;
  username?: string;
  firstName?: string;
  lastName?: string;
  avatarBase64?: string | null;
  status?: string | null;
  birthDate?: string | null; // ISO yyyy-mm-dd
}
