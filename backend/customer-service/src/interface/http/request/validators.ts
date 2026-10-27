import {
  registerDecorator,
  ValidationOptions,
  ValidationArguments,
} from 'class-validator';

// ~3MB of base64 text (keeps request bodies sane for dev)
const MAX_LEN = 3_000_000;
const DATA_URL = /^data:image\/[a-zA-Z0-9.+-]+;base64,[A-Za-z0-9+/=]+$/;
const PLAIN_B64 = /^[A-Za-z0-9+/=]+$/;

/**
 * Accepts: null (clear avatar), a data-url image string, or plain base64.
 * Rejects overly large payloads.
 */
export function IsBase64OrDataUrl(options?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isBase64OrDataUrl',
      target: object.constructor,
      propertyName,
      options,
      validator: {
        validate(value: unknown, _args: ValidationArguments) {
          if (value === null) return true;
          if (typeof value !== 'string') return false;
          if (value.length > MAX_LEN) return false;
          return DATA_URL.test(value) || PLAIN_B64.test(value);
        },
        defaultMessage() {
          return 'avatarBase64 ต้องเป็น data URL รูปภาพ, base64 หรือ null และไม่เกินขนาดที่กำหนด';
        },
      },
    });
  };
}
