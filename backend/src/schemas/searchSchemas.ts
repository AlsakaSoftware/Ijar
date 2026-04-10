import { z } from 'zod';

export const SearchBodySchema = z.object({
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

export const OnboardingSearchBodySchema = SearchBodySchema.extend({
  queryId: z.string(),
});

export type SearchBody = z.infer<typeof SearchBodySchema>;
export type OnboardingSearchBody = z.infer<typeof OnboardingSearchBodySchema>;
