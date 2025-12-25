import express from 'express';
import {
  getMeals,
  getMeal,
  createMeal,
  updateMeal,
  deleteMeal
} from '../controllers/meal.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

router.route('/')
  .get(optionalAuth, getMeals)
  .post(protect, createMeal);

router.route('/:id')
  .get(optionalAuth, getMeal)
  .put(protect, updateMeal)
  .delete(protect, deleteMeal);

export default router;


