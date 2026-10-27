import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PendingRegistrationRepositoryPort } from '../../domain/port/pending-registration.repository.port';
import { PendingRegistration } from '../../domain/model/pending-registration';
import { PendingRegistrationRecord } from './orm/pending-registration.persistence';
import { PendingRegistrationMapper } from './mapper/pending-registration.mapper';

/** TypeORM adapter implementing PendingRegistrationRepositoryPort. */
@Injectable()
export class PendingRegistrationRepositoryAdapter
  implements PendingRegistrationRepositoryPort
{
  constructor(
    @InjectRepository(PendingRegistrationRecord)
    private readonly repo: Repository<PendingRegistrationRecord>,
  ) {}

  /** Insert or replace the pending row for this email (re-register overwrites). */
  async upsertByEmail(
    pending: PendingRegistration,
  ): Promise<PendingRegistration> {
    const existing = await this.repo.findOne({
      where: { email: pending.email },
      select: { id: true },
    });
    const record = PendingRegistrationMapper.toRecord(pending);
    if (existing) record.id = existing.id;
    const saved = await this.repo.save(record);
    return PendingRegistrationMapper.toDomain(saved);
  }

  async findByEmail(email: string): Promise<PendingRegistration | null> {
    const row = await this.repo.findOne({
      where: { email: email.toLowerCase().trim() },
    });
    return row ? PendingRegistrationMapper.toDomain(row) : null;
  }

  async update(pending: PendingRegistration): Promise<PendingRegistration> {
    const record = PendingRegistrationMapper.toRecord(pending);
    if (record.id === undefined) {
      const existing = await this.repo.findOne({
        where: { email: pending.email },
        select: { id: true },
      });
      if (existing) record.id = existing.id;
    }
    const saved = await this.repo.save(record);
    return PendingRegistrationMapper.toDomain(saved);
  }

  async deleteByEmail(email: string): Promise<void> {
    await this.repo.delete({ email: email.toLowerCase().trim() });
  }
}
