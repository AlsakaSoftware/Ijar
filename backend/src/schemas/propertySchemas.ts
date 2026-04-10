import { z } from 'zod';

// Property as sent from iOS (snake_case)
export const PropertySchema = z.object({
  id: z.string(),
  images: z.array(z.string()),
  price: z.string(),
  bedrooms: z.number(),
  bathrooms: z.number(),
  address: z.string(),
  area: z.string().nullable().optional(),
  rightmove_url: z.string().nullable().optional(),
  agent_phone: z.string().nullable().optional(),
  agent_name: z.string().nullable().optional(),
  branch_name: z.string().nullable().optional(),
  latitude: z.number().nullable().optional(),
  longitude: z.number().nullable().optional(),
});

export const SavePropertyBodySchema = z.object({
  property: PropertySchema,
});

export const UnsavePropertyBodySchema = z.object({
  propertyId: z.string(),
});

export const TrackActionBodySchema = z.object({
  action: z.enum(['saved', 'passed']),
});

export type Property = z.infer<typeof PropertySchema>;
export type SavePropertyBody = z.infer<typeof SavePropertyBodySchema>;
export type UnsavePropertyBody = z.infer<typeof UnsavePropertyBodySchema>;
export type TrackActionBody = z.infer<typeof TrackActionBodySchema>;
