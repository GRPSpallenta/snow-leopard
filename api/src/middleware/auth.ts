import type { Request, Response, NextFunction } from 'express'

export interface AuthUser {
  id: string
  email?: string
}

export interface AuthedRequest extends Request {
  user?: AuthUser
  token?: string
}

// Extracts Bearer token and attaches user (if valid) using Supabase Admin
import { supabaseAdmin } from '../clients/supabase'

export async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization || ''
  const token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : ''
  if (!token) return res.status(401).json({ error: 'Missing bearer token' })

  const { data, error } = await supabaseAdmin.auth.getUser(token)
  if (error || !data?.user) return res.status(401).json({ error: 'Invalid token' })

  req.user = { id: data.user.id, email: data.user.email ?? undefined }
  req.token = token
  next()
}
