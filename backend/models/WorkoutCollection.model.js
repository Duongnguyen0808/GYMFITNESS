import mongoose from 'mongoose';

const workoutCollectionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: ''
  },
  asset: {
    type: String,
    default: ''
  },
  generatorIDs: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Workout'
  }],
  categoryIDs: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category'
  }],
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null // null = default collection, not null = user collection
  },
  isDefault: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Indexes
workoutCollectionSchema.index({ userId: 1, isDefault: 1 });
workoutCollectionSchema.index({ categoryIDs: 1 });

const WorkoutCollection = mongoose.model('WorkoutCollection', workoutCollectionSchema);

export default WorkoutCollection;



