import { z } from 'zod';

export const UpsertTokenBodySchema = z.object({
  token: z.string().min(1, 'Token is required'),
  deviceType: z.enum(['ios']),
});

export type UpsertTokenBody = z.infer<typeof UpsertTokenBodySchema>;
