import { GroupRepository } from '../repositories/groupRepository';
import { GroupMemberRepository } from '../repositories/groupMemberRepository';
import { PropertyRepository } from '../repositories/propertyRepository';
import { Property } from '../schemas';
import { badRequest, ErrorCodes } from '../utils/errors';

export interface PropertyGroup {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
  property_count: number;
}

export class GroupService {
  constructor(
    private groupRepo: GroupRepository = new GroupRepository(),
    private memberRepo: GroupMemberRepository = new GroupMemberRepository(),
    private propertyRepo: PropertyRepository = new PropertyRepository()
  ) {}

  async getGroups(userId: string): Promise<PropertyGroup[]> {
    const groups = await this.groupRepo.findByUserId(userId);
    const groupIds = groups.map(g => g.id);
    const counts = await this.memberRepo.getMemberCounts(groupIds);

    return groups.map(g => ({
      id: g.id,
      user_id: g.user_id,
      name: g.name,
      created_at: g.created_at,
      property_count: counts[g.id] || 0,
    }));
  }

  async createGroup(userId: string, name: string): Promise<PropertyGroup> {
    const group = await this.groupRepo.create(userId, name);
    return {
      id: group.id,
      user_id: group.user_id,
      name: group.name,
      created_at: group.created_at,
      property_count: 0,
    };
  }

  async deleteGroup(groupId: string): Promise<{ success: boolean }> {
    await this.memberRepo.removeAllForGroup(groupId);
    await this.groupRepo.delete(groupId);
    return { success: true };
  }

  async renameGroup(groupId: string, name: string): Promise<{ success: boolean }> {
    await this.groupRepo.rename(groupId, name);
    return { success: true };
  }

  async getGroupProperties(groupId: string): Promise<Property[]> {
    const propertyIds = await this.memberRepo.getPropertyIds(groupId);
    if (propertyIds.length === 0) return [];

    const properties = await this.propertyRepo.findByIds(propertyIds);
    return properties.map(prop => ({
      id: String(prop.rightmove_id),
      images: prop.images || [],
      price: prop.price,
      bedrooms: prop.bedrooms,
      bathrooms: prop.bathrooms,
      address: prop.address,
      area: prop.area || null,
      rightmove_url: prop.rightmove_url || null,
      agent_phone: prop.agent_phone || null,
      agent_name: prop.agent_name || null,
      branch_name: prop.branch_name || null,
      latitude: prop.latitude || null,
      longitude: prop.longitude || null,
    }));
  }

  async addPropertyToGroup(groupId: string, rightmoveId: string): Promise<{ success: boolean }> {
    const id = parseInt(rightmoveId, 10);
    if (isNaN(id)) {
      throw badRequest(ErrorCodes.INVALID_PROPERTY_ID, 'Invalid property ID');
    }

    const property = await this.propertyRepo.findByRightmoveId(id);
    if (!property) {
      throw badRequest(ErrorCodes.PROPERTY_NOT_FOUND, 'Property not found');
    }

    await this.memberRepo.addMember(groupId, property.id);
    return { success: true };
  }

  async removePropertyFromGroup(groupId: string, rightmoveId: string): Promise<{ success: boolean }> {
    const id = parseInt(rightmoveId, 10);
    if (isNaN(id)) return { success: true };

    const property = await this.propertyRepo.findByRightmoveId(id);
    if (!property) return { success: true };

    await this.memberRepo.removeMember(groupId, property.id);
    return { success: true };
  }

  async getGroupsForProperty(userId: string, rightmoveId: string): Promise<string[]> {
    const id = parseInt(rightmoveId, 10);
    if (isNaN(id)) return [];

    const property = await this.propertyRepo.findByRightmoveId(id);
    if (!property) return [];

    return this.memberRepo.getGroupIdsForProperty(property.id, userId);
  }
}
