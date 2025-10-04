import request from 'supertest'
import app from '../src/app'
import { describe, it, expect } from 'vitest'

describe('Health endpoint', () => {
  it('GET /health returns ok true', async () => {
    const res = await request(app).get('/health')
    expect(res.status).toBe(200)
    expect(res.body).toHaveProperty('ok', true)
  })
})
