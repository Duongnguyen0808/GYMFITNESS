import mongoose from 'mongoose';

const planExerciseCollectionSettingSchema = new mongoose.Schema({
  round: {
    type: Number,
    required: true,
    default: 3
  },
  numOfWorkoutPerRound: {
    type: Number,
    required: true,
    default: 10
  },
  exerciseTime: {
    type: Number,
    required: true,
    default: 45
  },
  isStartWithWarmUp: {
    type: Boolean,
    default: false
  },
  isShuffle: {
    type: Boolean,
    default: false
  },
  transitionTime: {
    type: Number,
    default: 0
  },
  restTime: {
    type: Number,
    default: 0
  },
  restFrequency: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

const PlanExerciseCollectionSetting = mongoose.model('PlanExerciseCollectionSetting', planExerciseCollectionSettingSchema);

export default PlanExerciseCollectionSetting;

