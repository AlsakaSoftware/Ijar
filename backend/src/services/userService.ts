import { UserRepository } from '../repositories/userRepository';
import { DbUser } from '../schemas/userSchemas';
import { notFound, ErrorCodes } from '../utils/errors';

export class UserService {
  constructor(private userRepo: UserRepository) {}

  async getUser(userId: string): Promise<DbUser> {
    const user = await this.userRepo.findById(userId);
    if (!user) {
      throw notFound(ErrorCodes.PROPERTY_NOT_FOUND, 'User not found');
    }
    return user;
  }

  async upsertUser(userId: string): Promise<DbUser> {
    return this.userRepo.upsert(userId);
  }

  async markOnboardingComplete(userId: string): Promise<{ success: boolean }> {
    await this.userRepo.markOnboardingComplete(userId);
    return { success: true };
  }
}
