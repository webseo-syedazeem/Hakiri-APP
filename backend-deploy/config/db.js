const mongoose = require("mongoose");
const Activity = require("../models/Activity");
const Prompt = require("../models/Prompt");
const { ACTIVITIES, PROMPTS } = require("../data/catalog");

let cachedPromise = null;

const connectDB = async () => {
  if (cachedPromise) return cachedPromise;

  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    throw new Error("MONGO_URI is not defined in environment variables");
  }

  const maskedUri = mongoUri.replace(/\/\/.*@/, "//***:***@");
  console.log(`Connecting to MongoDB: ${maskedUri}`);

  cachedPromise = mongoose
    .connect(mongoUri, { serverSelectionTimeoutMS: 15000 })
    .then((conn) => {
      console.log(`MongoDB Connected: ${conn.connection.host}/${conn.connection.name}`);
      return conn;
    })
    .catch((error) => {
      console.error(`MongoDB Connection Error: ${error.message}`);
      cachedPromise = null;
      throw error;
    });

  return cachedPromise;
};

const seedCatalog = async () => {
  for (const activity of ACTIVITIES) {
    await Activity.updateOne({ slug: activity.slug }, { $set: activity }, { upsert: true });
  }
  for (const prompt of PROMPTS) {
    await Prompt.updateOne({ code: prompt.code }, { $set: prompt }, { upsert: true });
  }
  const slugs = ACTIVITIES.map((a) => a.slug);
  const codes = PROMPTS.map((p) => p.code);
  await Activity.deleteMany({ slug: { $nin: slugs } });
  await Prompt.deleteMany({ code: { $nin: codes } });
};

module.exports = { connectDB, seedCatalog };
