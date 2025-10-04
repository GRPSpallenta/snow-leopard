import { Router } from 'express'
import { supabaseAdmin } from '../clients/supabase'
import { requireAuth, type AuthedRequest } from '../middleware/auth'
import { validateBody } from '../middleware/validate'
import { CreateProposalSchema } from '../schemas/proposals'

const router = Router()

// POST /api/proposals - pro submits a proposal to a job
router.post('/', requireAuth, validateBody(CreateProposalSchema), async (req: AuthedRequest, res) => {
  const userId = req.user!.id
  const { job_id, offer_price, eta, notes } = req.body

  const { data: profile, error: pErr } = await supabaseAdmin
    .from('profiles')
    .select('id, role')
    .eq('user_id', userId)
    .single()
  if (pErr) return res.status(400).json({ error: pErr.message })
  if (profile.role !== 'professional') return res.status(403).json({ error: 'Only pros can propose' })

  const insert = {
    job_id,
    pro_profile_id: profile.id,
    offer_price,
    eta,
    notes
  }
  const { data, error } = await supabaseAdmin.from('proposals').insert(insert).select('*').single()
  if (error) return res.status(400).json({ error: error.message })
  return res.status(201).json({ proposal: data })
})

// GET /api/proposals/mine - list proposals by the authenticated pro
router.get('/mine', requireAuth, async (req: AuthedRequest, res) => {
  const userId = req.user!.id
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('id')
    .eq('user_id', userId)
    .single()
  const { data, error } = await supabaseAdmin
    .from('proposals')
    .select('*')
    .eq('pro_profile_id', profile?.id)
    .order('created_at', { ascending: false })
  if (error) return res.status(500).json({ error: error.message })
  return res.json({ proposals: data })
})

export default router
