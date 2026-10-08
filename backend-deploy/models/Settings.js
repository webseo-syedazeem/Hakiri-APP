const mongoose = require("mongoose");

const settingsSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", unique: true, required: true },
    industryTrack: { type: String, default: null },
    voiceProfile: { type: String, default: null },
    dailyAnchorMinutes: { type: Number, default: 5 },
    audioPrivacy: { type: String, default: "encrypted_on_device" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Settings", settingsSchema);
