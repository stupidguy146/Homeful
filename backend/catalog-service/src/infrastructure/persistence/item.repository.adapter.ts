import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ItemRepositoryPort } from '../../domain/port/item.repository.port';
import { HouseholdItem } from '../../domain/model/household-item';
import { Category } from '../../shared/categories';
import { HouseholdItemRecord } from './orm/household-item.persistence';
import { HouseholdItemMapper } from './mapper/household-item.mapper';

@Injectable()
export class ItemRepositoryAdapter implements ItemRepositoryPort {
  constructor(
    @InjectRepository(HouseholdItemRecord)
    private readonly items: Repository<HouseholdItemRecord>,
  ) {}

  async create(item: HouseholdItem): Promise<HouseholdItem> {
    const saved = await this.items.save(HouseholdItemMapper.toRecord(item));
    return HouseholdItemMapper.toDomain(saved);
  }

  async findAll(ssoId: string, category?: Category): Promise<HouseholdItem[]> {
    const rows = await this.items.find({
      where: category ? { ssoId, category } : { ssoId },
      order: { createdAt: 'DESC' },
    });
    return rows.map((r) => HouseholdItemMapper.toDomain(r));
  }

  async findById(itemId: string, ssoId: string): Promise<HouseholdItem | null> {
    const row = await this.items.findOne({ where: { itemId, ssoId } });
    return row ? HouseholdItemMapper.toDomain(row) : null;
  }

  async update(item: HouseholdItem): Promise<HouseholdItem> {
    const record = HouseholdItemMapper.toRecord(item);
    if (record.id === undefined) {
      const existing = await this.items.findOne({
        where: { itemId: item.itemId, ssoId: item.ssoId },
        select: { id: true },
      });
      if (existing) record.id = existing.id;
    }
    const saved = await this.items.save(record);
    return HouseholdItemMapper.toDomain(saved);
  }

  async delete(itemId: string, ssoId: string): Promise<void> {
    await this.items.delete({ itemId, ssoId });
  }
}
