import { z } from 'zod'

export const CreateProposalSchema = z.object({
  job_id: z.string().uuid(),
  offer_price: z.number().positive(),
  eta: z.string().optional(), // ISO datetime
  notes: z.string().optional()
})

export type CreateProposalInput = z.infer<typeof CreateProposalSchema>
