import { QueryRepository } from '../repositories/queryRepository';
import { DbQuery } from '../types/database';
import { CreateQueryBody, UpdateQueryBody } from '../schemas/querySchemas';

export class QueryService {
  constructor(private queryRepo: QueryRepository) {}

  async getQueries(userId: string): Promise<DbQuery[]> {
    return this.queryRepo.findByUserId(userId);
  }

  async createQuery(userId: string, data: CreateQueryBody): Promise<DbQuery> {
    return this.queryRepo.insert(userId, data);
  }

  async updateQuery(userId: string, queryId: string, data: UpdateQueryBody): Promise<{ success: boolean }> {
    await this.queryRepo.update(queryId, userId, data);
    return { success: true };
  }

  async deleteQuery(userId: string, queryId: string): Promise<{ success: boolean }> {
    await this.queryRepo.delete(queryId, userId);
    return { success: true };
  }
}
