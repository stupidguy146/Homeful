import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserRecord } from './infrastructure/persistence/orm/user.persistence';
import { UserRepositoryAdapter } from './infrastructure/persistence/user.repository.adapter';
import { USER_REPOSITORY } from './domain/port/user.repository.port';
import { MAILER } from './domain/port/mailer.port';
import { DevMailerAdapter } from './infrastructure/mail/dev-mailer.adapter';
import { CUSTOMER_CLIENT } from './domain/port/customer.client.port';
import { CustomerHttpClient } from './infrastructure/customer/customer.http.client';
import { AuthUseCases } from './application/use-case/auth.use-cases';
import { AuthController } from './interface/http/auth.controller';
import { JwtAuthGuard } from './interface/http/jwt-auth.guard';

@Module({
  imports: [TypeOrmModule.forFeature([UserRecord])],
  controllers: [AuthController],
  providers: [
    AuthUseCases,
    JwtAuthGuard,
    // Hexagonal wiring: bind the outbound ports to concrete adapters.
    { provide: USER_REPOSITORY, useClass: UserRepositoryAdapter },
    { provide: MAILER, useClass: DevMailerAdapter },
    { provide: CUSTOMER_CLIENT, useClass: CustomerHttpClient },
  ],
})
export class AuthModule {}
