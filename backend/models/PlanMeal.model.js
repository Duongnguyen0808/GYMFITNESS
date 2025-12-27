import mongoose from 'mongoose';

const planMealSchema = new mongoose.Schema({
  mealID: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Meal',
    required: true
  },
  listID: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Indexes
planMealSchema.index({ listID: 1 });
planMealSchema.index({ mealID: 1 });

const PlanMeal = mongoose.model('PlanMeal', planMealSchema);

export default PlanMeal;

