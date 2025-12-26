import express from 'express';
import { protect } from '../middleware/auth.middleware.js';
import {
  generatePlan,
  createPlan,
  getPlanPreview
} from '../controllers/recommendation.controller.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

router.post('/generate-plan', generatePlan);
router.post('/create-plan', createPlan);
router.get('/preview', getPlanPreview);

export default router;

