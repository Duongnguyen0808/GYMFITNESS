import express from 'express';
import {
  getIngredients,
  getIngredient,
  createIngredient,
  updateIngredient,
  deleteIngredient
} from '../controllers/ingredient.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

router.route('/')
  .get(optionalAuth, getIngredients)
  .post(protect, createIngredient);

router.route('/:id')
  .get(optionalAuth, getIngredient)
  .put(protect, updateIngredient)
  .delete(protect, deleteIngredient);

export default router;


