if (!process.env.VERCEL) {
  require("dotenv").config({ quiet: true });
}

process.on("uncaughtException", (err) => {
  console.error("[uncaughtException]", err);
});
process.on("unhandledRejection", (reason) => {
  console.error("[unhandledRejection]", reason);
});

const express = require("express");
const cors = require("cors");
const rateLimiter = require("express-rate-limit");
const helmet = require("helmet");
const { errorHandler, notFound } = require("./middleware/errorMiddleware");

const app = express();
app.set("trust proxy", 1);

app.use(
  rateLimiter({
    windowMs: 15 * 60 * 1000,
    max: 1000,
    standardHeaders: "draft-7",
    legacyHeaders: false,
    message: "Too many requests, please try again later.",
    validate: false,
  })
);
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/ping", (_req, res) => {
  res.status(200).json({ success: true, message: "Server is reachable!" });
});

let apiReady = false;
let apiRouter = null;

async function ensureApi(req, res, next) {
  try {
    if (!apiReady) {
      const { connectDB, seedCatalog } = require("./config/db");
      await connectDB();
      apiRouter = require("./routes");
      apiReady = true;
      // Catalog seed must not block signup/login on cold start.
      seedCatalog().catch((err) => console.error("seedCatalog:", err.message));
    }
    return apiRouter(req, res, next);
  } catch (error) {
    console.error("API bootstrap failed:", error);
    return res.status(503).json({
      success: false,
      message: "Database connection failed.",
      error: error.message,
      instruction: "Check MONGO_URI and that Atlas allows 0.0.0.0/0.",
    });
  }
}

app.get("/", async (_req, res) => {
  try {
    const mongoose = require("mongoose");
    const { connectDB } = require("./config/db");
    await connectDB();
    const statusMap = { 0: "disconnected", 1: "connected", 2: "connecting", 3: "disconnecting" };
    const { geminiStatus } = require("./config/ai");
    return res.json({
      success: true,
      message: "Hakkiri API is running",
      version: "1.0.0",
      database: statusMap[mongoose.connection.readyState] || "unknown",
      ai: geminiStatus(),
      base: "/api",
    });
  } catch (error) {
    return res.status(503).json({
      success: false,
      message: "Database connection failed.",
      error: error.message,
    });
  }
});

app.use("/api", ensureApi);
app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 5055;

if (!process.env.VERCEL && require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

module.exports = app;
