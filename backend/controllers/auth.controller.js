import User from '../models/User.model.js';
import { generateToken } from '../utils/generateToken.js';

/**
 * @desc    Register new user
 * @route   POST /api/auth/register
 * @access  Public
 */
export const register = async (req, res) => {
  try {
    const {
      email,
      password,
      name,
      gender,
      dateOfBirth,
      currentWeight,
      currentHeight,
      goalWeight,
      weightUnit,
      heightUnit,
      activeFrequency,
      ...otherFields
    } = req.body;

    // Check if user exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'User already exists'
      });
    }

    // Tự động tạo name từ email nếu không có
    const userName = name || email.split('@')[0] || 'User';
    
    // Create user với giá trị mặc định nếu không có
    const user = await User.create({
      email,
      password,
      name: userName,
      gender: gender || 'other',
      dateOfBirth: dateOfBirth || new Date('2000-01-01'),
      currentWeight: currentWeight || 70,
      currentHeight: currentHeight || 170,
      goalWeight: goalWeight || 65,
      weightUnit: weightUnit || 'kg',
      heightUnit: heightUnit || 'cm',
      activeFrequency: activeFrequency || 'moderate',
      ...otherFields
    });

    if (user) {
      res.status(201).json({
        success: true,
        data: {
          user: user.toJSON(),
          token: generateToken(user._id)
        }
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid user data'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate email & password
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Check for user
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if password matches
    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user: user.toJSON(),
        token: generateToken(user._id)
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get current logged in user
 * @route   GET /api/auth/me
 * @access  Private
 */
export const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


