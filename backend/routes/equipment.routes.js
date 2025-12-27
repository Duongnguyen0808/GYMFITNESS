import express from 'express';
import {
  getEquipment,
  getSingleEquipment,
  createEquipment,
  updateEquipment,
  deleteEquipment
} from '../controllers/equipment.controller.js';
import { protect, optionalAuth } from '../middleware/auth.middleware.js';

const router = express.Router();

router.route('/')
  .get(optionalAuth, getEquipment)
  .post(protect, createEquipment);

router.route('/:id')
  .get(optionalAuth, getSingleEquipment)
  .put(protect, updateEquipment)
  .delete(protect, deleteEquipment);

export default router;


