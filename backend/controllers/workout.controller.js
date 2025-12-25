import Workout from '../models/Workout.model.js';

/**
 * @desc    Get all workouts
 * @route   GET /api/workouts
 * @access  Public
 */
export const getWorkouts = async (req, res) => {
  try {
    const { categoryId, search } = req.query;
    let query = {};

    if (categoryId) {
      query.categoryIDs = categoryId;
    }

    if (search) {
      query.$text = { $search: search };
    }

    const workouts = await Workout.find(query)
      .populate('categoryIDs', 'name asset')
      .populate('equipmentIDs', 'name')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: workouts.length,
      data: workouts
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single workout
 * @route   GET /api/workouts/:id
 * @access  Public
 */
export const getWorkout = async (req, res) => {
  try {
    const workout = await Workout.findById(req.params.id)
      .populate('categoryIDs', 'name asset')
      .populate('equipmentIDs', 'name');

    if (!workout) {
      return res.status(404).json({
        success: false,
        message: 'Workout not found'
      });
    }

    res.status(200).json({
      success: true,
      data: workout
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create workout
 * @route   POST /api/workouts
 * @access  Private
 */
export const createWorkout = async (req, res) => {
  try {
    const workout = await Workout.create(req.body);

    res.status(201).json({
      success: true,
      data: workout
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update workout
 * @route   PUT /api/workouts/:id
 * @access  Private
 */
export const updateWorkout = async (req, res) => {
  try {
    const workout = await Workout.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!workout) {
      return res.status(404).json({
        success: false,
        message: 'Workout not found'
      });
    }

    res.status(200).json({
      success: true,
      data: workout
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete workout
 * @route   DELETE /api/workouts/:id
 * @access  Private
 */
export const deleteWorkout = async (req, res) => {
  try {
    const workout = await Workout.findById(req.params.id);

    if (!workout) {
      return res.status(404).json({
        success: false,
        message: 'Workout not found'
      });
    }

    await workout.deleteOne();

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


