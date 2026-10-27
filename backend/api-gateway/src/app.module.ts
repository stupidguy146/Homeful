import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { ProxyService } from './proxy/proxy.service';
import { CatalogProxyController } from './interface/catalog.proxy.controller';
import { AnalyticsProxyController } from './interface/analytics.proxy.controller';
import { AuthProxyController } from './interface/auth.proxy.controller';
import { CustomerProxyController } from './interface/customer.proxy.controller';
import { JwtVerifyGuard } from './interface/jwt-verify.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // Shared JWT secret with auth-service so the gateway can verify access
    // tokens locally without a round-trip per request.
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET', 'dev_access_secret_change_me'),
      }),
    }),
  ],
  controllers: [
    AuthProxyController,
    CustomerProxyController,
    CatalogProxyController,
    AnalyticsProxyController,
  ],
  providers: [ProxyService, JwtVerifyGuard],
})
export class AppModule {}
