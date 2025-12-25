import mongoose from 'mongoose';

const ingredientSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  kcal: {
    type: Number,
    required: true,
    default: 0
  },
  fat: {
    type: Number,
    required: true,
    default: 0
  },
  carbs: {
    type: Number,
    required: true,
    default: 0
  },
  protein: {
    type: Number,
    required: true,
    default: 0
  },
  imageUrl: {
    type: String,
    default: ''
  }
}, {
  timestamps: true
});

// Indexes
ingredientSchema.index({ name: 'text' });

const Ingredient = mongoose.model('Ingredient', ingredientSchema);

export default Ingredient;

