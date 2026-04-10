import { z } from 'zod';

export const CreateGroupBodySchema = z.object({
  name: z.string().min(1, 'Group name is required'),
});

export const RenameGroupBodySchema = z.object({
  name: z.string().min(1, 'Group name is required'),
});

export const AddPropertyToGroupBodySchema = z.object({
  propertyId: z.string(),
});

export type CreateGroupBody = z.infer<typeof CreateGroupBodySchema>;
export type RenameGroupBody = z.infer<typeof RenameGroupBodySchema>;
export type AddPropertyToGroupBody = z.infer<typeof AddPropertyToGroupBodySchema>;
