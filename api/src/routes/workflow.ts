import { Router } from 'express'
import { supabaseAdmin } from '../clients/supabase'
import { requireAuth, type AuthedRequest } from '../middleware/auth'
import { validateBody } from '../middleware/validate'
import { WorkflowEventSchema } from '../schemas/workflow'

const router = Router()

// POST /api/workflow/event - append a workflow event for a job (client/pro)
router.post('/event', requireAuth, validateBody(WorkflowEventSchema), async (req: AuthedRequest, res) => {
  const { job_id, type, payload } = req.body
  const { data, error } = await supabaseAdmin
    .from('workflow_events')
    .insert({ job_id, type, payload, actor_profile_id: null })
    .select('*')
    .single()
  if (error) return res.status(400).json({ error: error.message })
  return res.status(201).json({ event: data })
})

export default router
