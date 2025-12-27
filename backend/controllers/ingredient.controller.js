import Ingredient from '../models/Ingredient.model.js';
import { normalizeAssetUrl, normalizeAssetUrlForStorage, normalizeArrayImageUrls } from '../utils/urlHelper.js';

/**
 * @desc    Get all ingredients
 * @route   GET /api/ingredients
 * @access  Public
 */
export const getIngredients = async (req, res) => {
  try {
    const { search } = req.query;
    let query = {};

    if (search) {
      query.$text = { $search: search };
    }

    const ingredients = await Ingredient.find(query).sort({ createdAt: -1 });

    // Normalize image URLs
    const normalizedIngredients = normalizeArrayImageUrls(ingredients, req);

    res.status(200).json({
      success: true,
      count: normalizedIngredients.length,
      data: normalizedIngredients
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single ingredient
 * @route   GET /api/ingredients/:id
 * @access  Public
 */
export const getIngredient = async (req, res) => {
  try {
    const ingredient = await Ingredient.findById(req.params.id);

    if (!ingredient) {
      return res.status(404).json({
        success: false,
        message: 'Ingredient not found'
      });
    }

    res.status(200).json({
      success: true,
      data: ingredient
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create ingredient
 * @route   POST /api/ingredients
 * @access  Private
 */
export const createIngredient = async (req, res) => {
  try {
    // Normalize imageUrl để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.imageUrl) {
      body.imageUrl = normalizeAssetUrlForStorage(body.imageUrl);
    }
    const ingredient = await Ingredient.create(body);

    // Normalize image URL
    const normalizedIngredient = normalizeArrayImageUrls([ingredient], req)[0];

    res.status(201).json({
      success: true,
      data: normalizedIngredient
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update ingredient
 * @route   PUT /api/ingredients/:id
 * @access  Private
 */
export const updateIngredient = async (req, res) => {
  try {
    // Normalize imageUrl để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.imageUrl) {
      body.imageUrl = normalizeAssetUrlForStorage(body.imageUrl);
    }
    const ingredient = await Ingredient.findByIdAndUpdate(
      req.params.id,
      body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!ingredient) {
      return res.status(404).json({
        success: false,
        message: 'Ingredient not found'
      });
    }

    res.status(200).json({
      success: true,
      data: ingredient
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete ingredient
 * @route   DELETE /api/ingredients/:id
 * @access  Private
 */
export const deleteIngredient = async (req, res) => {
  try {
    const ingredient = await Ingredient.findById(req.params.id);

    if (!ingredient) {
      return res.status(404).json({
        success: false,
        message: 'Ingredient not found'
      });
    }

    await ingredient.deleteOne();

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


