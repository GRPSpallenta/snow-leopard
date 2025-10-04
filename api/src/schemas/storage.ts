import { z } from 'zod'

export const SignUploadSchema = z.object({
  bucket: z.string().default('job-images'),
  path: z.string().min(1)
})

export const SignDownloadQuerySchema = z.object({
  bucket: z.string().default('job-images'),
  path: z.string().min(1)
})

export type SignUploadInput = z.infer<typeof SignUploadSchema>
export type SignDownloadQuery = z.infer<typeof SignDownloadQuerySchema>
