import Meal from '../models/Meal.model.js';
import { normalizeAssetUrl, normalizeAssetUrlForStorage, normalizeArrayImageUrls, normalizeObjectImageUrls } from '../utils/urlHelper.js';

/**
 * @desc    Get all meals
 * @route   GET /api/meals
 * @access  Public
 */
export const getMeals = async (req, res) => {
  try {
    const { categoryId, search } = req.query;
    let query = {};

    if (categoryId) {
      // categoryIDs là mảng, cần dùng $in để tìm trong mảng
      query.categoryIDs = { $in: [categoryId] };
    }

    if (search) {
      query.$text = { $search: search };
    }

    const meals = await Meal.find(query)
      .populate('categoryIDs', 'name asset')
      .sort({ createdAt: -1 })
      .lean();

    // Convert ingreIDToAmount Map to plain object for JSON serialization
    const mealsWithPlainMap = meals.map(meal => {
      if (meal.ingreIDToAmount && meal.ingreIDToAmount instanceof Map) {
        meal.ingreIDToAmount = Object.fromEntries(meal.ingreIDToAmount);
      }
      return meal;
    });

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedMeals = normalizeArrayImageUrls(mealsWithPlainMap, req);

    res.status(200).json({
      success: true,
      count: normalizedMeals.length,
      data: normalizedMeals
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single meal
 * @route   GET /api/meals/:id
 * @access  Public
 */
export const getMeal = async (req, res) => {
  try {
    const meal = await Meal.findById(req.params.id)
      .populate('categoryIDs', 'name asset')
      .lean(); // Convert Mongoose document to plain object

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found'
      });
    }

    // Convert ingreIDToAmount Map to plain object for JSON serialization
    if (meal.ingreIDToAmount && meal.ingreIDToAmount instanceof Map) {
      meal.ingreIDToAmount = Object.fromEntries(meal.ingreIDToAmount);
    }

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedMeal = normalizeObjectImageUrls(meal, req);

    res.status(200).json({
      success: true,
      data: normalizedMeal
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create meal
 * @route   POST /api/meals
 * @access  Private
 */
export const createMeal = async (req, res) => {
  try {
    // Normalize asset để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.asset) {
      body.asset = normalizeAssetUrlForStorage(body.asset);
    }
    const meal = await Meal.create(body);
    
    // Convert to plain object and handle ingreIDToAmount Map
    const mealObj = meal.toObject();
    if (mealObj.ingreIDToAmount && mealObj.ingreIDToAmount instanceof Map) {
      mealObj.ingreIDToAmount = Object.fromEntries(mealObj.ingreIDToAmount);
    }

    // Normalize image URLs (bao gồm cả populate fields nếu có)
    const normalizedMeal = normalizeObjectImageUrls(mealObj, req);

    res.status(201).json({
      success: true,
      data: normalizedMeal
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update meal
 * @route   PUT /api/meals/:id
 * @access  Private
 */
export const updateMeal = async (req, res) => {
  try {
    // Normalize asset để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.asset) {
      body.asset = normalizeAssetUrlForStorage(body.asset);
    }
    const meal = await Meal.findByIdAndUpdate(
      req.params.id,
      body,
      {
        new: true,
        runValidators: true
      }
    ).lean(); // Convert to plain object

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found'
      });
    }

    // Convert ingreIDToAmount Map to plain object for JSON serialization
    if (meal.ingreIDToAmount && meal.ingreIDToAmount instanceof Map) {
      meal.ingreIDToAmount = Object.fromEntries(meal.ingreIDToAmount);
    }

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedMeal = normalizeObjectImageUrls(meal, req);

    res.status(200).json({
      success: true,
      data: normalizedMeal
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete meal
 * @route   DELETE /api/meals/:id
 * @access  Private
 */
export const deleteMeal = async (req, res) => {
  try {
    const meal = await Meal.findById(req.params.id);

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found'
      });
    }

    await meal.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


