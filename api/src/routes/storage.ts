import { Router } from 'express'
import { requireAuth, type AuthedRequest } from '../middleware/auth'
import { validateBody, validateQuery } from '../middleware/validate'
import { SignUploadSchema, SignDownloadQuerySchema } from '../schemas/storage'
import { supabaseAdmin } from '../clients/supabase'

const router = Router()

// POST /api/storage/sign-upload
// Returns a signed URL to upload to a specific bucket/path
router.post('/sign-upload', requireAuth, validateBody(SignUploadSchema), async (req: AuthedRequest, res) => {
  const { bucket = 'job-images', path } = req.body as { bucket: string; path: string }
  if (!path) return res.status(400).json({ error: 'Missing path' })

  const { data, error } = await supabaseAdmin.storage.from(bucket).createSignedUploadUrl(path)
  if (error) return res.status(400).json({ error: error.message })
  return res.json({ signedUrl: data?.signedUrl, token: data?.token, path })
})

// GET /api/storage/sign-download?bucket=...&path=...
router.get('/sign-download', requireAuth, validateQuery(SignDownloadQuerySchema), async (req, res) => {
  const bucket = (req.query.bucket as string) || 'job-images'
  const path = req.query.path as string
  if (!path) return res.status(400).json({ error: 'Missing path' })

  const { data, error } = await supabaseAdmin.storage.from(bucket).createSignedUrl(path, 60 * 10)
  if (error) return res.status(400).json({ error: error.message })
  return res.json({ url: data?.signedUrl })
})

export default router
