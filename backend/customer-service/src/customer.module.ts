import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CustomerRecord } from './infrastructure/persistence/orm/customer.persistence';
import { CustomerRepositoryAdapter } from './infrastructure/persistence/customer.repository.adapter';
import { CUSTOMER_REPOSITORY } from './domain/port/customer.repository.port';
import { CustomerUseCases } from './application/use-case/customer.use-cases';
import { CustomerController } from './interface/http/customer.controller';

@Module({
  imports: [TypeOrmModule.forFeature([CustomerRecord])],
  controllers: [CustomerController],
  providers: [
    CustomerUseCases,
    // Hexagonal wiring: bind the outbound port to its concrete adapter.
    { provide: CUSTOMER_REPOSITORY, useClass: CustomerRepositoryAdapter },
  ],
})
export class CustomerModule {}
