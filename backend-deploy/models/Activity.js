const mongoose = require("mongoose");

const rubricSchema = new mongoose.Schema(
  {
    key: String,
    name: String,
    beginner: String,
    intermediary: String,
    professional: String,
  },
  { _id: false }
);

const activitySchema = new mongoose.Schema(
  {
    slug: { type: String, unique: true, required: true },
    name: { type: String, required: true },
    isMvp: { type: Boolean, default: false },
    tagline: String,
    description: String,
    cognitiveMechanism: String,
    prepDurationSeconds: { type: Number, default: 3 },
    defaultDurationSeconds: { type: Number, default: 60 },
    benefits: { type: [String], default: [] },
    successMeasures: { type: [String], default: [] },
    rubrics: { type: [rubricSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Activity", activitySchema);
