import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { AuthModule } from './auth.module';
import { UserRecord } from './infrastructure/persistence/orm/user.persistence';
import { PendingRegistrationRecord } from './infrastructure/persistence/orm/pending-registration.persistence';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: parseInt(config.get<string>('DB_PORT', '5435'), 10),
        username: config.get<string>('DB_USER', 'auth'),
        password: config.get<string>('DB_PASSWORD', 'auth_pass'),
        database: config.get<string>('DB_NAME', 'auth_db'),
        entities: [UserRecord, PendingRegistrationRecord],
        synchronize: true, // dev only
      }),
    }),
    // JWT is global so use-cases can inject JwtService directly.
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET', 'dev_access_secret_change_me'),
      }),
    }),
    AuthModule,
  ],
})
export class AppModule {}
