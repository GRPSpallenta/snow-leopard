import { Router } from 'express'
import profiles from './profiles'
import jobs from './jobs'
import proposals from './proposals'
import workflow from './workflow'
import storage from './storage'

const router = Router()

router.use('/profiles', profiles)
router.use('/jobs', jobs)
router.use('/proposals', proposals)
router.use('/workflow', workflow)
router.use('/storage', storage)

export default router
