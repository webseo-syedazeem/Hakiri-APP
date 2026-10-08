[
  "express",
  "cors",
  "helmet",
  "express-rate-limit",
  "mongoose",
  "jsonwebtoken",
  "bcryptjs",
].forEach((dep) => {
  try {
    require(dep);
  } catch (err) {
    console.warn(`[api/index] optional dep missing at trace time: ${dep}`, err.message);
  }
});

let app;
let bootError;

try {
  app = require("../server");
} catch (err) {
  bootError = err;
  console.error("[api/index] require(server) failed:", err);
}

module.exports = (req, res) => {
  if (bootError || !app) {
    res.statusCode = 500;
    res.setHeader("Content-Type", "application/json");
    res.end(
      JSON.stringify({
        success: false,
        message: "Express app failed to load",
        error: bootError ? bootError.message : "app is null",
      })
    );
    return;
  }

  return app(req, res);
};
