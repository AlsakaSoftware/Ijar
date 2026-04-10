import { z } from 'zod';

// User row from the database
export const DbUserSchema = z.object({
  id: z.string(),
  has_completed_onboarding: z.boolean(),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
});

export type DbUser = z.infer<typeof DbUserSchema>;
