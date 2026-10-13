const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: [true, "Name is required"],
    trim: true,
  },
  email: {
    type: String,
    required: [true, "Email is required"],
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: [
      function () {
        return this.authProvider !== "google";
      },
      "Password is required",
    ],
    minlength: 6,
  },
  googleId: {
    type: String,
    sparse: true,
    unique: true,
    trim: true,
  },
  authProvider: {
    type: String,
    enum: ["password", "google"],
    default: "password",
  },
  avatarUrl: {
    type: String,
    default: "",
  },
  fcmTokens: {
    type: [String],
    default: [],
  },
  fcmPlatform: {
    type: String,
    enum: ["ios", "android", "unknown"],
    default: "unknown",
  },
  fcmUpdatedAt: {
    type: Date,
    default: null,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

userSchema.pre("save", async function () {
  if (!this.password || !this.isModified("password")) return;
  // 8 rounds keeps signup snappy on serverless without weakening auth much.
  this.password = await bcrypt.hash(this.password, 8);
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password) return false;
  return bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model("User", userSchema);
