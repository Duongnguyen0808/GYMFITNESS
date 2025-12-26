import mongoose from 'mongoose';

const workoutPlanSchema = new mongoose.Schema({
  userID: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  planID: {
    type: Number,
    required: true,
    unique: true
  },
  dailyGoalCalories: {
    type: Number,
    required: true,
    default: 0
  },
  startDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  endDate: {
    type: Date,
    required: true
  }
}, {
  timestamps: true
});

// Indexes
// Note: planID already has unique: true which creates an index automatically
workoutPlanSchema.index({ userID: 1 });
workoutPlanSchema.index({ startDate: 1, endDate: 1 });

const WorkoutPlan = mongoose.model('WorkoutPlan', workoutPlanSchema);

export default WorkoutPlan;

