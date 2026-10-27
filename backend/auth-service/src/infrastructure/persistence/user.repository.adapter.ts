import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRepositoryPort } from '../../domain/port/user.repository.port';
import { User } from '../../domain/model/user';
import { UserRecord } from './orm/user.persistence';
import { UserMapper } from './mapper/user.mapper';

/**
 * Outbound adapter (Hexagonal) implementing UserRepositoryPort over TypeORM.
 */
@Injectable()
export class UserRepositoryAdapter implements UserRepositoryPort {
  constructor(
    @InjectRepository(UserRecord)
    private readonly users: Repository<UserRecord>,
  ) {}

  async create(user: User): Promise<User> {
    const saved = await this.users.save(UserMapper.toRecord(user));
    return UserMapper.toDomain(saved);
  }

  async findByEmail(email: string): Promise<User | null> {
    const row = await this.users.findOne({
      where: { email: email.toLowerCase().trim() },
    });
    return row ? UserMapper.toDomain(row) : null;
  }

  async findBySsoId(ssoId: string): Promise<User | null> {
    const row = await this.users.findOne({ where: { ssoId } });
    return row ? UserMapper.toDomain(row) : null;
  }

  async findByVerifyToken(token: string): Promise<User | null> {
    const row = await this.users.findOne({ where: { verifyToken: token } });
    return row ? UserMapper.toDomain(row) : null;
  }

  async findByResetToken(token: string): Promise<User | null> {
    const row = await this.users.findOne({ where: { resetToken: token } });
    return row ? UserMapper.toDomain(row) : null;
  }

  async update(user: User): Promise<User> {
    const record = UserMapper.toRecord(user);
    if (record.id === undefined) {
      // domain keyed by ssoId; resolve the running PK for the UPDATE
      const existing = await this.users.findOne({
        where: { ssoId: user.ssoId },
        select: { id: true },
      });
      if (existing) record.id = existing.id;
    }
    const saved = await this.users.save(record);
    return UserMapper.toDomain(saved);
  }
}
