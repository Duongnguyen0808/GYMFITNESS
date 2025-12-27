import mongoose from 'mongoose';

const workoutSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  animation: {
    type: String,
    default: ''
  },
  thumbnail: {
    type: String,
    default: ''
  },
  hints: {
    type: String,
    default: ''
  },
  breathing: {
    type: String,
    default: ''
  },
  muscleFocusAsset: {
    type: String,
    default: ''
  },
  categoryIDs: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category'
  }],
  metValue: {
    type: Number,
    default: 0
  },
  equipmentIDs: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Equipment'
  }]
}, {
  timestamps: true
});

// Indexes
workoutSchema.index({ name: 'text' });
workoutSchema.index({ categoryIDs: 1 });

const Workout = mongoose.model('Workout', workoutSchema);

export default Workout;


