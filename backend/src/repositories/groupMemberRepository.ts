import { SupabaseClient } from '@supabase/supabase-js';
import { databaseError } from '../utils/errors';

export class GroupMemberRepository {
  constructor(private client: SupabaseClient) {}

  async getPropertyIds(groupId: string): Promise<string[]> {
    const { data, error } = await this.client
      .from('property_group_member')
      .select('property_id')
      .eq('group_id', groupId);

    if (error) throw databaseError(error.message);
    return (data || []).map(m => m.property_id);
  }

  async getMemberCounts(groupIds: string[]): Promise<Record<string, number>> {
    if (groupIds.length === 0) return {};

    const { data } = await this.client
      .from('property_group_member')
      .select('group_id')
      .in('group_id', groupIds);

    const counts: Record<string, number> = {};
    for (const member of data || []) {
      counts[member.group_id] = (counts[member.group_id] || 0) + 1;
    }
    return counts;
  }

  async addMember(groupId: string, propertyId: string): Promise<void> {
    const { error } = await this.client
      .from('property_group_member')
      .upsert(
        { group_id: groupId, property_id: propertyId },
        { onConflict: 'group_id,property_id', ignoreDuplicates: true }
      );

    if (error) throw databaseError(error.message);
  }

  async removeMember(groupId: string, propertyId: string): Promise<void> {
    const { error } = await this.client
      .from('property_group_member')
      .delete()
      .eq('group_id', groupId)
      .eq('property_id', propertyId);

    if (error) throw databaseError(error.message);
  }

  async removeAllForGroup(groupId: string): Promise<void> {
    await this.client
      .from('property_group_member')
      .delete()
      .eq('group_id', groupId);
  }

  async getGroupIdsForProperty(propertyId: string, userId: string): Promise<string[]> {
    const { data, error } = await this.client
      .from('property_group_member')
      .select('group_id, property_group!inner(user_id)')
      .eq('property_id', propertyId)
      .eq('property_group.user_id', userId);

    if (error) return [];
    return (data || []).map(m => m.group_id);
  }
}
