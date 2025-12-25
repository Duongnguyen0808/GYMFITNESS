import express from 'express';
import {
  getLibrarySections,
  getLibrarySection,
  createLibrarySection,
  updateLibrarySection,
  deleteLibrarySection
} from '../controllers/library_section.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

router.route('/')
  .get(optionalAuth, getLibrarySections)
  .post(protect, createLibrarySection);

router.route('/:id')
  .get(optionalAuth, getLibrarySection)
  .put(protect, updateLibrarySection)
  .delete(protect, deleteLibrarySection);

export default router;

