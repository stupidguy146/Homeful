import { NestFactory } from '@nestjs/core';
import * as express from 'express';
import { AppModule } from './app.module';
import { DomainExceptionFilter } from './shared/domain-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // allow large JSON bodies (base64 avatars flow through /api/customer)
  app.use(express.json({ limit: '6mb' }));
  app.useGlobalFilters(new DomainExceptionFilter());
  app.enableCors();
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`api-gateway listening on port ${port}`);
}
bootstrap();
