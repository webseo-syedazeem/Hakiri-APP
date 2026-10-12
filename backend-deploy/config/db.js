const mongoose = require("mongoose");
const Activity = require("../models/Activity");
const Prompt = require("../models/Prompt");
const { ACTIVITIES, PROMPTS } = require("../data/catalog");

let cachedPromise = null;
let seedPromise = null;
let seedDone = false;

const connectDB = async () => {
  if (mongoose.connection.readyState === 1) return mongoose.connection;
  if (cachedPromise) return cachedPromise;

  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    throw new Error("MONGO_URI is not defined in environment variables");
  }

  const maskedUri = mongoUri.replace(/\/\/.*@/, "//***:***@");
  console.log(`Connecting to MongoDB: ${maskedUri}`);

  cachedPromise = mongoose
    .connect(mongoUri, {
      serverSelectionTimeoutMS: 8000,
      connectTimeoutMS: 8000,
      maxPoolSize: 5,
      minPoolSize: 0,
      // Fail fast in serverless instead of queueing forever.
      bufferCommands: false,
    })
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

/** Seed only when catalog is missing — never re-write on every cold start. */
const seedCatalog = async () => {
  if (seedDone) return;
  if (seedPromise) return seedPromise;

  seedPromise = (async () => {
    try {
      const [activityCount, promptCount] = await Promise.all([
        Activity.estimatedDocumentCount(),
        Prompt.estimatedDocumentCount(),
      ]);
      if (activityCount >= ACTIVITIES.length && promptCount >= PROMPTS.length) {
        seedDone = true;
        return;
      }

      await Promise.all([
        Activity.bulkWrite(
          ACTIVITIES.map((activity) => ({
            updateOne: {
              filter: { slug: activity.slug },
              update: { $set: activity },
              upsert: true,
            },
          })),
          { ordered: false }
        ),
        Prompt.bulkWrite(
          PROMPTS.map((prompt) => ({
            updateOne: {
              filter: { code: prompt.code },
              update: { $set: prompt },
              upsert: true,
            },
          })),
          { ordered: false }
        ),
      ]);
      seedDone = true;
    } catch (error) {
      seedPromise = null;
      throw error;
    }
  })();

  return seedPromise;
};

module.exports = { connectDB, seedCatalog };
