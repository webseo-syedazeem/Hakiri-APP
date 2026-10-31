const mongoose = require("mongoose");

const aiContentReportSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null,
    index: true,
  },
  /** Denormalized at submit so admin always sees who reported. */
  reporterName: {
    type: String,
    default: "",
    trim: true,
    maxlength: 120,
  },
  reporterEmail: {
    type: String,
    default: "",
    trim: true,
    lowercase: true,
    maxlength: 160,
    index: true,
  },
  guestEmail: {
    type: String,
    default: "",
    trim: true,
  },
  contentType: {
    type: String,
    enum: [
      "suggested_answer",
      "coaching_feedback",
      "debate_pushback",
      "other",
    ],
    default: "other",
  },
  reason: {
    type: String,
    enum: [
      "inaccurate",
      "offensive",
      "harmful",
      "spam",
      "other",
    ],
    required: true,
  },
  detail: {
    type: String,
    default: "",
    maxlength: 2000,
  },
  contentSnippet: {
    type: String,
    default: "",
    maxlength: 4000,
  },
  activitySlug: {
    type: String,
    default: "",
    trim: true,
  },
  sessionId: {
    type: String,
    default: "",
    trim: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

module.exports = mongoose.model("AiContentReport", aiContentReportSchema);
