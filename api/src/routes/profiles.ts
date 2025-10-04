import { Router } from 'express'
import { supabaseAdmin } from '../clients/supabase'
import { requireAuth, type AuthedRequest } from '../middleware/auth'

const router = Router()

// GET /api/profiles/me
router.get('/me', requireAuth, async (req: AuthedRequest, res) => {
  const userId = req.user!.id
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('*')
    .eq('user_id', userId)
    .single()
  if (error) return res.status(500).json({ error: error.message })
  return res.json({ profile: data })
})

// PATCH /api/profiles/me
router.patch('/me', requireAuth, async (req: AuthedRequest, res) => {
  const userId = req.user!.id
  const allowed = ['first_name', 'last_name', 'phone', 'locale', 'home_address', 'work_address']
  const payload: Record<string, unknown> = {}
  for (const key of allowed) if (key in req.body) payload[key] = req.body[key]
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .update(payload)
    .eq('user_id', userId)
    .select('*')
    .single()
  if (error) return res.status(400).json({ error: error.message })
  return res.json({ profile: data })
})

export default router
