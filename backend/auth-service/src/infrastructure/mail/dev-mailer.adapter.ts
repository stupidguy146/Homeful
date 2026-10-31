import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { MailerPort } from '../../domain/port/mailer.port';

/**
 * Dev mail adapter. Tries to create an Ethereal test account (fake SMTP that
 * captures messages and returns a preview URL). If that fails (e.g. offline),
 * it falls back to logging the email + link to the console.
 *
 * Swap this adapter for a real SMTP/SES/SendGrid implementation in production.
 */
@Injectable()
export class DevMailerAdapter implements MailerPort, OnModuleInit {
  private readonly logger = new Logger(DevMailerAdapter.name);
  private transporter: nodemailer.Transporter | null = null;

  async onModuleInit(): Promise<void> {
    try {
      const testAccount = await nodemailer.createTestAccount();
      this.transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: { user: testAccount.user, pass: testAccount.pass },
      });
      this.logger.log('Ethereal dev SMTP ready (emails captured with preview URL)');
    } catch (err: any) {
      this.transporter = null;
      this.logger.warn(
        `Ethereal unavailable (${err?.message}); emails will be logged to console only`,
      );
    }
  }

  async sendVerificationEmail(to: string, verifyUrl: string): Promise<void> {
    await this.send(
      to,
      'ยืนยันอีเมลของคุณ',
      `กรุณายืนยันอีเมลโดยคลิกลิงก์นี้: ${verifyUrl}`,
      `<p>ยินดีต้อนรับ! กรุณายืนยันอีเมลของคุณ</p>
       <p><a href="${verifyUrl}">ยืนยันอีเมล</a></p>
       <p>หรือคัดลอกลิงก์: ${verifyUrl}</p>`,
    );
  }

  async sendOtpEmail(to: string, otp: string): Promise<void> {
    // Dev convenience: always surface the OTP in the console, even when the
    // email itself is delivered to an external inbox (e.g. Ethereal preview).
    this.logger.log(`[DEV OTP] to=${to} code=${otp}`);
    await this.send(
      to,
      'รหัสยืนยันอีเมล (OTP)',
      `รหัสยืนยันของคุณคือ ${otp} (หมดอายุใน 10 นาที)`,
      `<p>รหัสยืนยันอีเมลของคุณคือ:</p>
       <p style="font-size:28px;font-weight:bold;letter-spacing:6px;">${otp}</p>
       <p>รหัสนี้จะหมดอายุใน 10 นาที หากคุณไม่ได้ร้องขอ สามารถเพิกเฉยอีเมลนี้ได้</p>`,
    );
  }

  async sendPasswordResetEmail(to: string, resetUrl: string): Promise<void> {
    await this.send(
      to,
      'รีเซ็ตรหัสผ่าน',      `รีเซ็ตรหัสผ่านโดยคลิกลิงก์นี้: ${resetUrl}`,
      `<p>มีคำขอรีเซ็ตรหัสผ่านสำหรับบัญชีนี้</p>
       <p><a href="${resetUrl}">ตั้งรหัสผ่านใหม่</a></p>
       <p>หรือคัดลอกลิงก์: ${resetUrl}</p>
       <p>ถ้าคุณไม่ได้ร้องขอ สามารถเพิกเฉยอีเมลนี้ได้</p>`,
    );
  }

  private async send(
    to: string,
    subject: string,
    text: string,
    html: string,
  ): Promise<void> {
    if (!this.transporter) {
      this.logger.log(
        `[DEV EMAIL] to=${to} | ${subject}\n${text}`,
      );
      return;
    }
    const info = await this.transporter.sendMail({
      from: '"Checkon" <no-reply@example.com>',
      to,
      subject,
      text,
      html,
    });
    const preview = nodemailer.getTestMessageUrl(info);
    this.logger.log(`[DEV EMAIL] to=${to} | ${subject} | preview: ${preview}`);
  }
}
