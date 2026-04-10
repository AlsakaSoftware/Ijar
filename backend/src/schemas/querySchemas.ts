import { z } from 'zod';

export const CreateQueryBodySchema = z.object({
  id: z.string().optional(),
  name: z.string(),
  area_name: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  min_price: z.number().optional(),
  max_price: z.number().optional(),
  min_bedrooms: z.number().optional(),
  max_bedrooms: z.number().optional(),
  min_bathrooms: z.number().optional(),
  max_bathrooms: z.number().optional(),
  radius: z.number().optional(),
  furnish_type: z.string().optional(),
  active: z.boolean().optional(),
});

export const UpdateQueryBodySchema = CreateQueryBodySchema.partial().omit({ id: true });

export type CreateQueryBody = z.infer<typeof CreateQueryBodySchema>;
export type UpdateQueryBody = z.infer<typeof UpdateQueryBodySchema>;
