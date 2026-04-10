import { PropertyRepository } from '../repositories/propertyRepository';
import { UserPropertyActionRepository } from '../repositories/userPropertyActionRepository';
import { Property } from '../schemas/propertySchemas';
import { badRequest, notFound, ErrorCodes } from '../utils/errors';

export class PropertyService {
  constructor(
    private propertyRepo: PropertyRepository,
    private actionRepo: UserPropertyActionRepository
  ) {}

  async saveProperty(userId: string, property: Property): Promise<{ success: boolean; property_id?: string }> {
    const rightmoveId = parseInt(property.id, 10);
    if (isNaN(rightmoveId)) {
      throw badRequest(ErrorCodes.INVALID_PROPERTY_ID, 'Property ID must be numeric');
    }

    const { id: propertyUUID } = await this.propertyRepo.upsert({
      rightmove_id: rightmoveId,
      images: property.images,
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      address: property.address,
      area: property.area || undefined,
      rightmove_url: property.rightmove_url || `https://www.rightmove.co.uk/properties/${rightmoveId}`,
      agent_phone: property.agent_phone || undefined,
      agent_name: property.agent_name || undefined,
      branch_name: property.branch_name || undefined,
      latitude: property.latitude || undefined,
      longitude: property.longitude || undefined,
    });

    const existingAction = await this.actionRepo.findAction(userId, propertyUUID);

    if (existingAction) {
      if (existingAction.action === 'saved') {
        return { success: true, property_id: propertyUUID };
      }
      await this.actionRepo.updateAction(userId, propertyUUID, 'saved');
      return { success: true, property_id: propertyUUID };
    }

    await this.actionRepo.insertAction(userId, propertyUUID, 'saved');
    return { success: true, property_id: propertyUUID };
  }

  async unsaveProperty(userId: string, rightmoveId: string): Promise<{ success: boolean }> {
    const id = parseInt(rightmoveId, 10);
    if (isNaN(id)) {
      throw badRequest(ErrorCodes.INVALID_PROPERTY_ID, 'Property ID must be numeric');
    }

    const property = await this.propertyRepo.findByRightmoveId(id);
    if (!property) {
      throw notFound(ErrorCodes.PROPERTY_NOT_FOUND, 'Property not found');
    }

    await this.actionRepo.updateAction(userId, property.id, 'passed');
    return { success: true };
  }

  async getSavedProperties(userId: string): Promise<Property[]> {
    // Try optimized view first
    const viewData = await this.actionRepo.getSavedPropertiesFromView(userId);
    if (viewData) {
      return viewData.map(row => this.mapRowToProperty(row));
    }

    // Fallback to manual join
    const propertyIds = await this.actionRepo.getSavedPropertyIds(userId);
    if (propertyIds.length === 0) return [];

    const properties = await this.propertyRepo.findByIds(propertyIds);
    const propertyMap = new Map(properties.map(p => [p.id, p]));

    const result: Property[] = [];
    for (const pid of propertyIds) {
      const prop = propertyMap.get(pid);
      if (prop) result.push(this.mapRowToProperty(prop));
    }
    return result;
  }

  async getFeedProperties(userId: string): Promise<Property[]> {
    const rows = await this.propertyRepo.getFeedForUser(userId);
    return rows.map(row => this.mapRowToProperty(row));
  }

  async trackAction(userId: string, rightmoveId: string, action: string): Promise<{ success: boolean }> {
    const id = parseInt(rightmoveId, 10);
    if (isNaN(id)) {
      throw badRequest(ErrorCodes.INVALID_PROPERTY_ID, 'Property ID must be numeric');
    }

    const property = await this.propertyRepo.findByRightmoveId(id);
    if (!property) {
      throw notFound(ErrorCodes.PROPERTY_NOT_FOUND, 'Property not found');
    }

    await this.actionRepo.insertAction(userId, property.id, action);
    return { success: true };
  }

  private mapRowToProperty(row: any): Property {
    return {
      id: String(row.rightmove_id),
      images: row.images || [],
      price: row.price,
      bedrooms: row.bedrooms,
      bathrooms: row.bathrooms,
      address: row.address,
      area: row.area || null,
      rightmove_url: row.rightmove_url || null,
      agent_phone: row.agent_phone || null,
      agent_name: row.agent_name || null,
      branch_name: row.branch_name || null,
      latitude: row.latitude || null,
      longitude: row.longitude || null,
    };
  }
}
