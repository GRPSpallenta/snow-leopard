import type { Request, Response, NextFunction } from 'express'
import { ZodSchema, ZodError } from 'zod'

export function validateBody<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      req.body = schema.parse(req.body) as any
      next()
    } catch (e) {
      const err = e as ZodError
      res.status(400).json({ error: 'Validation failed', details: err.flatten() })
    }
  }
}

export function validateQuery<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      req.query = schema.parse(req.query) as any
      next()
    } catch (e) {
      const err = e as ZodError
      res.status(400).json({ error: 'Validation failed', details: err.flatten() })
    }
  }
}
