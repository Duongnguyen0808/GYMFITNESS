import mongoose from 'mongoose';
import User from '../models/User.model.js';
import WorkoutPlan from '../models/WorkoutPlan.model.js';
import PlanExerciseCollection from '../models/PlanExerciseCollection.model.js';
import PlanMealCollection from '../models/PlanMealCollection.model.js';
import PlanExercise from '../models/PlanExercise.model.js';
import PlanMeal from '../models/PlanMeal.model.js';
import PlanExerciseCollectionSetting from '../models/PlanExerciseCollectionSetting.model.js';
import Workout from '../models/Workout.model.js';
import Meal from '../models/Meal.model.js';
import recommendationService from '../services/recommendationService.js';

/**
 * @desc    Generate workout and meal plan recommendation
 * @route   POST /api/recommendations/generate-plan
 * @access  Private
 */
export const generatePlan = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user with all profile data
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Validate required fields
    if (!user.currentWeight || !user.goalWeight || !user.currentHeight) {
      return res.status(400).json({
        success: false,
        message: 'Missing required user information: currentWeight, goalWeight, and currentHeight are required'
      });
    }

    // Generate plan recommendation
    const planData = await recommendationService.generatePlan(user);

    res.status(200).json({
      success: true,
      data: planData
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create workout and meal plan from recommendation
 * @route   POST /api/recommendations/create-plan
 * @access  Private
 */
export const createPlan = async (req, res) => {
  try {
    const userId = req.user.id;
    const { 
      planLengthInDays,
      dailyGoalCalories,
      dailyIntakeCalories,
      dailyOuttakeCalories,
      recommendedExerciseIDs,
      recommendedMealIDs,
      startDate,
      endDate
    } = req.body;

    // Validate required fields
    if (!planLengthInDays || !dailyGoalCalories || !recommendedExerciseIDs || !recommendedMealIDs) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: planLengthInDays, dailyGoalCalories, recommendedExerciseIDs, recommendedMealIDs'
      });
    }

    // Get user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Delete existing plan if exists
    const existingPlan = await WorkoutPlan.findOne({ userID: userId });
    if (existingPlan) {
      // Get existing planID before deleting
      const existingPlanID = existingPlan.planID || 0;
      // Delete existing collections
      await PlanExerciseCollection.deleteMany({ planID: existingPlanID });
      await PlanMealCollection.deleteMany({ planID: existingPlanID });
      await WorkoutPlan.findByIdAndDelete(existingPlan._id);
    }

    // Generate a unique planID (simple incrementing approach)
    // In production, you might want to use a more robust ID generation
    const lastPlan = await WorkoutPlan.findOne().sort({ planID: -1 }).limit(1);
    let planID = 1;
    if (lastPlan && lastPlan.planID) {
      planID = lastPlan.planID + 1;
    }

    // Create new workout plan
    const workoutPlan = await WorkoutPlan.create({
      userID: userId,
      planID: planID,
      dailyGoalCalories: dailyGoalCalories,
      startDate: startDate ? new Date(startDate) : new Date(),
      endDate: endDate ? new Date(endDate) : new Date(Date.now() + planLengthInDays * 24 * 60 * 60 * 1000)
    });

    // Create exercise and meal collections for the first 60 days
    const daysToCreate = Math.min(planLengthInDays, 60);
    const createdExerciseCollections = [];
    const createdMealCollections = [];

    for (let i = 0; i < daysToCreate; i++) {
      const date = new Date();
      date.setDate(date.getDate() + i);
      date.setHours(0, 0, 0, 0);

      // Create exercise collection for this day
      const exerciseSetting = await PlanExerciseCollectionSetting.create({
        round: 3,
        numOfWorkoutPerRound: 10,
        isStartWithWarmUp: true,
        isShuffle: true,
        exerciseTime: 45,
        transitionTime: 10,
        restTime: 10,
        restFrequency: 10
      });

      const exerciseCollection = await PlanExerciseCollection.create({
        date: date,
        planID: planID,
        collectionSettingID: exerciseSetting._id.toString()
      });

      // Add exercises to collection (randomly select from recommended)
      const exercisesForDay = selectRandomExercises(recommendedExerciseIDs, 20);
      const planExercises = exercisesForDay.map(exerciseID => ({
        exerciseID: new mongoose.Types.ObjectId(exerciseID),
        listID: exerciseCollection._id.toString()
      }));
      await PlanExercise.insertMany(planExercises);

      createdExerciseCollections.push(exerciseCollection._id);

      // Create meal collection for this day
      const mealCollection = await PlanMealCollection.create({
        date: date,
        planID: planID,
        mealRatio: 1.0
      });

      // Add meals to collection (randomly select from recommended)
      const mealsForDay = selectRandomMeals(recommendedMealIDs, 3);
      const planMeals = mealsForDay.map(mealID => ({
        mealID: new mongoose.Types.ObjectId(mealID),
        listID: mealCollection._id.toString()
      }));
      await PlanMeal.insertMany(planMeals);

      createdMealCollections.push(mealCollection._id);
    }

    res.status(201).json({
      success: true,
      data: {
        plan: workoutPlan,
        exerciseCollectionsCreated: createdExerciseCollections.length,
        mealCollectionsCreated: createdMealCollections.length,
        message: `Plan created successfully with ${daysToCreate} days of exercises and meals`
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
 * @desc    Get plan recommendation preview (without creating plan)
 * @route   GET /api/recommendations/preview
 * @access  Private
 */
export const getPlanPreview = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (!user.currentWeight || !user.goalWeight || !user.currentHeight) {
      return res.status(400).json({
        success: false,
        message: 'Missing required user information. Please complete your profile setup.'
      });
    }

    const planData = await recommendationService.generatePlan(user);

    // Ensure we have arrays
    const exerciseIDs = Array.isArray(planData.recommendedExerciseIDs) 
      ? planData.recommendedExerciseIDs 
      : [];
    const mealIDs = Array.isArray(planData.recommendedMealIDs)
      ? planData.recommendedMealIDs
      : [];

    // Convert to mongoose ObjectId if needed
    const exerciseObjectIds = exerciseIDs.map(id => {
      if (mongoose.Types.ObjectId.isValid(id)) {
        return typeof id === 'string' ? new mongoose.Types.ObjectId(id) : id;
      }
      return null;
    }).filter(id => id !== null);

    const mealObjectIds = mealIDs.map(id => {
      if (mongoose.Types.ObjectId.isValid(id)) {
        return typeof id === 'string' ? new mongoose.Types.ObjectId(id) : id;
      }
      return null;
    }).filter(id => id !== null);

    // Get exercise and meal details for preview
    // ĐÃ SỬA: Lấy toàn bộ thông tin (bao gồm thumbnail, animation, assets...)
    const exercises = exerciseObjectIds.length > 0 
      ? await Workout.find({
          _id: { $in: exerciseObjectIds }
        })
      : [];

    // ĐÃ SỬA: Lấy toàn bộ thông tin bữa ăn
    const meals = mealObjectIds.length > 0
      ? await Meal.find({
          _id: { $in: mealObjectIds }
        })
      : [];

    // Convert dates to ISO strings for JSON response
    const responseData = {
      ...planData,
      startDate: planData.startDate instanceof Date 
        ? planData.startDate.toISOString() 
        : planData.startDate,
      endDate: planData.endDate instanceof Date
        ? planData.endDate.toISOString()
        : planData.endDate,
      recommendedExerciseIDs: exerciseIDs.map(id => id.toString()),
      recommendedMealIDs: mealIDs.map(id => id.toString()),
      exercises,
      meals
    };

    res.status(200).json({
      success: true,
      data: responseData
    });
  } catch (error) {
    console.error('Error in getPlanPreview:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Internal server error',
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Helper functions
function selectRandomExercises(exerciseIDs, count) {
  const shuffled = [...exerciseIDs].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(count, exerciseIDs.length));
}

function selectRandomMeals(mealIDs, count) {
  const shuffled = [...mealIDs].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(count, mealIDs.length));
}

// Attach helper functions to exports
export { selectRandomExercises, selectRandomMeals };