import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ItemUseCases } from '../../application/use-case/item.use-cases';
import {
  CreateItemRequest,
  UpdateItemRequest,
} from './request/catalog.requests';
import { CatalogPresenter } from './catalog.presenter';
import { DomainError, CatalogErrorCode } from '../../shared/errors';
import { SSO_ID_HEADER } from '../../shared/constants';
import { Category, isCategory } from '../../shared/categories';

function requireSsoId(ssoId?: string): string {
  if (!ssoId) throw new DomainError(CatalogErrorCode.MISSING_SSO_ID);
  return ssoId;
}

/**
 * Inbound HTTP controller for household items, under the 'catalog' prefix.
 *   POST   /catalog/items
 *   GET    /catalog/items?category=
 *   GET    /catalog/items/:itemId
 *   PATCH  /catalog/items/:itemId
 *   DELETE /catalog/items/:itemId
 */
@Controller('items')
export class ItemController {
  constructor(private readonly items: ItemUseCases) {}

  @Post()
  async create(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Body() body: CreateItemRequest,
  ) {
    const item = await this.items.create({
      ssoId: requireSsoId(ssoId),
      ...body,
      category: body.category as Category,
    });
    return CatalogPresenter.item(item);
  }

  @Get()
  async list(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('category') category?: string,
  ) {
    const cat = isCategory(category) ? category : undefined;
    const list = await this.items.list(requireSsoId(ssoId), cat);
    return list.map((i) => CatalogPresenter.item(i));
  }

  @Get(':itemId')
  async getOne(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('itemId') itemId: string,
  ) {
    const item = await this.items.getById(itemId, requireSsoId(ssoId));
    return CatalogPresenter.item(item);
  }

  @Patch(':itemId')
  async update(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('itemId') itemId: string,
    @Body() body: UpdateItemRequest,
  ) {
    const item = await this.items.update(itemId, requireSsoId(ssoId), {
      ...body,
      category: body.category as Category | undefined,
    });
    return CatalogPresenter.item(item);
  }

  @Delete(':itemId')
  @HttpCode(204)
  async remove(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('itemId') itemId: string,
  ) {
    await this.items.delete(itemId, requireSsoId(ssoId));
  }
}
