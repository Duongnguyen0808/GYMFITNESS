import Meal from '../models/Meal.model.js';

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
      query.categoryIDs = categoryId;
    }

    if (search) {
      query.$text = { $search: search };
    }

    const meals = await Meal.find(query)
      .populate('categoryIDs', 'name asset')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: meals.length,
      data: meals
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
      .populate('categoryIDs', 'name asset');

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found'
      });
    }

    res.status(200).json({
      success: true,
      data: meal
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
    const meal = await Meal.create(req.body);

    res.status(201).json({
      success: true,
      data: meal
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
    const meal = await Meal.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found'
      });
    }

    res.status(200).json({
      success: true,
      data: meal
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


