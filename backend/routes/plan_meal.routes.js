import express from 'express';
import {
  getPlanMealCollections,
  getPlanMealCollection,
  createPlanMealCollection,
  updatePlanMealCollection,
  deletePlanMealCollection,
  deletePlanMealCollectionsByPlanID,
  getPlanMeals
} from '../controllers/plan_meal.controller.js';
import { generateSmartMealPlan } from '../controllers/plan_meal.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

// Plan Meal Collections
router.route('/collections')
  .get(optionalAuth, getPlanMealCollections)
  .post(protect, createPlanMealCollection)
  .delete(protect, deletePlanMealCollectionsByPlanID); // Batch delete by planID

router.route('/collections/:id')
  .get(optionalAuth, getPlanMealCollection)
  .put(protect, updatePlanMealCollection)
  .delete(protect, deletePlanMealCollection);

// Plan Meals
router.route('/')
  .get(optionalAuth, getPlanMeals);

// Dev: generate smart meal plan (creates many days). Protected for admin.
router.route('/generate').post(generateSmartMealPlan);

export default router;

