import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HouseholdItemRecord } from './infrastructure/persistence/orm/household-item.persistence';
import { ItemRepositoryAdapter } from './infrastructure/persistence/item.repository.adapter';
import { ITEM_REPOSITORY } from './domain/port/item.repository.port';
import { ItemUseCases } from './application/use-case/item.use-cases';
import { ItemController } from './interface/http/catalog.controller';

@Module({
  imports: [TypeOrmModule.forFeature([HouseholdItemRecord])],
  controllers: [ItemController],
  providers: [
    ItemUseCases,
    { provide: ITEM_REPOSITORY, useClass: ItemRepositoryAdapter },
  ],
})
export class CatalogModule {}
