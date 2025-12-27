import mongoose from 'mongoose';

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  asset: {
    type: String,
    default: ''
  },
  parentCategoryID: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    default: null
  },
  type: {
    type: String,
    enum: ['workout', 'workout_collection', 'meal'],
    required: true
  }
}, {
  timestamps: true
});

// Indexes
categorySchema.index({ type: 1, parentCategoryID: 1 });
categorySchema.index({ name: 'text' });

const Category = mongoose.model('Category', categorySchema);

export default Category;



