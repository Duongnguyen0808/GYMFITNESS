import mongoose from 'mongoose';

const mealSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  asset: {
    type: String,
    default: ''
  },
  cookTime: {
    type: Number,
    default: 0
  },
  ingreIDToAmount: {
    type: Map,
    of: String,
    default: {}
  },
  steps: [{
    type: String
  }],
  categoryIDs: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MealCategory'
  }]
}, {
  timestamps: true
});

// Indexes
mealSchema.index({ name: 'text' });
mealSchema.index({ categoryIDs: 1 });

const Meal = mongoose.model('Meal', mealSchema);

export default Meal;


