import express from 'express';
import {
  getWorkouts,
  getWorkout,
  createWorkout,
  updateWorkout,
  deleteWorkout
} from '../controllers/workout.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

router.route('/')
  .get(optionalAuth, getWorkouts)
  .post(protect, createWorkout);

router.route('/:id')
  .get(optionalAuth, getWorkout)
  .put(protect, updateWorkout)
  .delete(protect, deleteWorkout);

export default router;



