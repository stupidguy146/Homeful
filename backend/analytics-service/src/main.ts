import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DomainExceptionFilter } from './shared/domain-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('analytics');
  app.useGlobalFilters(new DomainExceptionFilter());
  app.enableCors();
  const port = process.env.PORT ?? 3002;
  await app.listen(port);
  console.log(`analytics-service listening on port ${port}`);
}
bootstrap();
