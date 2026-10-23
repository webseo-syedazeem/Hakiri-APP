const mongoose = require("mongoose");

const reflectionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    title: { type: String, default: "" },
    learnings: { type: String, default: "" },
    focusArea: { type: String, default: "" },
  },
  { timestamps: true }
);

reflectionSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model("Reflection", reflectionSchema);
