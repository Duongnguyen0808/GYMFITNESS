import Workout from "../models/Workout.model.js";
import Meal from "../models/Meal.model.js";
import Category from "../models/Category.model.js";
import Ingredient from "../models/Ingredient.model.js";
import {
  calculateBMR,
  calculateTDEE,
  calculateDailyCalorieGoal,
  calculatePlanLength,
  calculateExerciseCalories,
  calculateMealNutrition,
} from "../utils/nutritionCalculator.js";

/**
 * Recommendation Service
 * Provides intelligent recommendations for exercises and meals based on user profile
 */
class RecommendationService {
  /**
   * Get recommended exercises based on user profile
   * @param {Object} userProfile - User profile with preferences and constraints
   * @param {Number} targetCalories - Target calories to burn
   * @param {Number} userWeight - User weight in kg
   * @returns {Promise<Array>} Array of recommended workout IDs
   */
  async getRecommendedExercises(userProfile, targetCalories, userWeight) {
    const {
      experience = "beginner",
      limits = [],
      activeFrequency = "moderate",
      mainGoal = null,
    } = userProfile;

    // Build query filters
    const query = {};

    // Filter by experience level (if categories have experience tags)
    // For now, we'll filter by MET values based on experience
    const metRanges = this.getMETRangeForExperience(experience);

    // Get all workouts - sử dụng lean() để query nhanh hơn
    let workouts = await Workout.find(query)
      .select("_id name metValue categoryIDs asset")
      .lean();

    // Filter workouts based on user constraints
    workouts = this.filterWorkoutsByConstraints(workouts, {
      experience,
      limits,
      metRanges,
      mainGoal,
    });

    // Select workouts to meet target calories
    const selectedWorkouts = this.selectWorkoutsForCalories(
      workouts,
      targetCalories,
      userWeight
    );

    return selectedWorkouts.map((w) => w._id);
  }

  /**
   * Get recommended meals based on user profile
   * @param {Object} userProfile - User profile with preferences
   * @param {Number} targetCalories - Target calories to consume
   * @returns {Promise<Array>} Array of recommended meal IDs
   */
  async getRecommendedMeals(userProfile, targetCalories) {
    const {
      diet = null,
      proteinSources = [],
      limits = [],
      mainGoal = null,
    } = userProfile;

    // Get meal categories (breakfast, lunch, dinner, snack) - sử dụng lean()
    const mealCategories = await Category.find({ type: "meal" }).lean();

    // Get all meals - sử dụng lean() và chỉ select fields cần thiết
    let meals = await Meal.find()
      .select("_id name calories categoryIDs proteinSources asset")
      .lean();

    if (meals.length === 0) {
      console.warn("No meals found in database");
      return [];
    }

    // Filter meals based on user preferences
    meals = this.filterMealsByPreferences(meals, {
      diet,
      proteinSources,
      limits,
      mainGoal,
    });

    // If we have meal categories, group and select by category
    if (mealCategories.length >= 1) {
      const mealsByCategory = this.groupMealsByCategory(meals, mealCategories);
      const selectedMeals = this.selectMealsForCalories(
        mealsByCategory,
        targetCalories
      );
      return selectedMeals.map((m) => m._id);
    }

    // Fallback: select meals directly without categories
    const selectedMeals = this.selectMealsDirectly(meals, targetCalories);
    return selectedMeals.map((m) => m._id);
  }

  /**
   * Select meals directly without category grouping (fallback)
   */
  selectMealsDirectly(meals, targetCalories) {
    const targetMeals = Math.max(3, Math.ceil(targetCalories / 500)); // At least 3 meals
    const shuffled = [...meals].sort(() => Math.random() - 0.5);
    return shuffled.slice(0, Math.min(targetMeals, shuffled.length));
  }

