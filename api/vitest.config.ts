import { defineConfig } from 'vitest/config'
import path from 'path'
import dotenv from 'dotenv'

// Ensure tests load env from the repo root .env
// __dirname here is the api/ directory
dotenv.config({ path: path.resolve(__dirname, '../.env') })

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.{test,spec}.ts']
  }
})
