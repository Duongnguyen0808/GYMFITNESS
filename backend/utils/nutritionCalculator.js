/**
 * Utility functions for calculating nutrition and fitness metrics
 */

/**
 * Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
 * @param {Number} weight - Weight in kg
 * @param {Number} height - Height in cm
 * @param {Number} age - Age in years
 * @param {String} gender - 'male', 'female', or 'other'
 * @returns {Number} BMR in calories per day
 */
export const calculateBMR = (weight, height, age, gender) => {
  // Convert height from cm to meters
  const heightInMeters = height / 100;

  // Base BMR calculation (Mifflin-St Jeor Equation)
  let bmr = 10 * weight + 6.25 * height - 5 * age;

  // Gender adjustment
  if (gender === "male") {
    bmr += 5;
  } else if (gender === "female") {
    bmr -= 161;
  } else {
    // For 'other', use average of male and female
    bmr -= 78;
  }

  return Math.round(bmr);
};

/**
 * Calculate Total Daily Energy Expenditure (TDEE)
 * @param {Number} bmr - Basal Metabolic Rate
 * @param {String} activeFrequency - Activity level: 'sedentary', 'light', 'moderate', 'active', 'very_active'
 * @returns {Number} TDEE in calories per day
 */
export const calculateTDEE = (bmr, activeFrequency) => {
  const activityMultipliers = {
    sedentary: 1.2, // Little or no exercise
    light: 1.375, // Light exercise 1-3 days/week
    moderate: 1.55, // Moderate exercise 3-5 days/week
    active: 1.725, // Hard exercise 6-7 days/week
    very_active: 1.9, // Very hard exercise, physical job
  };

  const multiplier =
    activityMultipliers[activeFrequency] || activityMultipliers.moderate;
  return Math.round(bmr * multiplier);
};

/**
 * Calculate daily calorie goal based on weight goal
 * @param {Number} tdee - Total Daily Energy Expenditure
 * @param {Number} currentWeight - Current weight in kg
 * @param {Number} goalWeight - Goal weight in kg
 * @returns {Object} { dailyIntakeCalories, dailyOuttakeCalories, dailyGoalCalories }
 */
export const calculateDailyCalorieGoal = (tdee, currentWeight, goalWeight) => {
  const weightDiff = goalWeight - currentWeight;

  // Calories per kg of body weight (1 kg ≈ 7700 calories)
  const caloriesPerKg = 7700;

  // Target weekly weight change (safe rate: 0.5-1 kg per week)
  const targetWeeklyWeightChange = weightDiff > 0 ? 0.5 : -0.5; // Gain or lose 0.5kg/week

  // Daily calorie adjustment needed
  const dailyCalorieAdjustment = (targetWeeklyWeightChange * caloriesPerKg) / 7;

  // Daily intake calories (what to eat)
  const dailyIntakeCalories = Math.round(tdee + dailyCalorieAdjustment);

  // Daily outtake calories (calories to burn through exercise)
  // For weight loss: burn more, for weight gain: burn less
  const dailyOuttakeCalories =
    weightDiff < 0
      ? Math.round(Math.abs(dailyCalorieAdjustment) * 0.6) // 60% from exercise
      : Math.round(Math.abs(dailyCalorieAdjustment) * 0.4); // 40% from exercise for weight gain

  // Daily goal calories (net calories after exercise)
  const dailyGoalCalories = dailyIntakeCalories - dailyOuttakeCalories;

  return {
    dailyIntakeCalories,
    dailyOuttakeCalories,
    dailyGoalCalories,
  };
};

/**
 * Calculate plan length in days based on weight difference
 * @param {Number} currentWeight - Current weight in kg
 * @param {Number} goalWeight - Goal weight in kg
 * @param {Number} weeklyWeightChange - Target weekly weight change (default: 0.5 kg/week)
 * @returns {Number} Plan length in days
 */
export const calculatePlanLength = (
  currentWeight,
  goalWeight,
  weeklyWeightChange = 0.5
) => {
  const weightDiff = Math.abs(goalWeight - currentWeight);
  const weeksNeeded = weightDiff / weeklyWeightChange;
  const daysNeeded = Math.ceil(weeksNeeded * 7);

  // Minimum 7 days, maximum 30 days (1 month)
  return Math.max(7, Math.min(daysNeeded, 30));
};

/**
 * Calculate calories burned for an exercise
 * @param {Number} metValue - MET (Metabolic Equivalent) value of exercise
 * @param {Number} weight - User weight in kg
 * @param {Number} durationMinutes - Duration in minutes
 * @returns {Number} Calories burned
 */
export const calculateExerciseCalories = (
  metValue,
  weight,
  durationMinutes
) => {
  // Formula: METs × weight (kg) × time (hours)
  const hours = durationMinutes / 60;
  return Math.round(metValue * weight * hours);
};

/**
 * Calculate total nutrition from ingredients
 * @param {Array} ingredients - Array of { ingredientID, amount } objects
 * @param {Map} ingredientData - Map of ingredientID to ingredient data
 * @returns {Object} { kcal, protein, carbs, fat }
 */
export const calculateMealNutrition = (ingredients, ingredientData) => {
  let totalKcal = 0;
  let totalProtein = 0;
  let totalCarbs = 0;
  let totalFat = 0;

  ingredients.forEach(({ ingredientID, amount }) => {
    const ingredient = ingredientData.get(ingredientID.toString());
    if (ingredient) {
      // amount is in grams, nutrition values are per 100g
      const multiplier = parseFloat(amount) / 100;
      totalKcal += (ingredient.kcal || 0) * multiplier;
      totalProtein += (ingredient.protein || 0) * multiplier;
      totalCarbs += (ingredient.carbs || 0) * multiplier;
      totalFat += (ingredient.fat || 0) * multiplier;
    }
  });

  return {
    kcal: Math.round(totalKcal),
    protein: Math.round(totalProtein * 10) / 10,
    carbs: Math.round(totalCarbs * 10) / 10,
    fat: Math.round(totalFat * 10) / 10,
  };
};
