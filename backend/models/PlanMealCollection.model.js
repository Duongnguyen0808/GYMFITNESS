import mongoose from 'mongoose';

const planMealCollectionSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true
  },
  planID: {
    type: Number,
    required: true,
    default: 0 // 0 = default plan
  },
  mealRatio: {
    type: Number,
    required: true,
    default: 1.0
  }
}, {
  timestamps: true
});

// Indexes
planMealCollectionSchema.index({ planID: 1, date: 1 });
planMealCollectionSchema.index({ date: 1 });

const PlanMealCollection = mongoose.model('PlanMealCollection', planMealCollectionSchema);

export default PlanMealCollection;

