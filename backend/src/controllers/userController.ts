import { UserService } from '../services/userService';

export class UserController {
  constructor(private userService: UserService = new UserService()) {}

  async getUser(userId: string) {
    return this.userService.getUser(userId);
  }

  async upsertUser(userId: string) {
    return this.userService.upsertUser(userId);
  }

  async markOnboardingComplete(userId: string) {
    return this.userService.markOnboardingComplete(userId);
  }
}
