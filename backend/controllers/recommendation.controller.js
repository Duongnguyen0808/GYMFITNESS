import mongoose from "mongoose";
import User from "../models/User.model.js";
import WorkoutPlan from "../models/WorkoutPlan.model.js";
import PlanExerciseCollection from "../models/PlanExerciseCollection.model.js";
import PlanMealCollection from "../models/PlanMealCollection.model.js";
import PlanExercise from "../models/PlanExercise.model.js";
import PlanMeal from "../models/PlanMeal.model.js";
import PlanExerciseCollectionSetting from "../models/PlanExerciseCollectionSetting.model.js";
import Workout from "../models/Workout.model.js";
import Meal from "../models/Meal.model.js";
import recommendationService from "../services/recommendationService.js";

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
        message: "User not found",
      });
    }

    // Validate required fields
    if (!user.currentWeight || !user.goalWeight || !user.currentHeight) {
      return res.status(400).json({
        success: false,
        message:
          "Missing required user information: currentWeight, goalWeight, and currentHeight are required",
      });
    }

    // Generate plan recommendation
    const planData = await recommendationService.generatePlan(user);

    res.status(200).json({
      success: true,
      data: planData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
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
      endDate,
    } = req.body;

    // Validate required fields
    if (
      !planLengthInDays ||
      !dailyGoalCalories ||
      !recommendedExerciseIDs ||
      !recommendedMealIDs
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Missing required fields: planLengthInDays, dailyGoalCalories, recommendedExerciseIDs, recommendedMealIDs",
      });
    }

    // Get user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
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
      endDate: endDate
        ? new Date(endDate)
        : new Date(Date.now() + planLengthInDays * 24 * 60 * 60 * 1000),
    });

    // Create exercise and meal collections for the first 60 days
    const daysToCreate = Math.min(planLengthInDays, 60);
    const createdExerciseCollections = [];
    const createdMealCollections = [];

    // Keep track of previous day's selected meal IDs to avoid consecutive repeats
    let prevMealIds = new Set();

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
        restFrequency: 10,
      });

      const exerciseCollection = await PlanExerciseCollection.create({
        date: date,
        planID: planID,
        collectionSettingID: exerciseSetting._id.toString(),
      });

      // Add exercises to collection (randomly select from recommended)
      const exercisesForDay = selectRandomExercises(recommendedExerciseIDs, 20);
      const planExercises = exercisesForDay.map((exerciseID) => ({
        exerciseID: new mongoose.Types.ObjectId(exerciseID),
        listID: exerciseCollection._id.toString(),
      }));
      await PlanExercise.insertMany(planExercises);

      createdExerciseCollections.push(exerciseCollection._id);

      // Create meal collection for this day
      const mealCollection = await PlanMealCollection.create({
        date: date,
        planID: planID,
        mealRatio: 1.0,
      });

      // Add meals to collection (select intelligently from recommendedMealIDs)
      // Fetch meal documents once outside loop would be more efficient, but keep simple here
      const recommendedMealDocs = await Meal.find({
        _id: { $in: recommendedMealIDs.map((id) => new mongoose.Types.ObjectId(id)) },
      }).lean();

      // Select number of meals for the day (default 3)
      let mealsCount = 3;

      // Get workout docs for today's exercises to determine intensity
      const workoutDocs = await Workout.find({
        _id: { $in: exercisesForDay.map((id) => new mongoose.Types.ObjectId(id)) },
      }).lean();

      // Compute average MET for today's exercises
      const avgMET =
        workoutDocs.length > 0
          ? workoutDocs.reduce((s, w) => s + (w.metValue || 5), 0) /
            workoutDocs.length
          : 0;

      // If average MET is high, prefer protein-rich meals and increase meals count slightly
      const preferProtein = avgMET >= 6;
      if (preferProtein) {
        mealsCount = 3;
      } else {
        mealsCount = 3;
      }

      // Simple selection strategy:
      // - Prefer meals that have proteinSources (if preferProtein)
      // - Otherwise pick meals closest to target per-meal calories (dailyIntakeCalories / mealsCount)
      const targetPerMeal = Math.max(300, Math.round(dailyIntakeCalories / Math.max(1, mealsCount)));

      // Rank meals
      const rankedMeals = recommendedMealDocs
        .map((m) => {
          const proteinScore =
            Array.isArray(m.proteinSources) && m.proteinSources.length > 0 ? 1 : 0;
          const calorieDiff = Math.abs((m.calories || 500) - targetPerMeal);
          // score lower is better
          const score = (preferProtein ? -proteinScore * 1000 : 0) + calorieDiff;
          return { meal: m, score };
        })
        .sort((a, b) => a.score - b.score)
        .map((r) => r.meal);

      // Avoid repeating same meals on consecutive days when possible
      let candidateMeals = rankedMeals.filter(
        (m) => !prevMealIds.has(m._id.toString())
      );
      if (candidateMeals.length < mealsCount) {
        // Not enough unique candidates; allow repeats (fall back to full ranked list)
        candidateMeals = rankedMeals;
      }

      const mealsForDay = candidateMeals.slice(
        0,
        Math.min(mealsCount, candidateMeals.length)
      );
      const planMeals = mealsForDay.map((meal) => ({
        mealID: new mongoose.Types.ObjectId(meal._id),
        listID: mealCollection._id.toString(),
      }));
      if (planMeals.length > 0) {
        await PlanMeal.insertMany(planMeals);
      }

      createdMealCollections.push(mealCollection._id);
      // Update prevMealIds for next day
      prevMealIds = new Set(mealsForDay.map((m) => m._id.toString()));
    }

    res.status(201).json({
      success: true,
      data: {
        plan: workoutPlan,
        exerciseCollectionsCreated: createdExerciseCollections.length,
        mealCollectionsCreated: createdMealCollections.length,
        message: `Plan created successfully with ${daysToCreate} days of exercises and meals`,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
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

    // Sử dụng lean() để query nhanh hơn
    const user = await User.findById(userId).lean();
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (!user.currentWeight || !user.goalWeight || !user.currentHeight) {
      return res.status(400).json({
        success: false,
        message:
          "Missing required user information. Please complete your profile setup.",
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
    const exerciseObjectIds = exerciseIDs
      .map((id) => {
        if (mongoose.Types.ObjectId.isValid(id)) {
          return typeof id === "string" ? new mongoose.Types.ObjectId(id) : id;
        }
        return null;
      })
      .filter((id) => id !== null);

    const mealObjectIds = mealIDs
      .map((id) => {
        if (mongoose.Types.ObjectId.isValid(id)) {
          return typeof id === "string" ? new mongoose.Types.ObjectId(id) : id;
        }
        return null;
      })
      .filter((id) => id !== null);

    // Get exercise and meal details song song với lean() để nhanh hơn
    const [exercises, meals] = await Promise.all([
      exerciseObjectIds.length > 0
        ? Workout.find({ _id: { $in: exerciseObjectIds } }).lean()
        : Promise.resolve([]),
      mealObjectIds.length > 0
        ? Meal.find({ _id: { $in: mealObjectIds } }).lean()
        : Promise.resolve([]),
    ]);

    // Convert dates to ISO strings for JSON response
    const responseData = {
      ...planData,
      startDate:
        planData.startDate instanceof Date
          ? planData.startDate.toISOString()
          : planData.startDate,
      endDate:
        planData.endDate instanceof Date
          ? planData.endDate.toISOString()
          : planData.endDate,
      recommendedExerciseIDs: exerciseIDs.map((id) => id.toString()),
      recommendedMealIDs: mealIDs.map((id) => id.toString()),
      exercises,
      meals,
    };

    res.status(200).json({
      success: true,
      data: responseData,
    });
  } catch (error) {
    console.error("Error in getPlanPreview:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Internal server error",
      stack: process.env.NODE_ENV === "development" ? error.stack : undefined,
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
