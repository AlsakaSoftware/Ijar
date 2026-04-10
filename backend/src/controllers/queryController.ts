import { QueryService } from '../services/queryService';
import { CreateQueryRequest, UpdateQueryRequest } from '../schemas';

export class QueryController {
  constructor(private queryService: QueryService = new QueryService()) {}

  async getQueries(userId: string) {
    return this.queryService.getQueries(userId);
  }

  async createQuery(userId: string, data: CreateQueryRequest) {
    return this.queryService.createQuery(userId, data);
  }

  async updateQuery(userId: string, queryId: string, data: UpdateQueryRequest) {
    return this.queryService.updateQuery(userId, queryId, data);
  }

  async deleteQuery(userId: string, queryId: string) {
    return this.queryService.deleteQuery(userId, queryId);
  }
}
