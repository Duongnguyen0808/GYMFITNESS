import Category from '../models/Category.model.js';
import { normalizeAssetUrl, normalizeAssetUrlForStorage, normalizeArrayImageUrls, normalizeObjectImageUrls } from '../utils/urlHelper.js';

/**
 * @desc    Get all categories
 * @route   GET /api/categories
 * @access  Public
 */
export const getCategories = async (req, res) => {
  try {
    const { type, parentId } = req.query;
    let query = {};

    if (type) {
      query.type = type;
    }

    if (parentId) {
      query.parentCategoryID = parentId;
    } else if (parentId === null || parentId === 'null') {
      query.parentCategoryID = null;
    }

    const categories = await Category.find(query)
      .populate('parentCategoryID', 'name asset')
      .sort({ name: 1 });

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedCategories = normalizeArrayImageUrls(categories, req);

    res.status(200).json({
      success: true,
      count: normalizedCategories.length,
      data: normalizedCategories
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single category
 * @route   GET /api/categories/:id
 * @access  Public
 */
export const getCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id)
      .populate('parentCategoryID', 'name asset');

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedCategory = normalizeObjectImageUrls(category, req);

    res.status(200).json({
      success: true,
      data: normalizedCategory
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create category
 * @route   POST /api/categories
 * @access  Private
 */
export const createCategory = async (req, res) => {
  try {
    // Normalize asset để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.asset) {
      body.asset = normalizeAssetUrlForStorage(body.asset);
    }
    const category = await Category.create(body);

    // Normalize image URLs (bao gồm cả populate fields nếu có)
    const normalizedCategory = normalizeObjectImageUrls(category, req);

    res.status(201).json({
      success: true,
      data: normalizedCategory
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update category
 * @route   PUT /api/categories/:id
 * @access  Private
 */
export const updateCategory = async (req, res) => {
  try {
    // Normalize asset để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.asset) {
      body.asset = normalizeAssetUrlForStorage(body.asset);
    }
    const category = await Category.findByIdAndUpdate(
      req.params.id,
      body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedCategory = normalizeObjectImageUrls(category, req);

    res.status(200).json({
      success: true,
      data: normalizedCategory
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete category
 * @route   DELETE /api/categories/:id
 * @access  Private
 */
export const deleteCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    await category.deleteOne();

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


