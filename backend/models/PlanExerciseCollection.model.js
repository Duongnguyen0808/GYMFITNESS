import mongoose from 'mongoose';

const planExerciseCollectionSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true
  },
  planID: {
    type: Number,
    required: true,
    default: 0 // 0 = default plan
  },
  collectionSettingID: {
    type: String,
    required: true,
    default: ''
  }
}, {
  timestamps: true
});

// Indexes
planExerciseCollectionSchema.index({ planID: 1, date: 1 });
planExerciseCollectionSchema.index({ date: 1 });

const PlanExerciseCollection = mongoose.model('PlanExerciseCollection', planExerciseCollectionSchema);

export default PlanExerciseCollection;

