import mongoose from 'mongoose';

const planExerciseSchema = new mongoose.Schema({
  exerciseID: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Workout',
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
planExerciseSchema.index({ listID: 1 });
planExerciseSchema.index({ exerciseID: 1 });

const PlanExercise = mongoose.model('PlanExercise', planExerciseSchema);

export default PlanExercise;

