import { PropertyService } from '../services/propertyService';
import { SavePropertyRequest, UnsavePropertyRequest, TrackActionRequest, Property } from '../schemas';

export class PropertyController {
  constructor(private propertyService: PropertyService = new PropertyService()) {}

  async saveProperty(userId: string, data: SavePropertyRequest) {
    return this.propertyService.saveProperty(userId, data.property);
  }

  async unsaveProperty(userId: string, data: UnsavePropertyRequest) {
    return this.propertyService.unsaveProperty(userId, data.propertyId);
  }

  async getSavedProperties(userId: string): Promise<Property[]> {
    return this.propertyService.getSavedProperties(userId);
  }

  async getFeed(userId: string): Promise<Property[]> {
    return this.propertyService.getFeedProperties(userId);
  }

  async trackAction(userId: string, rightmoveId: string, data: TrackActionRequest) {
    return this.propertyService.trackAction(userId, rightmoveId, data.action);
  }
}
