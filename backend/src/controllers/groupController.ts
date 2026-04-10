import { GroupService } from '../services/groupService';
import { CreateGroupRequest, RenameGroupRequest, AddPropertyToGroupRequest } from '../schemas';

export class GroupController {
  constructor(private groupService: GroupService = new GroupService()) {}

  async getGroups(userId: string) {
    return this.groupService.getGroups(userId);
  }

  async createGroup(userId: string, data: CreateGroupRequest) {
    return this.groupService.createGroup(userId, data.name);
  }

  async deleteGroup(groupId: string) {
    return this.groupService.deleteGroup(groupId);
  }

  async renameGroup(groupId: string, data: RenameGroupRequest) {
    return this.groupService.renameGroup(groupId, data.name);
  }

  async getGroupProperties(groupId: string) {
    return this.groupService.getGroupProperties(groupId);
  }

  async addPropertyToGroup(groupId: string, data: AddPropertyToGroupRequest) {
    return this.groupService.addPropertyToGroup(groupId, data.propertyId);
  }

  async removePropertyFromGroup(groupId: string, propertyId: string) {
    return this.groupService.removePropertyFromGroup(groupId, propertyId);
  }

  async getGroupsForProperty(userId: string, rightmoveId: string) {
    return this.groupService.getGroupsForProperty(userId, rightmoveId);
  }
}