  /**
   * Generate complete workout and meal plan
   * @param {Object} user - User object with all profile data
   * @returns {Promise<Object>} Complete plan with calculations
   */
  async generatePlan(user) {
    const {
      currentWeight,
      goalWeight,
      currentHeight,
      gender,
      dateOfBirth,
      activeFrequency,
      experience,
      limits,
      diet,
      proteinSources,
      mainGoal,
    } = user;

    // Calculate age
    const age = dateOfBirth
      ? Math.floor(
          (new Date() - new Date(dateOfBirth)) / (365.25 * 24 * 60 * 60 * 1000)
        )
      : 30; // Default age if not provided

    // Calculate BMR and TDEE
    const bmr = calculateBMR(currentWeight, currentHeight, age, gender);
    const tdee = calculateTDEE(bmr, activeFrequency || "moderate");

    // Calculate daily calorie goals
    const calorieGoals = calculateDailyCalorieGoal(
      tdee,
      currentWeight,
      goalWeight
    );

    // Calculate plan length
    const planLengthInDays = calculatePlanLength(currentWeight, goalWeight);

    // Get recommended exercises and meals SONG SONG để tăng tốc
    const [exerciseIDs, mealIDs] = await Promise.all([
      this.getRecommendedExercises(
        { experience, limits, activeFrequency, mainGoal },
        calorieGoals.dailyOuttakeCalories,
        currentWeight
      ),
      this.getRecommendedMeals(
        { diet, proteinSources, limits, mainGoal },
        calorieGoals.dailyIntakeCalories
      ),
    ]);

    const result = {
      bmr,
      tdee,
      ...calorieGoals,
      planLengthInDays,
      recommendedExerciseIDs: exerciseIDs,
      recommendedMealIDs: mealIDs,
      startDate: new Date(),
      endDate: new Date(Date.now() + planLengthInDays * 24 * 60 * 60 * 1000),
    };

    return result;
  }

  // Helper methods

  getMETRangeForExperience(experience) {
    const ranges = {
      beginner: { min: 2, max: 6 }, // Light to moderate intensity
      intermediate: { min: 4, max: 8 }, // Moderate to vigorous
      advanced: { min: 6, max: 12 }, // Vigorous to very vigorous
    };
    return ranges[experience] || ranges.beginner;
  }

  filterWorkoutsByConstraints(workouts, constraints) {
    const { experience, limits, metRanges, mainGoal } = constraints;

    return workouts.filter((workout) => {
      // Filter by MET range based on experience
      if (workout.metValue) {
        if (
          workout.metValue < metRanges.min ||
          workout.metValue > metRanges.max
        ) {
          return false;
        }
      }

      // Filter by equipment limitations (if user has limits)
      // This would need to be expanded based on your limits structure
      if (limits && limits.length > 0) {
        // Check if workout requires equipment that user can't use
        // Implementation depends on how limits are structured
      }

      return true;
    });
  }

  selectWorkoutsForCalories(workouts, targetCalories, userWeight) {
    const selected = [];
    let totalCalories = 0;
    const exerciseDuration = 45; // 45 seconds per exercise

    // Shuffle workouts for variety
    const shuffled = [...workouts].sort(() => Math.random() - 0.5);

    for (const workout of shuffled) {
      if (totalCalories >= targetCalories) break;

      const calories = calculateExerciseCalories(
        workout.metValue || 5,
        userWeight,
        exerciseDuration / 60 // Convert to minutes
      );

      selected.push(workout);
      totalCalories += calories;
    }

    // Ensure we have at least 10 exercises
    if (selected.length < 10 && workouts.length >= 10) {
      const additional = shuffled
        .filter((w) => !selected.some((s) => s._id.equals(w._id)))
        .slice(0, 10 - selected.length);
      selected.push(...additional);
    }

    return selected;
  }

  filterMealsByPreferences(meals, preferences) {
    const { diet, proteinSources, limits, mainGoal } = preferences;

    return meals.filter((meal) => {
      // Filter by diet type (vegetarian, vegan, etc.)
      // This would need meal tags or categories to work properly
      // For now, we'll just return all meals

      return true;
    });
  }

  groupMealsByCategory(meals, categories) {
    const grouped = {};

    categories.forEach((category) => {
      grouped[category._id.toString()] = meals.filter((meal) =>
        meal.categoryIDs.some((catID) => catID._id.equals(category._id))
      );
    });

    return grouped;
  }

  selectMealsForCalories(mealsByCategory, targetCalories) {
    const selected = [];
    const categoryIds = Object.keys(mealsByCategory);

    // Get at least one meal from each category
    categoryIds.forEach((categoryId) => {
      const categoryMeals = mealsByCategory[categoryId];
      if (categoryMeals.length > 0) {
        const randomMeal =
          categoryMeals[Math.floor(Math.random() * categoryMeals.length)];
        if (!selected.some((m) => m._id.equals(randomMeal._id))) {
          selected.push(randomMeal);
        }
      }
    });

    // Add more meals if needed to reach target calories
    // This is simplified - in reality, you'd calculate meal calories from ingredients
    const targetMeals = Math.ceil(targetCalories / 500); // Assume ~500 cal per meal
    const allMeals = Object.values(mealsByCategory).flat();
    const shuffled = [...allMeals].sort(() => Math.random() - 0.5);

    for (const meal of shuffled) {
      if (selected.length >= targetMeals) break;
      if (!selected.some((m) => m._id.equals(meal._id))) {
        selected.push(meal);
      }
    }

    return selected;
  }
}

export default new RecommendationService();
