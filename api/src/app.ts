import dotenv from 'dotenv'
import path from 'path'
// Load env from the repository root .env (one .env for the whole project)
// __dirname is api/src -> go up two levels to reach repo root
dotenv.config({ path: path.resolve(__dirname, '../../.env') })

import express from 'express'
import helmet from 'helmet'
import cors from 'cors'
import pinoHttp from 'pino-http'

import { supabaseAdmin } from './clients/supabase'
import routes from './routes'

const app = express()
app.use(helmet())
app.use(cors())
app.use(pinoHttp())
app.use(express.json({ limit: '5mb' }))

// Silence favicon.ico 404s during API-only development
app.get('/favicon.ico', (_req, res) => res.status(204).end())

// Health check
app.get('/health', async (_req, res) => {
  const { data, error } = await supabaseAdmin.from('services').select('id').limit(1)
  if (error) return res.status(500).json({ ok: false, error: error.message })
  return res.json({ ok: true, db: !!data })
})

// Basic auth check route
app.get('/auth/me', async (req, res) => {
  try {
    const authHeader = req.headers.authorization || ''
    const token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : ''
    if (!token) return res.status(401).json({ error: 'Missing bearer token' })

    const { data, error } = await supabaseAdmin.auth.getUser(token)
    if (error || !data?.user) return res.status(401).json({ error: 'Invalid token' })

    return res.json({ user: { id: data.user.id, email: data.user.email } })
  } catch (e: any) {
    return res.status(500).json({ error: e.message })
  }
})

// Mount API routes
app.use('/api', routes)

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' })
})

// Error handler
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  // eslint-disable-next-line no-console
  console.error(err)
  res.status(500).json({ error: 'Internal Server Error' })
})

export default app
