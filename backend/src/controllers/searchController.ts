import { SearchService } from '../services/searchService';
import { SearchRequest, OnboardingSearchRequest } from '../schemas';

export class SearchController {
  constructor(private searchService: SearchService = new SearchService()) {}

  async search(data: SearchRequest) {
    return this.searchService.searchProperties(data);
  }

  async onboardingSearch(data: OnboardingSearchRequest) {
    return this.searchService.onboardingSearch(data);
  }

  async getPropertyDetails(propertyId: string) {
    return this.searchService.getPropertyDetails(propertyId);
  }
}
