import mongoose from 'mongoose';

const librarySectionSchema = new mongoose.Schema({
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
  route: {
    type: String,
    required: true
  },
  order: {
    type: Number,
    required: true,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Indexes
librarySectionSchema.index({ order: 1 });
librarySectionSchema.index({ isActive: 1 });

const LibrarySection = mongoose.model('LibrarySection', librarySectionSchema);

export default LibrarySection;


