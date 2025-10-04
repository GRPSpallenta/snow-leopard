import { z } from 'zod'

export const WorkflowEventSchema = z.object({
  job_id: z.string().uuid(),
  type: z.enum(['start', 'pause', 'resume', 'finish', 'invoice', 'payment']),
  payload: z.record(z.any()).default({})
})

export type WorkflowEventInput = z.infer<typeof WorkflowEventSchema>
