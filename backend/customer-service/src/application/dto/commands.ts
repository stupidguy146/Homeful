/** Application-level command shapes (framework-agnostic). */

export interface CreateProfileCommand {
  ssoId: string;
  username: string;
  firstName: string;
  lastName: string;
}

export interface UpdateProfileCommand {
  username?: string;
  firstName?: string;
  lastName?: string;
  avatarBase64?: string | null;
  status?: string | null;
  birthDate?: string | null; // ISO yyyy-mm-dd
}
