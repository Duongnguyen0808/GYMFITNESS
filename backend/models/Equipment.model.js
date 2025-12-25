import mongoose from 'mongoose';

const equipmentSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  imageLink: {
    type: String,
    default: ''
  }
}, {
  timestamps: true
});

// Indexes
equipmentSchema.index({ name: 'text' });

const Equipment = mongoose.model('Equipment', equipmentSchema);

export default Equipment;

