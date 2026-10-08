module.exports = (req, res) => {
  res.statusCode = 200;
  res.setHeader("Content-Type", "application/json");
  res.end(JSON.stringify({ success: true, message: "Hakkiri API reachable", via: "api/ping.js" }));
};
