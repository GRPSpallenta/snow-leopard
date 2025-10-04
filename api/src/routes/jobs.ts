import { Router } from 'express'
import { supabaseAdmin } from '../clients/supabase'
import { requireAuth, type AuthedRequest } from '../middleware/auth'
import { validateBody } from '../middleware/validate'
import { CreateJobSchema } from '../schemas/jobs'

const router = Router()

// POST /api/jobs - create a job (client)
router.post('/', requireAuth, validateBody(CreateJobSchema), async (req: AuthedRequest, res) => {
  const userId = req.user!.id
  const { service_id, description, budget, currency, desired_by, location, job_size, service_type } = req.body
  const { data: profile, error: pErr } = await supabaseAdmin
    .from('profiles')
    .select('id, role')
    .eq('user_id', userId)
    .single()
  if (pErr) return res.status(400).json({ error: pErr.message })
  if (profile.role !== 'client') return res.status(403).json({ error: 'Only clients can create jobs' })

  const insert = {
    client_profile_id: profile.id,
    service_id,
    description,
    budget,
    currency,
    desired_by,
    location,
    job_size,
    service_type
  }
  const { data, error } = await supabaseAdmin.from('jobs').insert(insert).select('*').single()
  if (error) return res.status(400).json({ error: error.message })
  return res.status(201).json({ job: data })
})

// GET /api/jobs/open - list open jobs (pros)
router.get('/open', requireAuth, async (_req, res) => {
  const { data, error } = await supabaseAdmin
    .from('jobs')
    .select('*')
    .eq('status', 'open')
    .order('created_at', { ascending: false })
  if (error) return res.status(500).json({ error: error.message })
  return res.json({ jobs: data })
})

export default router
