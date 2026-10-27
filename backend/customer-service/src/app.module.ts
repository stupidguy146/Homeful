import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CustomerModule } from './customer.module';
import { CustomerRecord } from './infrastructure/persistence/orm/customer.persistence';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: parseInt(config.get<string>('DB_PORT', '5436'), 10),
        username: config.get<string>('DB_USER', 'customer'),
        password: config.get<string>('DB_PASSWORD', 'customer_pass'),
        database: config.get<string>('DB_NAME', 'customer_db'),
        entities: [CustomerRecord],
        synchronize: true, // dev only
      }),
    }),
    CustomerModule,
  ],
})
export class AppModule {}
