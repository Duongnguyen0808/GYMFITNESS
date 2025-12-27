import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const collectionSettingSchema = new mongoose.Schema(
  {
    round: { type: Number, default: 3 },
    numOfWorkoutPerRound: { type: Number, default: 5 },
    isStartWithWarmUp: { type: Boolean, default: true },
    isShuffle: { type: Boolean, default: true },
    exerciseTime: { type: Number, default: 10 },
    transitionTime: { type: Number, default: 10 },
    restTime: { type: Number, default: 10 },
    restFrequency: { type: Number, default: 10 },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
    },
    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
    },
    name: {
      type: String,
      default: "User",
    },
    gender: {
      type: String,
      enum: ["male", "female", "other"],
      default: "other",
    },
    dateOfBirth: {
      type: Date,
      default: () => new Date("2000-01-01"),
    },
    currentWeight: {
      type: Number,
      default: 70,
    },
    currentHeight: {
      type: Number,
      default: 170,
    },
    goalWeight: {
      type: Number,
      default: 65,
    },
    weightUnit: {
      type: String,
      enum: ["kg", "lbs"],
      default: "kg",
    },
    heightUnit: {
      type: String,
      enum: ["cm", "ft"],
      default: "cm",
    },
    hobbies: [
      {
        type: String,
      },
    ],
    diet: {
      type: String,
    },
    badHabits: [
      {
        type: String,
      },
    ],
    proteinSources: [
      {
        type: String,
      },
    ],
    limits: [
      {
        type: String,
      },
    ],
    sleepTime: {
      type: String,
    },
    dailyWater: {
      type: String,
    },
    mainGoal: {
      type: String,
    },
    bodyType: {
      type: String,
    },
    experience: {
      type: String,
    },
    typicalDay: {
      type: String,
    },
    activeFrequency: {
      type: String,
      default: "moderate",
    },
    collectionSetting: {
      type: collectionSettingSchema,
      default: () => ({}),
    },
    // Email verification fields
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailOTP: {
      type: String,
      default: null,
    },
    emailOTPExpires: {
      type: Date,
      default: null,
    },
    // Password reset fields
    resetPasswordOTP: {
      type: String,
      default: null,
    },
    resetPasswordOTPExpires: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) {
    return next();
  }
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Remove sensitive fields from JSON output
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  delete obj.emailOTP;
  delete obj.emailOTPExpires;
  delete obj.resetPasswordOTP;
  delete obj.resetPasswordOTPExpires;
  return obj;
};

const User = mongoose.model("User", userSchema);

export default User;
