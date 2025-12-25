import express from 'express';
import {
  getPlanExerciseCollections,
  getPlanExerciseCollection,
  createPlanExerciseCollection,
  updatePlanExerciseCollection,
  deletePlanExerciseCollection,
  deletePlanExerciseCollectionsByPlanID,
  getPlanExercises,
  getPlanExerciseCollectionSetting
} from '../controllers/plan_exercise.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

// Plan Exercise Collections
router.route('/collections')
  .get(optionalAuth, getPlanExerciseCollections)
  .post(protect, createPlanExerciseCollection)
  .delete(protect, deletePlanExerciseCollectionsByPlanID); // Batch delete by planID

router.route('/collections/:id')
  .get(optionalAuth, getPlanExerciseCollection)
  .put(protect, updatePlanExerciseCollection)
  .delete(protect, deletePlanExerciseCollection);

// Plan Exercises
router.route('/')
  .get(optionalAuth, getPlanExercises);

// Plan Exercise Collection Settings
router.route('/settings/:id')
  .get(optionalAuth, getPlanExerciseCollectionSetting);

export default router;

