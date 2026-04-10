import { z } from 'zod';

// =============================================================================
// Property Schemas
// =============================================================================

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

export const savePropertySchema = z.object({
  property: PropertySchema,
});

export const unsavePropertySchema = z.object({
  propertyId: z.string(),
});

export const trackActionSchema = z.object({
  action: z.enum(['saved', 'passed']),
});

// =============================================================================
// Group Schemas
// =============================================================================

export const createGroupSchema = z.object({
  name: z.string().min(1, 'Group name is required'),
});

export const renameGroupSchema = z.object({
  name: z.string().min(1, 'Group name is required'),
});

export const addPropertyToGroupSchema = z.object({
  propertyId: z.string(),
});

// =============================================================================
// Search Schemas
// =============================================================================

export const searchSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
  minPrice: z.number().optional(),
  maxPrice: z.number().optional(),
  minBedrooms: z.number().optional(),
  maxBedrooms: z.number().optional(),
  minBathrooms: z.number().optional(),
  maxBathrooms: z.number().optional(),
  radius: z.number().optional(),
  furnishType: z.string().optional(),
  page: z.number().optional(),
});

export const onboardingSearchSchema = searchSchema.extend({
  queryId: z.string(),
});

// =============================================================================
// Query Schemas
// =============================================================================

export const createQuerySchema = z.object({
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

export const updateQuerySchema = createQuerySchema.partial().omit({ id: true });

// =============================================================================
// Device Token Schemas
// =============================================================================

export const upsertTokenSchema = z.object({
  token: z.string().min(1, 'Token is required'),
  deviceType: z.enum(['ios']),
});

// =============================================================================
// Inferred Types
// =============================================================================

export type Property = z.infer<typeof PropertySchema>;
export type SavePropertyRequest = z.infer<typeof savePropertySchema>;
export type UnsavePropertyRequest = z.infer<typeof unsavePropertySchema>;
export type TrackActionRequest = z.infer<typeof trackActionSchema>;
export type CreateGroupRequest = z.infer<typeof createGroupSchema>;
export type RenameGroupRequest = z.infer<typeof renameGroupSchema>;
export type AddPropertyToGroupRequest = z.infer<typeof addPropertyToGroupSchema>;
export type SearchRequest = z.infer<typeof searchSchema>;
export type OnboardingSearchRequest = z.infer<typeof onboardingSearchSchema>;
export type CreateQueryRequest = z.infer<typeof createQuerySchema>;
export type UpdateQueryRequest = z.infer<typeof updateQuerySchema>;
export type UpsertTokenRequest = z.infer<typeof upsertTokenSchema>;
