import mongoose from 'mongoose';

const mealCollectionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: ''
  },
  note: {
    type: String,
    default: ''
  },
  asset: {
    type: String,
    default: ''
  },
  dateToMealID: {
    type: Map,
    of: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Meal'
    }],
    default: {}
  }
}, {
  timestamps: true
});

// Indexes
mealCollectionSchema.index({ title: 'text' });

const MealCollection = mongoose.model('MealCollection', mealCollectionSchema);

export default MealCollection;



