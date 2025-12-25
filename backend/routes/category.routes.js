import express from 'express';
import {
  getCategories,
  getCategory,
  createCategory,
  updateCategory,
  deleteCategory
} from '../controllers/category.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

router.route('/')
  .get(optionalAuth, getCategories)
  .post(protect, createCategory);

router.route('/:id')
  .get(optionalAuth, getCategory)
  .put(protect, updateCategory)
  .delete(protect, deleteCategory);

export default router;


