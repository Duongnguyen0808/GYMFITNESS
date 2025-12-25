import WorkoutCollection from '../models/WorkoutCollection.model.js';
import MealCollection from '../models/MealCollection.model.js';

/**
 * @desc    Get all workout collections
 * @route   GET /api/collections/workouts
 * @access  Public
 */
export const getWorkoutCollections = async (req, res) => {
  try {
    const { userId, isDefault } = req.query;
    let query = {};

    if (userId) {
      query.userId = userId;
    } else if (isDefault === 'true' || isDefault === true) {
      query.isDefault = true;
      query.userId = null;
    }

    const collections = await WorkoutCollection.find(query)
      .populate('generatorIDs', 'name thumbnail')
      .populate('categoryIDs', 'name asset')
      .populate('userId', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: collections.length,
      data: collections
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single workout collection
 * @route   GET /api/collections/workouts/:id
 * @access  Public
 */
export const getWorkoutCollection = async (req, res) => {
  try {
    const collection = await WorkoutCollection.findById(req.params.id)
      .populate('generatorIDs', 'name thumbnail animation')
      .populate('categoryIDs', 'name asset')
      .populate('userId', 'name email');

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Workout collection not found'
      });
    }

    res.status(200).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create workout collection
 * @route   POST /api/collections/workouts
 * @access  Private
 */
export const createWorkoutCollection = async (req, res) => {
  try {
    const collection = await WorkoutCollection.create({
      ...req.body,
      userId: req.user ? req.user.id : null
    });

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('workout-collection-created', collection);
    }

    res.status(201).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update workout collection
 * @route   PUT /api/collections/workouts/:id
 * @access  Private
 */
export const updateWorkoutCollection = async (req, res) => {
  try {
    const collection = await WorkoutCollection.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Workout collection not found'
      });
    }

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('workout-collection-updated', collection);
    }

    res.status(200).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete workout collection
 * @route   DELETE /api/collections/workouts/:id
 * @access  Private
 */
export const deleteWorkoutCollection = async (req, res) => {
  try {
    const collection = await WorkoutCollection.findById(req.params.id);

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Workout collection not found'
      });
    }

    await collection.deleteOne();

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('workout-collection-deleted', { id: req.params.id });
    }

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

/**
 * @desc    Get all meal collections
 * @route   GET /api/collections/meals
 * @access  Public
 */
export const getMealCollections = async (req, res) => {
  try {
    const collections = await MealCollection.find()
      .populate({
        path: 'dateToMealID',
        populate: {
          path: '$*',
          model: 'Meal'
        }
      })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: collections.length,
      data: collections
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single meal collection
 * @route   GET /api/collections/meals/:id
 * @access  Public
 */
export const getMealCollection = async (req, res) => {
  try {
    const collection = await MealCollection.findById(req.params.id)
      .populate({
        path: 'dateToMealID',
        populate: {
          path: '$*',
          model: 'Meal'
        }
      });

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Meal collection not found'
      });
    }

    res.status(200).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create meal collection
 * @route   POST /api/collections/meals
 * @access  Private
 */
export const createMealCollection = async (req, res) => {
  try {
    const collection = await MealCollection.create(req.body);

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('meal-collection-created', collection);
    }

    res.status(201).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update meal collection
 * @route   PUT /api/collections/meals/:id
 * @access  Private
 */
export const updateMealCollection = async (req, res) => {
  try {
    const collection = await MealCollection.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Meal collection not found'
      });
    }

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('meal-collection-updated', collection);
    }

    res.status(200).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete meal collection
 * @route   DELETE /api/collections/meals/:id
 * @access  Private
 */
export const deleteMealCollection = async (req, res) => {
  try {
    const collection = await MealCollection.findById(req.params.id);

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Meal collection not found'
      });
    }

    await collection.deleteOne();

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.emit('meal-collection-deleted', { id: req.params.id });
    }

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


