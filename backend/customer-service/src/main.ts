import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import { AppModule } from './app.module';
import { DomainExceptionFilter } from './shared/domain-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('customer');
  // avatars are base64 strings → allow a larger JSON body (default is 100kb)
  app.use(express.json({ limit: '5mb' }));
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useGlobalFilters(new DomainExceptionFilter());
  app.enableCors();
  const port = process.env.PORT ?? 3004;
  await app.listen(port);
  console.log(`customer-service listening on port ${port}`);
}
bootstrap();
