import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CustomerRepositoryPort } from '../../domain/port/customer.repository.port';
import { CustomerProfile } from '../../domain/model/customer-profile';
import { CustomerRecord } from './orm/customer.persistence';
import { CustomerMapper } from './mapper/customer.mapper';

/**
 * Outbound adapter (Hexagonal) implementing CustomerRepositoryPort over TypeORM.
 */
@Injectable()
export class CustomerRepositoryAdapter implements CustomerRepositoryPort {
  constructor(
    @InjectRepository(CustomerRecord)
    private readonly customers: Repository<CustomerRecord>,
  ) {}

  async findBySsoId(ssoId: string): Promise<CustomerProfile | null> {
    const row = await this.customers.findOne({ where: { ssoId } });
    return row ? CustomerMapper.toDomain(row) : null;
  }

  async findByUsername(username: string): Promise<CustomerProfile | null> {
    const row = await this.customers.findOne({ where: { username } });
    return row ? CustomerMapper.toDomain(row) : null;
  }

  async save(profile: CustomerProfile): Promise<CustomerProfile> {
    const record = CustomerMapper.toRecord(profile);
    // preserve the running PK on update (domain is keyed by ssoId, not id)
    const existing = await this.customers.findOne({
      where: { ssoId: profile.ssoId },
      select: { id: true },
    });
    if (existing) {
      record.id = existing.id;
    }
    const saved = await this.customers.save(record);
    return CustomerMapper.toDomain(saved);
  }
}
