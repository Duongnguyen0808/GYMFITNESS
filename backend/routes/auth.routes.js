import express from "express";
import {
  register,
  login,
  getMe,
  adminLogin,
  createAdmin,
  verifyEmail,
  resendOTP,
} from "../controllers/auth.controller.js";
import { protect, requireAdmin } from "../middleware/auth.middleware.js";

const router = express.Router();

// Public routes
router.post("/register", register);
router.post("/login", login);
router.post("/verify-email", verifyEmail);
router.post("/resend-otp", resendOTP);

// Protected routes
router.get("/me", protect, getMe);

// Admin routes
router.post("/admin/login", adminLogin);
router.post("/admin/create", protect, requireAdmin, createAdmin);

export default router;
