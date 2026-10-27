import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AnalyticsUseCases } from './application/use-case/analytics.use-cases';
import { CatalogHttpAdapter } from './infrastructure/catalog/catalog.http.adapter';
import { CATALOG_PORT } from './domain/port/catalog.port';
import { AnalyticsController } from './interface/http/analytics.controller';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [AnalyticsController],
  providers: [
    AnalyticsUseCases,
    // Hexagonal wiring: bind the outbound port to the REST adapter.
    { provide: CATALOG_PORT, useClass: CatalogHttpAdapter },
  ],
})
export class AppModule {}
