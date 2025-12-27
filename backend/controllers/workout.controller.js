import Workout from '../models/Workout.model.js';
import { normalizeAssetUrl, normalizeAssetUrlForStorage, normalizeArrayImageUrls, normalizeObjectImageUrls } from '../utils/urlHelper.js';

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

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedWorkouts = normalizeArrayImageUrls(workouts, req);

    res.status(200).json({
      success: true,
      count: normalizedWorkouts.length,
      data: normalizedWorkouts
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

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedWorkout = normalizeObjectImageUrls(workout, req);

    res.status(200).json({
      success: true,
      data: normalizedWorkout
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
    // Normalize thumbnail, muscleFocusAsset và animation để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.thumbnail) {
      body.thumbnail = normalizeAssetUrlForStorage(body.thumbnail);
    }
    if (body.muscleFocusAsset) {
      body.muscleFocusAsset = normalizeAssetUrlForStorage(body.muscleFocusAsset);
    }
    if (body.animation) {
      body.animation = normalizeAssetUrlForStorage(body.animation);
    }
    const workout = await Workout.create(body);

    // Normalize image URLs (bao gồm cả populate fields nếu có)
    const normalizedWorkout = normalizeObjectImageUrls(workout, req);

    res.status(201).json({
      success: true,
      data: normalizedWorkout
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
    // Normalize thumbnail, muscleFocusAsset và animation để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.thumbnail) {
      body.thumbnail = normalizeAssetUrlForStorage(body.thumbnail);
    }
    if (body.muscleFocusAsset) {
      body.muscleFocusAsset = normalizeAssetUrlForStorage(body.muscleFocusAsset);
    }
    if (body.animation) {
      body.animation = normalizeAssetUrlForStorage(body.animation);
    }
    const workout = await Workout.findByIdAndUpdate(
      req.params.id,
      body,
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

    // Normalize image URLs (bao gồm cả populate fields)
    const normalizedWorkout = normalizeObjectImageUrls(workout, req);

    res.status(200).json({
      success: true,
      data: normalizedWorkout
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


