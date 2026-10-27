import { HttpException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance, Method } from 'axios';
import { DomainError, GatewayErrorCode } from '../shared/errors';

/**
 * Thin proxy that forwards HTTP requests to a downstream service and
 * relays status/body back. Encapsulates the forwarding logic so
 * controllers stay declarative.
 */
@Injectable()
export class ProxyService {
  private readonly catalog: AxiosInstance;
  private readonly analytics: AxiosInstance;
  private readonly auth: AxiosInstance;
  private readonly customer: AxiosInstance;

  constructor(config: ConfigService) {
    this.catalog = axios.create({
      baseURL: config.get<string>('CATALOG_SERVICE_URL', 'http://localhost:3001'),
      timeout: 8000,
      validateStatus: () => true,
    });
    this.analytics = axios.create({
      baseURL: config.get<string>('ANALYTICS_SERVICE_URL', 'http://localhost:3002'),
      timeout: 8000,
      validateStatus: () => true,
    });
    this.auth = axios.create({
      baseURL: config.get<string>('AUTH_SERVICE_URL', 'http://localhost:3003'),
      timeout: 8000,
      validateStatus: () => true,
    });
    this.customer = axios.create({
      baseURL: config.get<string>('CUSTOMER_SERVICE_URL', 'http://localhost:3004'),
      timeout: 8000,
      // avatars are base64 → allow large bodies
      maxBodyLength: 6 * 1024 * 1024,
      maxContentLength: 6 * 1024 * 1024,
      validateStatus: () => true,
    });
  }

  forwardToCustomer(
    method: Method,
    path: string,
    body?: unknown,
    query?: unknown,
    headers?: Record<string, string>,
  ) {
    return this.forward(this.customer, method, path, body, query, headers);
  }

  forwardToCatalog(
    method: Method,
    path: string,
    body?: unknown,
    query?: unknown,
    headers?: Record<string, string>,
  ) {
    return this.forward(this.catalog, method, path, body, query, headers);
  }

  forwardToAnalytics(
    method: Method,
    path: string,
    body?: unknown,
    query?: unknown,
    headers?: Record<string, string>,
  ) {
    return this.forward(this.analytics, method, path, body, query, headers);
  }

  forwardToAuth(
    method: Method,
    path: string,
    body?: unknown,
    query?: unknown,
    headers?: Record<string, string>,
  ) {
    return this.forward(this.auth, method, path, body, query, headers);
  }

  private async forward(
    client: AxiosInstance,
    method: Method,
    path: string,
    body?: unknown,
    query?: unknown,
    headers?: Record<string, string>,
  ) {
    try {
      const res = await client.request({
        method,
        url: path,
        data: body,
        params: query,
        headers,
      });
      if (res.status >= 400) {
        // relay the upstream error body (already { domain, code, message })
        // together with its status; the filter passes it through unchanged.
        throw new HttpException(res.data ?? { message: 'error' }, res.status);
      }
      return res.data;
    } catch (err: any) {
      if (err instanceof HttpException) throw err;
      // network failure / timeout reaching the upstream service
      throw new DomainError(GatewayErrorCode.UPSTREAM_UNAVAILABLE);
    }
  }
}
