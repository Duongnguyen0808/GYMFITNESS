import express from 'express';
import {
  getWorkoutCollections,
  getWorkoutCollection,
  createWorkoutCollection,
  updateWorkoutCollection,
  deleteWorkoutCollection,
  getMealCollections,
  getMealCollection,
  createMealCollection,
  updateMealCollection,
  deleteMealCollection
} from '../controllers/collection.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

// Workout Collections
router.route('/workouts')
  .get(optionalAuth, getWorkoutCollections)
  .post(protect, createWorkoutCollection);

router.route('/workouts/:id')
  .get(optionalAuth, getWorkoutCollection)
  .put(protect, updateWorkoutCollection)
  .delete(protect, deleteWorkoutCollection);

// Meal Collections
router.route('/meals')
  .get(optionalAuth, getMealCollections)
  .post(protect, createMealCollection);

router.route('/meals/:id')
  .get(optionalAuth, getMealCollection)
  .put(protect, updateMealCollection)
  .delete(protect, deleteMealCollection);

export default router;



