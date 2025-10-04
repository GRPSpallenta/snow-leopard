import { z } from 'zod'

export const CreateJobSchema = z.object({
  service_id: z.string().uuid(),
  description: z.string().min(1),
  budget: z.number().optional(),
  currency: z.string().default('USD'),
  desired_by: z.string().optional(), // ISO date
  location: z.object({ formatted: z.string(), lat: z.number(), lng: z.number() }),
  job_size: z.enum(['small', 'large']).optional(),
  service_type: z.enum(['fix', 'supply_fix'])
})

export type CreateJobInput = z.infer<typeof CreateJobSchema>
